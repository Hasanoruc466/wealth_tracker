import 'models/asset_type.dart';

/// Takip edilen altın ve gümüş türleri: uygulama kodu → görünen ad.
/// Sıra, listelerde gösterilen sıradır.
const goldNames = <String, String>{
  'gram-altin': 'Gram Altın',
  'gram-has-altin': 'Has Altın',
  'ceyrek-altin': 'Çeyrek Altın',
  'yarim-altin': 'Yarım Altın',
  'tam-altin': 'Tam Altın',
  'cumhuriyet-altini': 'Cumhuriyet Altını',
  'resat-altin': 'Reşat Altın',
  '22-ayar-bilezik': '22 Ayar Bilezik',
  'gumus': 'Gümüş',
};

/// Aynı varlığın eski kodları. Ata altın, Cumhuriyet altınıyla aynıdır.
const goldAliases = <String, String>{'ata-altin': 'cumhuriyet-altini'};

/// Artık fiyatı takip edilmeyen ama portföylerde kalmış olabilecek türler.
const _retiredGoldNames = <String, String>{
  'hamit-altin': 'Hamit Altın',
  'ikibucuk-altin': 'İkibuçuk Altın',
  'besli-altin': 'Beşli Altın',
  'gremse-altin': 'Gremse Altın',
  '18-ayar-altin': '18 Ayar Altın',
  '14-ayar-altin': '14 Ayar Altın',
  'gram-platin': 'Platin',
  'gram-paladyum': 'Paladyum',
};

const currencyNames = <String, String>{
  'USD': 'ABD Doları',
  'EUR': 'Euro',
  'GBP': 'İngiliz Sterlini',
  'CHF': 'İsviçre Frangı',
  'CAD': 'Kanada Doları',
  'RUB': 'Rus Rublesi',
  'AED': 'BAE Dirhemi',
  'AUD': 'Avustralya Doları',
  'DKK': 'Danimarka Kronu',
  'SEK': 'İsveç Kronu',
  'NOK': 'Norveç Kronu',
  'JPY': 'Japon Yeni',
  'KWD': 'Kuveyt Dinarı',
  'ZAR': 'Güney Afrika Randı',
  'BHD': 'Bahreyn Dinarı',
  'LYD': 'Libya Dinarı',
  'SAR': 'Suudi Riyali',
  'IQD': 'Irak Dinarı',
  'ILS': 'İsrail Şekeli',
  'INR': 'Hindistan Rupisi',
  'MXN': 'Meksika Pesosu',
  'HUF': 'Macar Forinti',
  'NZD': 'Yeni Zelanda Doları',
  'BRL': 'Brezilya Reali',
  'IDR': 'Endonezya Rupisi',
  'CZK': 'Çek Korunası',
  'PLN': 'Polonya Zlotisi',
  'RON': 'Rumen Leyi',
  'CNY': 'Çin Yuanı',
  'ARS': 'Arjantin Pesosu',
  'ALL': 'Arnavut Leki',
  'AZN': 'Azerbaycan Manatı',
  'BAM': 'Bosna-Hersek Markı',
  'CLP': 'Şili Pesosu',
  'COP': 'Kolombiya Pesosu',
  'CRC': 'Kosta Rika Kolonu',
  'DZD': 'Cezayir Dinarı',
  'EGP': 'Mısır Lirası',
  'HKD': 'Hong Kong Doları',
  'ISK': 'İzlanda Kronu',
  'KRW': 'Güney Kore Wonu',
  'KZT': 'Kazak Tengesi',
  'LBP': 'Lübnan Lirası',
  'LKR': 'Sri Lanka Rupisi',
  'MAD': 'Fas Dirhemi',
  'MDL': 'Moldova Leyi',
  'MKD': 'Makedon Dinarı',
  'MYR': 'Malezya Ringgiti',
  'OMR': 'Umman Riyali',
  'PEN': 'Peru Solü',
  'PHP': 'Filipin Pesosu',
  'PKR': 'Pakistan Rupisi',
  'QAR': 'Katar Riyali',
  'RSD': 'Sırp Dinarı',
  'SGD': 'Singapur Doları',
  'SYP': 'Suriye Lirası',
  'THB': 'Tayland Bahtı',
  'TWD': 'Tayvan Doları',
  'UAH': 'Ukrayna Grivnası',
  'UYU': 'Uruguay Pesosu',
  'GEL': 'Gürcistan Larisi',
  'TND': 'Tunus Dinarı',
  'BGN': 'Bulgar Levası',
  'VND': 'Vietnam Dongu',
};

const cryptoNames = <String, String>{
  'BTC': 'Bitcoin',
  'ETH': 'Ethereum',
  'USDT': 'Tether',
  'XRP': 'XRP',
  'BNB': 'BNB',
  'SOL': 'Solana',
  'ADA': 'Cardano',
  'DOGE': 'Dogecoin',
  'AVAX': 'Avalanche',
  'DOT': 'Polkadot',
  'TRX': 'TRON',
  'LINK': 'Chainlink',
  'LTC': 'Litecoin',
  'BCH': 'Bitcoin Cash',
  'SHIB': 'Shiba Inu',
  'ATOM': 'Cosmos',
  'NEAR': 'NEAR Protocol',
  'UNI': 'Uniswap',
  'AAVE': 'Aave',
  'PAXG': 'PAX Gold',
  'SUI': 'Sui',
  'TON': 'Toncoin',
  'XLM': 'Stellar',
  'HBAR': 'Hedera',
  'ETC': 'Ethereum Classic',
  'APT': 'Aptos',
  'ARB': 'Arbitrum',
  'OP': 'Optimism',
  'POL': 'Polygon',
  'FET': 'Artificial Superintelligence',
  'RENDER': 'Render',
  'ICP': 'Internet Computer',
  'FIL': 'Filecoin',
  'PEPE': 'Pepe',
  'FLOKI': 'Floki',
  'BONK': 'Bonk',
  'WIF': 'dogwifhat',
  'ENA': 'Ethena',
};

/// Altın türleri için kısa kimyasal simge, diğerleri için kod.
String shortLabel(AssetType type, String code) => switch (type) {
      AssetType.gold => switch (code) {
          'gumus' => 'Ag',
          'gram-platin' => 'Pt',
          'gram-paladyum' => 'Pd',
          _ => 'Au',
        },
      AssetType.cash => '₺',
      _ => code.length > 4 ? code.substring(0, 4) : code,
    };

/// Fiyat bilgisi gelmese bile bir varlığa okunabilir bir ad verir.
String displayName(AssetType type, String code) => switch (type) {
      AssetType.gold => goldNames[code] ?? _retiredGoldNames[code],
      AssetType.currency => currencyNames[code],
      AssetType.crypto => cryptoNames[code],
      AssetType.cash => 'Türk Lirası',
    } ??
    code;

// --- 2.x sürümünden kalan veriler -------------------------------------------

/// Eski sürüm altınları görünen adlarıyla saklıyordu.
const legacyGoldNames = <String, String>{
  'Has Altın': 'gram-has-altin',
  'Çeyrek Altın': 'ceyrek-altin',
  'Yarım Altın': 'yarim-altin',
  'Tam Altın': 'tam-altin',
  'Cumhuriyet Altını': 'cumhuriyet-altini',
  'Ata Altın': 'cumhuriyet-altini',
  '14 Ayar Altın': '14-ayar-altin',
  '18 Ayar Altın': '18-ayar-altin',
  '22 Ayar Altın': '22-ayar-bilezik',
  'Reşat Altın': 'resat-altin',
  'Gram Altın': 'gram-altin',
  'Gümüş': 'gumus',
  'Platin': 'gram-platin',
};

/// Eski sürüm dövizleri TCMB'deki Türkçe adlarıyla saklıyordu.
const legacyCurrencyNames = <String, String>{
  'ABD DOLARI': 'USD',
  'AVUSTRALYA DOLARI': 'AUD',
  'DANİMARKA KRONU': 'DKK',
  'EURO': 'EUR',
  'İNGİLİZ STERLİNİ': 'GBP',
  'İSVİÇRE FRANGI': 'CHF',
  'İSVEÇ KRONU': 'SEK',
  'KANADA DOLARI': 'CAD',
  'KUVEYT DİNARI': 'KWD',
  'NORVEÇ KRONU': 'NOK',
  'SUUDİ ARABİSTAN RİYALİ': 'SAR',
  'JAPON YENİ': 'JPY',
  'RUMEN LEYİ': 'RON',
  'RUS RUBLESİ': 'RUB',
  'ÇİN YUANI': 'CNY',
  'PAKİSTAN RUPİSİ': 'PKR',
  'KATAR RİYALİ': 'QAR',
  'GÜNEY KORE WONU': 'KRW',
  'AZERBAYCAN YENİ MANATI': 'AZN',
  'BİRLEŞİK ARAP EMİRLİKLERİ DİRHEMİ': 'AED',
  'KAZAKİSTAN TENGESİ': 'KZT',
};

/// Gramla ölçülen altın ve değerli metaller; diğer altınlar adetle sayılır.
const _gramMetals = {
  'gram-altin',
  'gram-has-altin',
  '22-ayar-bilezik',
  '18-ayar-altin',
  '14-ayar-altin',
  'gumus',
  'gram-platin',
  'gram-paladyum',
};

/// Miktar alanının yanında gösterilen birim (gram, adet, USD…).
String? unitLabel(AssetType type, String? code) => switch (type) {
      AssetType.gold when code == null => null,
      AssetType.gold => _gramMetals.contains(code) ? 'gram' : 'adet',
      AssetType.cash => 'TL',
      _ => code,
    };
