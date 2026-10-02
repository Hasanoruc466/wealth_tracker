import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/asset_type.dart';
import 'models/market_snapshot.dart';
import 'models/quote.dart';
import 'price_api.dart';

class MarketUnavailableException implements Exception {
  const MarketUnavailableException();

  @override
  String toString() =>
      'Fiyatlar alınamadı. İnternet bağlantınızı kontrol edip tekrar deneyin.';
}

/// Fiyatları ağdan çeker, son başarılı sonucu önbellekte tutar.
///
/// Kaynaklardan biri hata verirse o kaynağın önbellekteki verisi kullanılır,
/// böylece uygulama çevrimdışıyken de son bilinen fiyatlarla çalışır.
class MarketRepository {
  MarketRepository(this._api, this._prefs);

  static const _cacheKey = 'market.cache.v1';

  final PriceApi _api;
  final SharedPreferences _prefs;

  Future<MarketSnapshot> fetch() async {
    final [gold, currency, crypto] = await Future.wait([
      _attempt(_api.fetchGold),
      _attempt(_api.fetchCurrency),
      _attempt(_api.fetchCrypto),
    ]);
    final cached = readCache();

    final quotes = <AssetType, List<Quote>>{};
    var stale = false;
    void merge(List<Quote>? fresh, AssetType type, {bool fillGaps = false}) {
      final old = cached?.quotes[type] ?? const <Quote>[];
      if (fresh == null) {
        stale = true;
        if (old.isNotEmpty) quotes[type] = old;
        return;
      }
      quotes[type] = [...fresh];
      // Altın listesi sabittir; bir kalem (ör. gümüş) bu turda
      // fiyatlanamadıysa son bilinen fiyatı kullanılır.
      if (fillGaps) {
        final have = {for (final quote in fresh) quote.code};
        for (final quote in old) {
          if (have.contains(quote.code)) continue;
          quotes[type]!.add(quote);
          stale = true;
        }
      }
    }

    merge(gold, AssetType.gold, fillGaps: true);
    merge(currency, AssetType.currency);
    merge(crypto, AssetType.crypto);
    if (quotes.isEmpty) throw const MarketUnavailableException();

    final anyFresh = gold != null || currency != null || crypto != null;
    final snapshot = MarketSnapshot(
      quotes: quotes,
      updatedAt: anyFresh ? DateTime.now() : cached!.updatedAt,
      isStale: stale,
    );
    if (anyFresh) {
      await _prefs.setString(_cacheKey, jsonEncode(snapshot.toJson()));
    }
    return snapshot;
  }

  MarketSnapshot? readCache() {
    final raw = _prefs.getString(_cacheKey);
    if (raw == null) return null;
    try {
      return MarketSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Fiyat önbelleği okunamadı: $e');
      return null;
    }
  }

  Future<List<Quote>?> _attempt(Future<List<Quote>> Function() fetch) async {
    try {
      final quotes = await fetch();
      return quotes.isEmpty ? null : quotes;
    } catch (e) {
      debugPrint('Fiyat kaynağı hatası: $e');
      return null;
    }
  }
}
