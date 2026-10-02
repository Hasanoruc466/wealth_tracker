import 'dart:async';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/catalog.dart';
import '../data/debt_repository.dart';
import '../data/history_repository.dart';
import '../data/market_repository.dart';
import '../data/models/asset_type.dart';
import '../data/models/debt.dart';
import '../data/models/holding.dart';
import '../data/models/market_snapshot.dart';
import '../data/models/quote.dart';
import '../data/portfolio_repository.dart';
import '../data/price_api.dart';

/// `main` içinde gerçek örnekle değiştirilir.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences override edilmedi'),
);

final priceApiProvider = Provider((ref) => PriceApi());

final marketRepositoryProvider = Provider(
  (ref) => MarketRepository(
    ref.watch(priceApiProvider),
    ref.watch(sharedPreferencesProvider),
  ),
);

final portfolioRepositoryProvider = Provider(
  (ref) => PortfolioRepository(ref.watch(sharedPreferencesProvider)),
);

final debtRepositoryProvider = Provider(
  (ref) => DebtRepository(ref.watch(sharedPreferencesProvider)),
);

final historyRepositoryProvider = Provider(
  (ref) => HistoryRepository(ref.watch(sharedPreferencesProvider)),
);

// --- Piyasa -----------------------------------------------------------------

final marketProvider =
    AsyncNotifierProvider<MarketNotifier, MarketSnapshot>(MarketNotifier.new);

class MarketNotifier extends AsyncNotifier<MarketSnapshot> {
  /// Kaynaklar dakikada bir güncellenir.
  static const refreshInterval = Duration(minutes: 1);

  /// Bir kaynak yanıt vermediyse bir sonraki turu beklemeden yeniden denenir.
  static const retryAfterFailure = Duration(seconds: 15);

  bool _refreshing = false;
  Timer? _timer;
  Timer? _retry;

  @override
  Future<MarketSnapshot> build() async {
    ref.onDispose(pause);
    _schedule();
    final snapshot = await ref.read(marketRepositoryProvider).fetch();
    if (snapshot.isStale) _scheduleRetry();
    return snapshot;
  }

  /// Fiyatları yeniler. Elde veri varken yenileme başarısız olursa eski veri
  /// korunur.
  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    _retry?.cancel();
    try {
      final next = await AsyncValue.guard(
        () => ref.read(marketRepositoryProvider).fetch(),
      );
      if (next.hasValue || !state.hasValue) state = next;
      if (next.hasError || (next.valueOrNull?.isStale ?? false)) {
        _scheduleRetry();
      }
    } finally {
      _refreshing = false;
    }
  }

  /// Uygulama arka plana geçince otomatik yenileme durur.
  void pause() {
    _timer?.cancel();
    _retry?.cancel();
    _timer = _retry = null;
  }

  /// Uygulamaya dönülünce fiyatlar hemen yenilenir ve zamanlayıcı yeniden başlar.
  void resume() {
    _schedule();
    refresh();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer.periodic(refreshInterval, (_) => refresh());
  }

  void _scheduleRetry() {
    if (_timer == null) return; // arka plandayken deneme yapılmaz
    _retry?.cancel();
    _retry = Timer(retryAfterFailure, refresh);
  }
}

// --- Portföy ----------------------------------------------------------------

final portfolioProvider =
    NotifierProvider<PortfolioNotifier, List<Holding>>(PortfolioNotifier.new);

class PortfolioNotifier extends Notifier<List<Holding>> {
  PortfolioRepository get _repository => ref.read(portfolioRepositoryProvider);

  @override
  List<Holding> build() => _repository.load();

  /// Varlık zaten varsa miktarı üzerine eklenir ve ortalama alış fiyatı
  /// yeniden hesaplanır. [unitCost] birim alış fiyatıdır (TL).
  void add(AssetType type, String code, double amount, {double? unitCost}) {
    if (amount <= 0) return;
    if (type == AssetType.cash) unitCost = null;
    final holding =
        Holding(type: type, code: code, amount: amount, avgCost: unitCost);
    final exists = state.any((h) => h.key == holding.key);
    _update(exists
        ? [
            for (final h in state)
              h.key == holding.key ? h.merge(amount, unitCost) : h,
          ]
        : [...state, holding]);
  }

  /// Miktarı ve ortalama alış fiyatını doğrudan değiştirir; sıfır miktar
  /// varlığı siler.
  void edit(String key, double amount, {double? avgCost}) {
    if (amount <= 0) {
      remove(key);
      return;
    }
    _update([
      for (final h in state)
        h.key == key
            ? Holding(
                type: h.type,
                code: h.code,
                amount: amount,
                avgCost: h.type == AssetType.cash ? null : avgCost,
              )
            : h,
    ]);
  }

  /// Silinen varlığı döndürür; geri almak için [restore] kullanılabilir.
  Holding? remove(String key) {
    final removed = state.where((h) => h.key == key).firstOrNull;
    if (removed != null) _update([...state.where((h) => h.key != key)]);
    return removed;
  }

  void restore(Holding holding) => add(
        holding.type,
        holding.code,
        holding.amount,
        unitCost: holding.avgCost,
      );

  void _update(List<Holding> next) {
    state = next;
    unawaited(_repository.save(next));
  }
}

// --- Özet -------------------------------------------------------------------

class HoldingValue {
  const HoldingValue({required this.holding, required this.quote});

  final Holding holding;

  /// Fiyat bulunamazsa (ör. listeden kaldırılan bir kripto) `null` olur.
  final Quote? quote;

  String get name => quote?.name ?? displayName(holding.type, holding.code);

  double get value => holding.amount * (quote?.price ?? 0);

  /// Bugünkü değişimin TL karşılığı.
  double get dailyChange {
    final percent = quote?.changePercent;
    if (percent == null || percent <= -100) return 0;
    return value - value / (1 + percent / 100);
  }

  /// Alıştan bu yana kâr/zarar; maliyet ya da fiyat bilinmiyorsa (ve nakitte)
  /// `null`.
  double? get profit {
    final cost = holding.cost;
    if (cost == null || quote == null) return null;
    return value - cost;
  }

  double? get profitPercent {
    final profit = this.profit;
    final cost = holding.cost;
    if (profit == null || cost == null || cost <= 0) return null;
    return profit / cost * 100;
  }
}

class PortfolioSummary {
  PortfolioSummary(List<HoldingValue> items)
      : items = [...items]..sort((a, b) {
            final byValue = b.value.compareTo(a.value);
            return byValue != 0 ? byValue : a.name.compareTo(b.name);
          }),
        total = items.fold(0, (sum, item) => sum + item.value),
        dailyChange = items.fold(0, (sum, item) => sum + item.dailyChange);

  /// Değere göre büyükten küçüğe sıralı.
  final List<HoldingValue> items;
  final double total;
  final double dailyChange;

  double get dailyChangePercent {
    final previous = total - dailyChange;
    return previous <= 0 ? 0 : dailyChange / previous * 100;
  }

  /// Maliyeti bilinen varlıklar.
  Iterable<HoldingValue> get _costed =>
      items.where((item) => item.profit != null);

  /// Maliyeti bilinen varlıkların toplam kâr/zararı; hiçbirinin maliyeti
  /// bilinmiyorsa `null`.
  double? get profit => _costed.isEmpty
      ? null
      : _costed.fold<double>(0, (sum, item) => sum + item.profit!);

  double? get profitPercent {
    final profit = this.profit;
    if (profit == null) return null;
    final cost = _costed.fold<double>(0, (sum, item) => sum + item.holding.cost!);
    return cost <= 0 ? null : profit / cost * 100;
  }

  /// Nakit dışında maliyeti girilmemiş varlık var mı?
  bool get hasMissingCost => items.any(
      (item) => item.holding.type != AssetType.cash && item.holding.avgCost == null);

  /// Türlere göre toplam değer (yalnızca değeri olan türler).
  Map<AssetType, double> get allocation {
    final result = <AssetType, double>{};
    for (final item in items) {
      if (item.value <= 0) continue;
      result.update(item.holding.type, (v) => v + item.value,
          ifAbsent: () => item.value);
    }
    return result;
  }
}

/// Nakit her zaman 1 TL'dir; diğerleri fiyatlar gelene kadar `null` olur.
Quote? _quoteFor(Ref ref, AssetType type, String code) {
  if (type == AssetType.cash) return Quote.cash;
  return ref.watch(marketProvider).valueOrNull?.find(type, code);
}

final portfolioSummaryProvider = Provider<PortfolioSummary>((ref) {
  final holdings = ref.watch(portfolioProvider);
  return PortfolioSummary([
    for (final holding in holdings)
      HoldingValue(
        holding: holding,
        quote: _quoteFor(ref, holding.type, holding.code),
      ),
  ]);
});

// --- Borçlar ----------------------------------------------------------------

final debtsProvider =
    NotifierProvider<DebtsNotifier, List<Debt>>(DebtsNotifier.new);

class DebtsNotifier extends Notifier<List<Debt>> {
  DebtRepository get _repository => ref.read(debtRepositoryProvider);

  @override
  List<Debt> build() => _repository.load();

  /// Aynı kimlikte kayıt varsa onu değiştirir, yoksa ekler.
  void save(Debt debt) {
    final exists = state.any((d) => d.id == debt.id);
    _update(exists
        ? [for (final d in state) d.id == debt.id ? debt : d]
        : [...state, debt]);
  }

  /// Silinen kaydı döndürür; geri almak için [save] kullanılabilir.
  Debt? remove(String id) {
    final removed = state.where((d) => d.id == id).firstOrNull;
    if (removed != null) _update([...state.where((d) => d.id != id)]);
    return removed;
  }

  void _update(List<Debt> next) {
    state = next;
    unawaited(_repository.save(next));
  }
}

class DebtValue {
  const DebtValue({required this.debt, required this.quote});

  final Debt debt;
  final Quote? quote;

  String get assetName => quote?.name ?? displayName(debt.type, debt.code);

  double get value => debt.amount * (quote?.price ?? 0);

  /// Bugünkü değişimin TL karşılığı (borcun kendi değerindeki değişim).
  double get dailyChange {
    final percent = quote?.changePercent;
    if (percent == null || percent <= -100) return 0;
    return value - value / (1 + percent / 100);
  }
}

class DebtSummary {
  DebtSummary(List<DebtValue> items)
      : items = [...items]..sort((a, b) {
            final byValue = b.value.compareTo(a.value);
            return byValue != 0
                ? byValue
                : a.debt.person.compareTo(b.debt.person);
          });

  /// Değere göre büyükten küçüğe sıralı.
  final List<DebtValue> items;

  Iterable<DebtValue> of(DebtDirection direction) =>
      items.where((i) => i.debt.direction == direction);

  /// Başkalarından alacaklarının toplamı.
  double get lent => _sum(of(DebtDirection.lent));

  /// Başkalarına borçlarının toplamı.
  double get borrowed => _sum(of(DebtDirection.borrowed));

  /// Alacakların değer kazanması net değeri artırır, borçlarınki azaltır.
  double get dailyChange => items.fold(
      0,
      (sum, i) =>
          sum + (i.debt.isLent ? i.dailyChange : -i.dailyChange));

  static double _sum(Iterable<DebtValue> items) =>
      items.fold(0, (sum, i) => sum + i.value);
}

final debtSummaryProvider = Provider<DebtSummary>((ref) {
  final debts = ref.watch(debtsProvider);
  return DebtSummary([
    for (final debt in debts)
      DebtValue(debt: debt, quote: _quoteFor(ref, debt.type, debt.code)),
  ]);
});

// --- Net değer --------------------------------------------------------------

/// Varlıklar + alacaklar − borçlar.
class NetWorth {
  const NetWorth({required this.assets, required this.debts});

  final PortfolioSummary assets;
  final DebtSummary debts;

  bool get hasDebts => debts.items.isNotEmpty;

  bool get isEmpty => assets.items.isEmpty && debts.items.isEmpty;

  double get total => assets.total + debts.lent - debts.borrowed;

  double get dailyChange => assets.dailyChange + debts.dailyChange;

  double get dailyChangePercent {
    final previous = (total - dailyChange).abs();
    return previous <= 0 ? 0 : dailyChange / previous * 100;
  }
}

final netWorthProvider = Provider<NetWorth>((ref) => NetWorth(
      assets: ref.watch(portfolioSummaryProvider),
      debts: ref.watch(debtSummaryProvider),
    ));

// --- Geçmiş -----------------------------------------------------------------

/// Günlük net değerler (borçlar düşülmüş). Fiyatlar her geldiğinde bugünün
/// değeri güncellenir.
final historyProvider =
    NotifierProvider<HistoryNotifier, List<HistoryPoint>>(HistoryNotifier.new);

class HistoryNotifier extends Notifier<List<HistoryPoint>> {
  HistoryRepository get _repository => ref.read(historyRepositoryProvider);

  @override
  List<HistoryPoint> build() {
    ref.listen(netWorthProvider, (_, worth) {
      final next = _record(worth);
      if (next != null) state = next;
    });
    return _record(ref.read(netWorthProvider)) ?? _repository.load();
  }

  /// Fiyatlar henüz gelmediyse ya da kayıt yoksa kaydetmez.
  List<HistoryPoint>? _record(NetWorth worth) {
    if (ref.read(marketProvider).valueOrNull == null) return null;
    if (worth.isEmpty) return null;
    return _repository.record(DateTime.now(), worth.total);
  }
}

// --- Görünüm tercihleri -----------------------------------------------------

/// Tutarların `₺•••` olarak gizlenip gizlenmediği.
final hideBalancesProvider =
    NotifierProvider<HideBalancesNotifier, bool>(HideBalancesNotifier.new);

class HideBalancesNotifier extends Notifier<bool> {
  static const _key = 'ui.hideBalances';

  @override
  bool build() => ref.read(sharedPreferencesProvider).getBool(_key) ?? false;

  void toggle() {
    state = !state;
    ref.read(sharedPreferencesProvider).setBool(_key, state);
  }
}

/// Portföy satırlarının sağında gösterilen değişim.
enum RowMetric {
  daily('Bugün'),
  profit('Toplam K/Z');

  const RowMetric(this.label);

  final String label;
}

final rowMetricProvider =
    NotifierProvider<RowMetricNotifier, RowMetric>(RowMetricNotifier.new);

class RowMetricNotifier extends Notifier<RowMetric> {
  static const _key = 'ui.rowMetric';

  @override
  RowMetric build() {
    final saved = ref.read(sharedPreferencesProvider).getString(_key);
    return RowMetric.values.where((m) => m.name == saved).firstOrNull ??
        RowMetric.daily;
  }

  void toggle() {
    state = state == RowMetric.daily ? RowMetric.profit : RowMetric.daily;
    ref.read(sharedPreferencesProvider).setString(_key, state.name);
  }
}

/// Açık, koyu ya da sistem teması.
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'ui.themeMode';

  @override
  ThemeMode build() {
    final saved = ref.read(sharedPreferencesProvider).getString(_key);
    return ThemeMode.values.where((m) => m.name == saved).firstOrNull ??
        ThemeMode.system;
  }

  void set(ThemeMode mode) {
    state = mode;
    ref.read(sharedPreferencesProvider).setString(_key, mode.name);
  }
}

/// Alt menüde seçili sekme; başka ekranlardan sekme değiştirmek için.
final homeTabProvider = StateProvider<int>((ref) => 0);

/// Bir kez kapatılınca bir daha gösterilmeyen ipuçları için kalıcı bayrak.
class SeenFlagNotifier extends Notifier<bool> {
  SeenFlagNotifier(this._key);

  final String _key;

  @override
  bool build() => ref.read(sharedPreferencesProvider).getBool(_key) ?? false;

  void markSeen() {
    state = true;
    ref.read(sharedPreferencesProvider).setBool(_key, true);
  }
}

/// "Alış fiyatı girilmemiş varlıklarda…" ipucu kapatıldı mı?
final costHintSeenProvider = NotifierProvider<SeenFlagNotifier, bool>(
  () => SeenFlagNotifier('ui.costHintSeen'),
);
