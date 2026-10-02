import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'catalog.dart';
import 'gold_pricing.dart';
import 'models/asset_type.dart';
import 'models/quote.dart';

class PriceApiException implements Exception {
  const PriceApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'PriceApiException: $message';
}

/// Herkese açık, anahtarsız fiyat kaynakları:
/// - Altın ve gümüş: ons fiyatından hesaplanır (bkz. gold_pricing.dart).
///   Ons: gold-api.com, yedek olarak Binance PAXG. Kur: Truncgil, yedek
///   olarak Binance USDT/TRY.
/// - Döviz: Truncgil v4 (dakikada bir güncellenir)
/// - Kripto: Binance TRY pariteleri; Binance'e ulaşılamazsa Bitlo
class PriceApi {
  PriceApi({http.Client? client}) : _client = client ?? http.Client();

  static final _finansUri = Uri.https('finans.truncgil.com', '/v4/today.json');
  static final _bitloUri = Uri.https('api4.bitlo.com', '/market/ticker/all');
  static const _goldApiHost = 'api.gold-api.com';
  static const _binanceHost = 'api.binance.com';
  static const _timeout = Duration(seconds: 12);

  /// gold-api.com, Dart'ın varsayılan User-Agent'ını (`Dart/x (dart:io)`)
  /// ortak kotaya alıp 429 döndürüyor. Truncgil ise içinde URL geçen
  /// User-Agent'larda bağlantıyı kesiyor; bu yüzden sade bir ad kullanılır.
  static const _headers = {'User-Agent': 'Kese/3.0'};

  static const _retryDelay = Duration(milliseconds: 400);

  /// Binance tek istekte en fazla bu kadar sembolü güvenle kabul eder.
  static const _binanceChunk = 100;

  /// TRY parite listesi nadiren değişir; her yenilemede tekrar çekilmez.
  static const _symbolsTtl = Duration(hours: 12);

  /// Altın ve döviz aynı yenilemede Truncgil'e ihtiyaç duyar; tek istek yeter.
  static const _finansReuse = Duration(seconds: 20);

  final http.Client _client;

  List<String>? _trySymbols;
  DateTime? _trySymbolsAt;

  Future<Map<String, dynamic>>? _finansRequest;
  DateTime? _finansRequestAt;

  /// Altın ve gümüş alış/satış fiyatları.
  Future<List<Quote>> fetchGold() async {
    Map<String, dynamic>? finans;
    try {
      finans = await _finans();
    } catch (e) {
      debugPrint('Truncgil kullanılamadı, kur Binance\'ten alınacak: $e');
    }

    final [goldOunce, silverOunce, usdTry] = await Future.wait<double?>([
      _goldOunceUsd(),
      _spotUsd('XAG').then<double?>((v) => v, onError: (Object _) => null),
      _usdTry(finans),
    ]);

    return priceMetals(
      fineGoldGram: ounceToGramTry(goldOunce!, usdTry!),
      fineSilverGram: silverOunce != null
          ? ounceToGramTry(silverOunce, usdTry)
          : _positiveOrNull(_field(finans, 'GUMUS', 'Buying')),
      // Ons servisinde günlük değişim yok; Truncgil'in gram değişimi kullanılır.
      goldChangePercent: parseTrNumber(_field(finans, 'GRA', 'Change')),
      silverChangePercent: parseTrNumber(_field(finans, 'GUMUS', 'Change')),
    );
  }

  /// Döviz kurları.
  Future<List<Quote>> fetchCurrency() async =>
      parseTruncgilCurrencies(await _finans());

  Future<Map<String, dynamic>> _finans() {
    final pending = _finansRequest;
    if (pending != null &&
        DateTime.now().difference(_finansRequestAt!) < _finansReuse) {
      return pending;
    }
    final request = _getJson(_finansUri).then((json) {
      if (json is! Map<String, dynamic>) {
        throw const PriceApiException('Beklenmeyen Truncgil yanıtı');
      }
      return json;
    });
    _finansRequest = request;
    _finansRequestAt = DateTime.now();
    // Başarısız istek, bir sonraki denemede yeniden kullanılmasın.
    request.then((_) {}, onError: (Object _) {
      if (identical(_finansRequest, request)) _finansRequest = null;
    });
    return request;
  }

  /// Ons altın (USD). gold-api.com'a ulaşılamazsa, bir ons altına endeksli
  /// PAXG'nin Binance fiyatı kullanılır.
  Future<double> _goldOunceUsd() async {
    try {
      return await _spotUsd('XAU');
    } catch (e) {
      debugPrint('gold-api.com kullanılamadı, PAXG deneniyor: $e');
      return _binancePrice('PAXGUSDT');
    }
  }

  Future<double> _spotUsd(String symbol) async {
    final json = await _getJson(Uri.https(_goldApiHost, '/price/$symbol'));
    return _positive(json is Map ? json['price'] : null);
  }

  Future<double> _usdTry(Map<String, dynamic>? finans) async =>
      _positiveOrNull(_field(finans, 'USD', 'Buying')) ??
      await _binancePrice('USDTTRY');

  Future<double> _binancePrice(String symbol) async {
    final json = await _getJson(
        Uri.https(_binanceHost, '/api/v3/ticker/price', {'symbol': symbol}));
    return _positive(json is Map ? json['price'] : null);
  }

  Future<List<Quote>> fetchCrypto() async {
    try {
      return await _fetchBinance();
    } catch (e) {
      debugPrint('Binance kullanılamadı, Bitlo deneniyor: $e');
      final json = await _getJson(_bitloUri);
      if (json is! List) throw const PriceApiException('Beklenmeyen kripto yanıtı');
      return parseBitlo(json);
    }
  }

  Future<List<Quote>> _fetchBinance({bool retried = false}) async {
    final symbols = await _binanceTrySymbols();
    try {
      final pages = await Future.wait([
        for (var i = 0; i < symbols.length; i += _binanceChunk)
          _getJson(Uri.https(_binanceHost, '/api/v3/ticker/24hr', {
            'type': 'MINI',
            'symbols': jsonEncode(
                symbols.sublist(i, min(i + _binanceChunk, symbols.length))),
          })),
      ]);
      return parseBinance([for (final page in pages) ...page as List]);
    } on PriceApiException catch (e) {
      // Listedeki bir parite kaldırıldıysa Binance tüm isteği 400 ile reddeder.
      if (e.statusCode != 400 || retried) rethrow;
      _trySymbols = null;
      return _fetchBinance(retried: true);
    }
  }

  Future<List<String>> _binanceTrySymbols() async {
    final cached = _trySymbols;
    if (cached != null &&
        DateTime.now().difference(_trySymbolsAt!) < _symbolsTtl) {
      return cached;
    }
    final json = await _getJson(Uri.https(_binanceHost, '/api/v3/ticker/price'));
    final symbols = [
      for (final item in json as List)
        if (item is Map &&
            '${item['symbol']}'.endsWith('TRY') &&
            (double.tryParse('${item['price']}') ?? 0) > 0)
          item['symbol'] as String,
    ];
    if (symbols.isEmpty) throw const PriceApiException('Binance TRY paritesi yok');
    _trySymbols = symbols;
    _trySymbolsAt = DateTime.now();
    return symbols;
  }

  /// Bağlantı yarıda kesilirse ya da yanıt eksik gelirse (Truncgil'de ara
  /// sıra görülüyor) istek bir kez tekrarlanır. Zaman aşımında tekrarlanmaz.
  Future<Object?> _getJson(Uri uri, {bool retry = true}) async {
    try {
      final response =
          await _client.get(uri, headers: _headers).timeout(_timeout);
      if (response.statusCode != 200) {
        throw PriceApiException('${uri.host} HTTP ${response.statusCode}',
            statusCode: response.statusCode);
      }
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on Exception catch (e) {
      final transient = e is http.ClientException || e is FormatException;
      if (!retry || !transient) rethrow;
      debugPrint('${uri.host} isteği tekrarlanıyor: $e');
      await Future<void>.delayed(_retryDelay);
      return _getJson(uri, retry: false);
    }
  }
}

// --- Döviz (Truncgil v4) -------------------------------------------------------

/// v4, JPY'yi 100 kat düşük veriyor (≈0,0031 TL; doğrusu ≈0,31 TL).
/// Değer bu eşiğin altındaysa düzeltilir; kaynak düzelirse koruma devreye girmez.
const _truncgilUnitFixes = <String, ({double below, double factor})>{
  'JPY': (below: 0.05, factor: 100),
};

/// `{"USD": {"Buying": 49.1259, "Selling": 49.1397, "Change": 0.1, "Type": "Currency"}, ...}`
List<Quote> parseTruncgilCurrencies(Map<String, dynamic> json) {
  final currencies = <Quote>[];
  for (final MapEntry(key: code, :value) in json.entries) {
    if (value is! Map || value['Type'] != 'Currency') continue;
    final buy = parseTrNumber(value['Buying']);
    if (buy == null || buy <= 0) continue;
    final sell = parseTrNumber(value['Selling']);
    final fix = _truncgilUnitFixes[code];
    final factor = fix != null && buy < fix.below ? fix.factor : 1;
    currencies.add(Quote(
      type: AssetType.currency,
      code: code,
      name: currencyNames[code] ?? code,
      buy: buy * factor,
      sell: (sell == null || sell <= 0 ? buy : sell) * factor,
      changePercent: parseTrNumber(value['Change']),
    ));
  }
  return currencies;
}

Object? _field(Map<String, dynamic>? json, String key, String field) {
  final entry = json?[key];
  return entry is Map ? entry[field] : null;
}

double? _positiveOrNull(Object? value) {
  final number = value is num ? value.toDouble() : double.tryParse('$value');
  return number != null && number > 0 && number.isFinite ? number : null;
}

double _positive(Object? value) =>
    _positiveOrNull(value) ??
    (throw PriceApiException('Geçersiz fiyat: $value'));

// --- Kripto ------------------------------------------------------------------

/// Binance `ticker/24hr?type=MINI`:
/// `[{"symbol": "BTCTRY", "lastPrice": "4138957.0", "openPrice": "...", "quoteVolume": "...", "count": 1234}]`
List<Quote> parseBinance(List<dynamic> json) {
  final rows = <_CryptoRow>[];
  for (final item in json) {
    if (item is! Map) continue;
    final symbol = item['symbol'];
    if (symbol is! String || !symbol.endsWith('TRY')) continue;
    // İşlem görmeyen (askıya alınmış) pariteler.
    if (item['count'] == 0) continue;
    final last = double.tryParse('${item['lastPrice']}');
    if (last == null || last <= 0) continue;
    final open = double.tryParse('${item['openPrice']}') ?? 0;

    rows.add(_cryptoRow(
      code: symbol.substring(0, symbol.length - 'TRY'.length),
      price: last,
      change: open > 0 ? (last - open) / open * 100 : null,
      volume: double.tryParse('${item['quoteVolume']}') ?? 0,
    ));
  }
  return _rankCrypto(rows);
}

/// Bitlo: `[{"marketCode": "BTC-TRY", "currentQuote": "4136784.00", "change24hPercent": "-0.35", ...}]`
List<Quote> parseBitlo(List<dynamic> json) {
  final rows = <_CryptoRow>[];
  for (final item in json) {
    if (item is! Map) continue;
    final market = item['marketCode'];
    if (market is! String || !market.endsWith('-TRY')) continue;
    final price = double.tryParse('${item['currentQuote']}');
    if (price == null || price <= 0) continue;

    rows.add(_cryptoRow(
      code: market.substring(0, market.length - '-TRY'.length),
      price: price,
      change: double.tryParse('${item['change24hPercent']}'),
      volume: double.tryParse('${item['notionalVolume24h']}') ?? 0,
    ));
  }
  return _rankCrypto(rows);
}

typedef _CryptoRow = ({Quote quote, double volume});

_CryptoRow _cryptoRow({
  required String code,
  required double price,
  required double? change,
  required double volume,
}) =>
    (
      quote: Quote(
        type: AssetType.crypto,
        code: code,
        name: cryptoNames[code] ?? code,
        buy: price,
        sell: price,
        changePercent: change,
      ),
      volume: volume,
    );

/// Bilinen büyük coinler katalog sırasıyla başta, diğerleri işlem hacmine
/// göre arkada listelenir.
List<Quote> _rankCrypto(List<_CryptoRow> rows) {
  final ranks = {for (final (i, code) in cryptoNames.keys.indexed) code: i};
  rows.sort((a, b) {
    final byRank = (ranks[a.quote.code] ?? ranks.length)
        .compareTo(ranks[b.quote.code] ?? ranks.length);
    return byRank != 0 ? byRank : b.volume.compareTo(a.volume);
  });
  return [for (final row in rows) row.quote];
}

/// Sayıları ve "6.553,17", "%-0,59" gibi Türkçe biçimli metinleri çözer.
double? parseTrNumber(Object? value) {
  if (value is num) return value.toDouble();
  if (value is! String) return null;
  final cleaned = value
      .replaceAll(RegExp(r'[^0-9,.\-]'), '')
      .replaceAll('.', '')
      .replaceAll(',', '.');
  return double.tryParse(cleaned);
}
