import 'package:wealth_tracker/data/models/asset_type.dart';
import 'package:wealth_tracker/data/models/quote.dart';
import 'package:wealth_tracker/data/price_api.dart';

const gramGold = Quote(
  type: AssetType.gold,
  code: 'gram-altin',
  name: 'Gram Altın',
  buy: 3000,
  sell: 3010,
  changePercent: 1,
);

const usd = Quote(
  type: AssetType.currency,
  code: 'USD',
  name: 'ABD Doları',
  buy: 40,
  sell: 40.1,
  changePercent: -0.5,
);

const btc = Quote(
  type: AssetType.crypto,
  code: 'BTC',
  name: 'Bitcoin',
  buy: 4000000,
  sell: 4000000,
  changePercent: 2,
);

class FakePriceApi extends PriceApi {
  FakePriceApi({bool failAll = false})
      : failGold = failAll,
        failCurrency = failAll,
        failCrypto = failAll;

  bool failGold;
  bool failCurrency;
  bool failCrypto;

  /// Döviz kaynağına yapılan istek sayısı (yenileme sıklığı testleri için).
  int currencyCalls = 0;

  set failAll(bool value) {
    failGold = failCurrency = failCrypto = value;
  }

  @override
  Future<List<Quote>> fetchGold() async {
    if (failGold) throw const PriceApiException('gold down');
    return const [gramGold];
  }

  @override
  Future<List<Quote>> fetchCurrency() async {
    currencyCalls++;
    if (failCurrency) throw const PriceApiException('currency down');
    return const [usd];
  }

  @override
  Future<List<Quote>> fetchCrypto() async {
    if (failCrypto) throw const PriceApiException('crypto down');
    return const [btc];
  }
}
