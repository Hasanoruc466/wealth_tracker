import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wealth_tracker/data/catalog.dart';
import 'package:wealth_tracker/data/gold_pricing.dart';
import 'package:wealth_tracker/data/models/asset_type.dart';
import 'package:wealth_tracker/data/models/quote.dart';
import 'package:wealth_tracker/data/price_api.dart';

void main() {
  group('parseTrNumber', () {
    test('sayıları ve Türkçe biçimli metinleri çözer', () {
      expect(parseTrNumber('6.553,17'), 6553.17);
      expect(parseTrNumber('0,3109'), 0.3109);
      expect(parseTrNumber('%-0,59'), -0.59);
      expect(parseTrNumber(12), 12.0);
      expect(parseTrNumber(-0.74), -0.74);
      expect(parseTrNumber(null), isNull);
      expect(parseTrNumber('abc'), isNull);
    });
  });

  test('parseTruncgilCurrencies yalnızca dövizleri alır', () {
    final quotes = parseTruncgilCurrencies({
      'Update_Date': '2026-10-02 22:54:01',
      'USD': {'Buying': 49.1259, 'Type': 'Currency', 'Selling': 49.1397, 'Change': 0.1},
      'GRA': {'Buying': 6542.92, 'Type': 'Gold', 'Selling': 6543.82, 'Change': -0.74},
      'XYZ': {'Buying': 0, 'Type': 'Currency', 'Selling': 0},
    });

    final usd = quotes.single;
    expect(usd.key, 'currency:USD');
    expect(usd.name, 'ABD Doları');
    expect(usd.buy, 49.1259);
    expect(usd.sell, 49.1397);
    expect(usd.changePercent, 0.1);
  });

  test("v4'ün JPY birim hatası düzeltilir, doğru değere dokunulmaz", () {
    Map<String, dynamic> jpy(double buy) => {
          'JPY': {'Buying': buy, 'Selling': buy, 'Type': 'Currency', 'Change': 0}
        };
    expect(parseTruncgilCurrencies(jpy(0.003109)).single.buy,
        closeTo(0.3109, 1e-9));
    expect(parseTruncgilCurrencies(jpy(0.3109)).single.buy, 0.3109);
  });

  group('altın hesabı', () {
    test('ons → gram TL', () {
      expect(ounceToGramTry(4143.70, 49.1155), closeTo(6543.32, 0.01));
    });

    test('2 Ekim ölçümüyle aynı alış/satış fiyatlarını üretir', () {
      final quotes = {
        for (final q in priceMetals(
          fineGoldGram: 6543.32,
          fineSilverGram: 95.74,
          goldChangePercent: -0.6,
          silverChangePercent: -0.5,
        ))
          q.code: q,
      };

      expect(quotes.keys, goldNames.keys);
      void check(String code, double buy, double sell) {
        expect(quotes[code]!.buy, closeTo(buy, 0.05), reason: '$code alış');
        expect(quotes[code]!.sell, closeTo(sell, 0.05), reason: '$code satış');
      }

      check('gram-altin', 6504.09, 6640.81);
      check('gram-has-altin', 6536.78, 6608.75);
      check('ceyrek-altin', 10460.35, 10880.86);
      check('yarim-altin', 20920.69, 21866.86);
      check('tam-altin', 41799.34, 43355.25);
      check('cumhuriyet-altini', 42990.88, 44245.14);
      check('resat-altin', 42904.38, 47056.42);
      check('22-ayar-bilezik', 5963.71, 6179.48);
      check('gumus', 87.12, 98.33);
      expect(quotes['ceyrek-altin']!.changePercent, -0.6);
      expect(quotes['gumus']!.changePercent, -0.5);
    });

    test('gümüş fiyatı yoksa gümüş atlanır', () {
      final quotes = priceMetals(fineGoldGram: 6500, fineSilverGram: null);
      expect(quotes.map((q) => q.code), isNot(contains('gumus')));
      expect(quotes, hasLength(goldNames.length - 1));
    });
  });

  group('PriceApi.fetchGold', () {
    final finans = {
      'USD': {'Buying': 50.0, 'Selling': 50.1, 'Type': 'Currency', 'Change': 0.1},
      'GRA': {'Buying': 6500.0, 'Selling': 6501.0, 'Type': 'Gold', 'Change': -0.7},
      'GUMUS': {'Buying': 96.0, 'Selling': 96.1, 'Type': 'Gold', 'Change': 0.3},
    };

    Map<String, double> buys(List<Quote> quotes) =>
        {for (final q in quotes) q.code: q.buy};

    test('ons ve Truncgil kurundan hesaplar', () async {
      final api = PriceApi(client: MockClient((request) async {
        expect(request.headers['User-Agent'], 'Kese/3.0');
        return switch ((request.url.host, request.url.path)) {
          ('api.gold-api.com', '/price/XAU') =>
            http.Response('{"price": 3110.34768}', 200),
          ('api.gold-api.com', '/price/XAG') =>
            http.Response('{"price": 62.2069536}', 200),
          ('finans.truncgil.com', _) => http.Response(jsonEncode(finans), 200),
          _ => http.Response('', 404),
        };
      }));

      final quotes = await api.fetchGold();
      // 3110,35 USD × 50 TL ÷ 31,1035 = gram başına 5000 TL saf altın.
      expect(buys(quotes)['gram-has-altin'], closeTo(5000 * 0.999, 1e-6));
      expect(buys(quotes)['gumus'], closeTo(100 * 0.91, 1e-6));
      expect(quotes.first.changePercent, -0.7);
      expect(quotes.last.changePercent, 0.3);
    });

    test('yedekler: PAXG, Binance kuru ve Truncgil gümüşü', () async {
      final requested = <String>[];
      final api = PriceApi(client: MockClient((request) async {
        requested.add('${request.url.host}${request.url.path}?${request.url.query}');
        return switch (request.url.host) {
          'api.binance.com' => http.Response(
              request.url.queryParameters['symbol'] == 'PAXGUSDT'
                  ? '{"symbol":"PAXGUSDT","price":"3110.34768000"}'
                  : '{"symbol":"USDTTRY","price":"50.00000000"}',
              200),
          _ => http.Response('', 503),
        };
      }));

      final quotes = await api.fetchGold();
      expect(buys(quotes)['gram-has-altin'], closeTo(5000 * 0.999, 1e-6));
      // Gümüş onsu ve Truncgil yoksa gümüş fiyatlanamaz.
      expect(buys(quotes).containsKey('gumus'), isFalse);
      expect(quotes.first.changePercent, isNull);
      expect(requested, contains('api.binance.com/api/v3/ticker/price?symbol=PAXGUSDT'));
    });

    test('ons hiçbir kaynaktan alınamazsa hata verir', () async {
      final api = PriceApi(client: MockClient(
          (request) async => request.url.host == 'finans.truncgil.com'
              ? http.Response(jsonEncode(finans), 200)
              : http.Response('', 503)));
      expect(api.fetchGold(), throwsA(isA<PriceApiException>()));
    });

    test('kesilen bağlantı bir kez tekrarlanır', () async {
      var finansCalls = 0;
      final api = PriceApi(client: MockClient((request) async {
        finansCalls++;
        if (finansCalls == 1) {
          throw http.ClientException('Connection closed before full header');
        }
        return http.Response(jsonEncode(finans), 200);
      }));
      expect((await api.fetchCurrency()).single.code, 'USD');
      expect(finansCalls, 2);
    });

    test('yarım gelen yanıt bir kez tekrarlanır, ikinci hata iletilir', () async {
      var calls = 0;
      final api = PriceApi(client: MockClient((request) async {
        calls++;
        return http.Response('{"USD": {"Buying": 4', 200);
      }));
      await expectLater(api.fetchCurrency(), throwsA(isA<FormatException>()));
      expect(calls, 2);
    });

    test('döviz ve altın aynı Truncgil isteğini paylaşır', () async {
      var finansCalls = 0;
      final api = PriceApi(client: MockClient((request) async {
        if (request.url.host == 'finans.truncgil.com') {
          finansCalls++;
          return http.Response(jsonEncode(finans), 200);
        }
        return http.Response('{"price": 3000}', 200);
      }));
      await Future.wait([api.fetchGold(), api.fetchCurrency()]);
      expect(finansCalls, 1);
    });
  });

  test('parseBinance TRY paritelerini alır, değişimi açılıştan hesaplar', () {
    final quotes = parseBinance([
      {'symbol': 'SANDTRY', 'lastPrice': '3.0', 'openPrice': '2.0', 'quoteVolume': '1000', 'count': 10},
      {'symbol': 'BTCTRY', 'lastPrice': '4100000', 'openPrice': '4000000', 'quoteVolume': '500', 'count': 10},
      {'symbol': 'BTCUSDT', 'lastPrice': '100000', 'openPrice': '1', 'quoteVolume': '9999', 'count': 10},
      {'symbol': 'OLDTRY', 'lastPrice': '1', 'openPrice': '1', 'quoteVolume': '0', 'count': 0},
    ]);

    // Bilinen coinler hacimden bağımsız olarak önce gelir.
    expect(quotes.map((q) => q.code), ['BTC', 'SAND']);
    expect(quotes.first.name, 'Bitcoin');
    expect(quotes.first.changePercent, closeTo(2.5, 1e-9));
    expect(quotes.last.changePercent, closeTo(50, 1e-9));
  });

  test('parseBitlo yalnızca TRY paritelerini alır', () {
    final quotes = parseBitlo([
      {'marketCode': 'ETH-TRY', 'currentQuote': '150000.00', 'change24hPercent': '1.5'},
      {'marketCode': 'BTC-USDT', 'currentQuote': '100000'},
      {'marketCode': 'DEAD-TRY', 'currentQuote': '0'},
      'çöp',
    ]);
    expect(quotes.single.code, 'ETH');
    expect(quotes.single.changePercent, 1.5);
  });

  group('PriceApi.fetchCrypto', () {
    test('Binance pariteleri önbelleğe alır, kaldırılan pariteyle yeniler',
        () async {
      var priceListCalls = 0;
      var listed = ['BTCTRY', 'ETHTRY', 'OLDTRY'];
      final api = PriceApi(client: MockClient((request) async {
        switch (request.url.path) {
          case '/api/v3/ticker/price':
            priceListCalls++;
            return http.Response(
                jsonEncode([
                  for (final s in listed) {'symbol': s, 'price': '1'},
                  {'symbol': 'BTCUSDT', 'price': '1'},
                ]),
                200);
          case '/api/v3/ticker/24hr':
            final symbols = (jsonDecode(request.url.queryParameters['symbols']!)
                    as List)
                .cast<String>();
            if (symbols.any((s) => !listed.contains(s))) {
              return http.Response('{"code":-1121,"msg":"Invalid symbol."}', 400);
            }
            return http.Response(
                jsonEncode([
                  for (final s in symbols)
                    {'symbol': s, 'lastPrice': '10', 'openPrice': '10', 'quoteVolume': '1', 'count': 1},
                ]),
                200);
        }
        return http.Response('', 404);
      }));

      expect((await api.fetchCrypto()).map((q) => q.code), ['BTC', 'ETH', 'OLD']);
      await api.fetchCrypto();
      expect(priceListCalls, 1);

      listed = ['BTCTRY', 'ETHTRY'];
      expect((await api.fetchCrypto()).map((q) => q.code), ['BTC', 'ETH']);
      expect(priceListCalls, 2);
    });

    test("Binance'e ulaşılamazsa Bitlo kullanılır", () async {
      final api = PriceApi(client: MockClient((request) async {
        if (request.url.host == 'api.binance.com') {
          return http.Response('', 451);
        }
        return http.Response(
            jsonEncode([
              {'marketCode': 'BTC-TRY', 'currentQuote': '4000000'},
            ]),
            200);
      }));

      final quotes = await api.fetchCrypto();
      expect(quotes.single.code, 'BTC');
      expect(quotes.single.type, AssetType.crypto);
    });
  });
}
