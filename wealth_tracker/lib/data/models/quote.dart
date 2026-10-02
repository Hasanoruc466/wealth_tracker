import 'asset_type.dart';

/// Bir varlığın TL cinsinden anlık fiyatı.
class Quote {
  const Quote({
    required this.type,
    required this.code,
    required this.name,
    required this.buy,
    required this.sell,
    this.changePercent,
  });

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
        type: AssetType.values.byName(json['type'] as String),
        code: json['code'] as String,
        name: json['name'] as String,
        buy: (json['buy'] as num).toDouble(),
        sell: (json['sell'] as num).toDouble(),
        changePercent: (json['change'] as num?)?.toDouble(),
      );

  static const cash = Quote(
    type: AssetType.cash,
    code: 'TRY',
    name: 'Türk Lirası',
    buy: 1,
    sell: 1,
    changePercent: 0,
  );

  final AssetType type;
  final String code;
  final String name;

  /// Piyasanın alış fiyatı, yani varlığı bugün bozdurursanız eline geçecek tutar.
  final double buy;
  final double sell;

  /// Günlük (kriptoda 24 saatlik) değişim yüzdesi.
  final double? changePercent;

  /// Portföy değerlemesinde kullanılan fiyat.
  double get price => buy;

  String get key => '${type.name}:$code';

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'code': code,
        'name': name,
        'buy': buy,
        'sell': sell,
        'change': changePercent,
      };
}
