import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wealth_tracker/data/debt_repository.dart';
import 'package:wealth_tracker/data/market_repository.dart';
import 'package:wealth_tracker/data/models/asset_type.dart';
import 'package:wealth_tracker/data/models/debt.dart';
import 'package:wealth_tracker/data/models/quote.dart';
import 'package:wealth_tracker/data/portfolio_repository.dart';
import 'package:wealth_tracker/state/providers.dart';

import 'fakes.dart';

Future<ProviderContainer> makeContainer({
  Map<String, Object> prefs = const {},
  FakePriceApi? api,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
    priceApiProvider.overrideWithValue(api ?? FakePriceApi()),
  ]);
  addTearDown(container.dispose);
  return container;
}

const silver = Quote(
  type: AssetType.gold,
  code: 'gumus',
  name: 'Gümüş',
  buy: 87,
  sell: 98,
);

class _GoldOnlyApi extends FakePriceApi {
  _GoldOnlyApi(this.gold);

  List<Quote> gold;

  @override
  Future<List<Quote>> fetchGold() async => gold;
}

String legacy(String type, String name, num amount) =>
    jsonEncode({'assetType': type, 'name': name, 'amount': amount});

void main() {
  test('2.x kayıtları yeni biçime taşınır ve birleştirilir', () {
    final holdings = migrateLegacyAssets([
      legacy('Döviz', 'ABD DOLARI', 100),
      legacy('Altın', 'Çeyrek Altın', 2),
      legacy('Kripto', 'BTC', 0.5),
      legacy('TL', 'TL', 1000),
      legacy('Döviz', 'ABD DOLARI', 50),
      legacy('Döviz', 'ÖZEL ÇEKME HAKKI (SDR)', 1),
      'bozuk',
    ]);

    expect({for (final h in holdings) h.key: h.amount}, {
      'currency:USD': 150,
      'gold:ceyrek-altin': 2,
      'crypto:BTC': 0.5,
      'cash:TRY': 1000,
      'currency:ÖZEL ÇEKME HAKKI (SDR)': 1,
    });
  });

  test('eski anahtar ilk açılışta taşınır ve silinir', () async {
    final container = await makeContainer(prefs: {
      PortfolioRepository.legacyKey: [legacy('Döviz', 'EURO', 10)],
    });

    final holdings = container.read(portfolioProvider);
    expect(holdings.single.key, 'currency:EUR');

    await pumpEventQueue();
    final prefs = container.read(sharedPreferencesProvider);
    expect(prefs.getStringList(PortfolioRepository.legacyKey), isNull);
    expect(prefs.getString('portfolio.v2'), contains('EUR'));
  });

  test('ata altın kayıtları cumhuriyet altınıyla birleştirilir', () async {
    final container = await makeContainer(prefs: {
      'portfolio.v2': jsonEncode([
        {'type': 'gold', 'code': 'ata-altin', 'amount': 2},
        {'type': 'gold', 'code': 'cumhuriyet-altini', 'amount': 1},
        {'type': 'gold', 'code': 'hamit-altin', 'amount': 1},
      ]),
    });
    expect({for (final h in container.read(portfolioProvider)) h.key: h.amount}, {
      'gold:cumhuriyet-altini': 3,
      'gold:hamit-altin': 1,
    });
  });

  test('ekleme birleştirir, sıfır miktar siler, geri alma geri getirir', () async {
    final container = await makeContainer();
    final notifier = container.read(portfolioProvider.notifier);

    notifier.add(AssetType.currency, 'USD', 10);
    notifier.add(AssetType.currency, 'USD', 5);
    notifier.add(AssetType.gold, 'gram-altin', 2);
    expect(container.read(portfolioProvider).first.amount, 15);

    notifier.edit('gold:gram-altin', 0);
    expect(container.read(portfolioProvider), hasLength(1));

    final removed = notifier.remove('currency:USD')!;
    expect(container.read(portfolioProvider), isEmpty);
    notifier.restore(removed);
    expect(container.read(portfolioProvider).single.amount, 15);

    // Yeniden açılışta korunur.
    final reloaded = PortfolioRepository(container.read(sharedPreferencesProvider)).load();
    expect(reloaded.single.amount, 15);
  });

  test('özet; değeri, günlük değişimi ve dağılımı hesaplar', () async {
    final container = await makeContainer();
    final notifier = container.read(portfolioProvider.notifier)
      ..add(AssetType.gold, 'gram-altin', 2) // 6000, +%1
      ..add(AssetType.currency, 'USD', 100) // 4000, -%0,5
      ..add(AssetType.cash, 'TRY', 1000)
      ..add(AssetType.crypto, 'DELISTED', 3); // fiyatı yok
    expect(notifier, isNotNull);

    await container.read(marketProvider.future);
    final summary = container.read(portfolioSummaryProvider);

    expect(summary.total, 11000);
    expect(summary.items.first.holding.code, 'gram-altin');
    expect(summary.items.last.quote, isNull);
    expect(summary.items.last.name, 'DELISTED');
    expect(summary.dailyChange, closeTo(6000 - 6000 / 1.01 + 4000 - 4000 / 0.995, 1e-6));
    expect(summary.allocation, {
      AssetType.gold: 6000,
      AssetType.currency: 4000,
      AssetType.cash: 1000,
    });
  });

  test('alış fiyatı birleştirmede ağırlıklı ortalanır', () async {
    final container = await makeContainer();
    final notifier = container.read(portfolioProvider.notifier);

    notifier.add(AssetType.gold, 'gram-altin', 2, unitCost: 2500);
    notifier.add(AssetType.gold, 'gram-altin', 2, unitCost: 3500);
    expect(container.read(portfolioProvider).single.avgCost, 3000);

    // Maliyeti bilinmeyen bir alım ortalamayı bilinmez yapar.
    notifier.add(AssetType.gold, 'gram-altin', 1);
    expect(container.read(portfolioProvider).single.avgCost, isNull);

    notifier.edit('gold:gram-altin', 5, avgCost: 2000);
    final reloaded =
        PortfolioRepository(container.read(sharedPreferencesProvider)).load();
    expect(reloaded.single.avgCost, 2000);

    // Silinip geri alınan varlık maliyetini korur.
    notifier.restore(notifier.remove('gold:gram-altin')!);
    expect(container.read(portfolioProvider).single.avgCost, 2000);
  });

  test('kâr/zarar yalnızca maliyeti bilinen varlıklardan hesaplanır', () async {
    final container = await makeContainer();
    container.read(portfolioProvider.notifier)
      ..add(AssetType.gold, 'gram-altin', 2, unitCost: 2500) // 6000 - 5000
      ..add(AssetType.currency, 'USD', 100, unitCost: 50) // 4000 - 5000
      ..add(AssetType.crypto, 'BTC', 1) // maliyet yok
      ..add(AssetType.cash, 'TRY', 1000, unitCost: 1); // nakitte K/Z yok
    await container.read(marketProvider.future);
    final summary = container.read(portfolioSummaryProvider);

    expect(summary.profit, 0);
    expect(summary.profitPercent, 0);
    expect(summary.hasMissingCost, isTrue);
    final gold = summary.items.firstWhere((i) => i.holding.code == 'gram-altin');
    expect(gold.profit, 1000);
    expect(gold.profitPercent, 20);
    final cash = summary.items.firstWhere((i) => i.holding.code == 'TRY');
    expect(cash.holding.avgCost, isNull);
    expect(cash.profit, isNull);
  });

  test('portföy değeri gün başına bir kez saklanır', () async {
    final container = await makeContainer(prefs: {
      'history.v1': jsonEncode({'2026-09-30': 9000.0, '2026-10-01': 9500.0}),
    });
    container.listen(historyProvider, (_, _) {});
    expect(container.read(historyProvider), hasLength(2));

    container.read(portfolioProvider.notifier).add(AssetType.cash, 'TRY', 1000);
    await container.read(marketProvider.future);
    await pumpEventQueue();
    final history = container.read(historyProvider);
    expect(history, hasLength(3));
    expect(history.last.total, 1000);

    container.read(portfolioProvider.notifier).add(AssetType.cash, 'TRY', 500);
    expect(container.read(historyProvider), hasLength(3));
    expect(container.read(historyProvider).last.total, 1500);
  });

  test('borç ve alacaklar güncel fiyatla net değere yansır', () async {
    final container = await makeContainer();
    container.read(portfolioProvider.notifier)
        .add(AssetType.cash, 'TRY', 10000);
    final debts = container.read(debtsProvider.notifier)
      ..save(const Debt(
        id: '1',
        direction: DebtDirection.lent,
        person: 'Ayşe',
        type: AssetType.gold,
        code: 'gram-altin',
        amount: 2, // 6000, +%1
      ))
      ..save(const Debt(
        id: '2',
        direction: DebtDirection.borrowed,
        person: 'Mehmet',
        type: AssetType.currency,
        code: 'USD',
        amount: 50, // satış 40,1 → 2005, -%0,5
      ));
    await container.read(marketProvider.future);

    var worth = container.read(netWorthProvider);
    // Alacak alış (bozdurma), borç satış (geri ödemek için satın alma)
    // fiyatıyla değerlenir.
    expect(worth.debts.lent, 2 * gramGold.buy);
    expect(worth.debts.borrowed, closeTo(50 * usd.sell, 1e-9));
    expect(worth.total, closeTo(10000 + 6000 - 2005, 1e-9));
    // Alacak değer kazanınca net artar, borç değer kaybedince de net artar.
    expect(
      worth.dailyChange,
      closeTo((6000 - 6000 / 1.01) - (2005 - 2005 / 0.995), 1e-6),
    );

    // Kalıcıdır; kapatılan kayıt geri alınabilir.
    final reloaded =
        DebtRepository(container.read(sharedPreferencesProvider)).load();
    expect(reloaded.map((d) => d.person), ['Ayşe', 'Mehmet']);
    debts.save(debts.remove('2')!);
    worth = container.read(netWorthProvider);
    expect(worth.total, closeTo(13995, 1e-9));

    // Düzenleme aynı kimlikteki kaydı değiştirir.
    debts.save(const Debt(
      id: '1',
      direction: DebtDirection.lent,
      person: 'Ayşe',
      type: AssetType.cash,
      code: 'TRY',
      amount: 500,
    ));
    expect(container.read(debtsProvider), hasLength(2));
    expect(container.read(netWorthProvider).total,
        closeTo(10000 + 500 - 2005, 1e-9));
  });

  test('vadesi geçmiş borç bugünden önceki tarihe göre belirlenir', () {
    final now = DateTime(2026, 10, 2, 15);
    Debt due(DateTime d) => Debt(
          id: 'x',
          direction: DebtDirection.lent,
          person: 'A',
          type: AssetType.cash,
          code: 'TRY',
          amount: 1,
          dueDate: d,
        );
    expect(due(DateTime(2026, 10, 1)).isOverdue(now), isTrue);
    expect(due(DateTime(2026, 10, 2)).isOverdue(now), isFalse);
  });

  test('tema tercihi saklanır', () async {
    final container = await makeContainer(prefs: {'ui.themeMode': 'dark'});
    expect(container.read(themeModeProvider), ThemeMode.dark);
    container.read(themeModeProvider.notifier).set(ThemeMode.light);
    expect(
      container.read(sharedPreferencesProvider).getString('ui.themeMode'),
      'light',
    );
  });

  group('MarketRepository', () {
    test('bir kaynak düşerse önbellekteki veri kullanılır', () async {
      final api = FakePriceApi();
      final container = await makeContainer(api: api);
      final repo = container.read(marketRepositoryProvider);

      final fresh = await repo.fetch();
      expect(fresh.isStale, isFalse);

      api.failCrypto = true;
      final partial = await repo.fetch();
      expect(partial.isStale, isTrue);
      expect(partial.find(AssetType.crypto, 'BTC')?.price, btc.price);
      expect(partial.find(AssetType.currency, 'USD'), isNotNull);
    });

    test('fiyatlanamayan altın kalemi önbellekten tamamlanır', () async {
      final api = _GoldOnlyApi([gramGold, silver]);
      final container = await makeContainer(api: api);
      final repo = container.read(marketRepositoryProvider);
      await repo.fetch();

      api.gold = [gramGold];
      final snapshot = await repo.fetch();
      expect(snapshot.of(AssetType.gold).map((q) => q.code),
          ['gram-altin', 'gumus']);
      expect(snapshot.isStale, isTrue);
    });

    test('hiç veri yoksa hata verir', () async {
      final container = await makeContainer(
          api: FakePriceApi(failAll: true));
      expect(
        container.read(marketRepositoryProvider).fetch(),
        throwsA(isA<MarketUnavailableException>()),
      );
    });
  });
}
