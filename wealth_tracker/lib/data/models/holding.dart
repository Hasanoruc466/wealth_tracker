import 'asset_type.dart';

/// Kullanıcının sahip olduğu bir varlık ve miktarı.
class Holding {
  const Holding({
    required this.type,
    required this.code,
    required this.amount,
    this.avgCost,
  });

  factory Holding.fromJson(Map<String, dynamic> json) => Holding(
        type: AssetType.values.byName(json['type'] as String),
        code: json['code'] as String,
        amount: (json['amount'] as num).toDouble(),
        avgCost: (json['avgCost'] as num?)?.toDouble(),
      );

  final AssetType type;
  final String code;
  final double amount;

  /// Birim başına ortalama alış fiyatı (TL). Bilinmiyorsa `null`.
  final double? avgCost;

  /// Bir varlık türü ve kodu birlikte benzersizdir.
  String get key => '${type.name}:$code';

  /// Toplam alış maliyeti; ortalama alış fiyatı bilinmiyorsa `null`.
  double? get cost => avgCost == null ? null : avgCost! * amount;

  Holding copyWith({double? amount}) => Holding(
        type: type,
        code: code,
        amount: amount ?? this.amount,
        avgCost: avgCost,
      );

  /// [amount] kadar [unitCost] fiyatından alım ekler. Ortalama maliyet yalnızca
  /// iki tarafın da maliyeti biliniyorsa korunur.
  Holding merge(double amount, double? unitCost) {
    final total = this.amount + amount;
    final cost = this.cost;
    return Holding(
      type: type,
      code: code,
      amount: total,
      avgCost: cost == null || unitCost == null
          ? null
          : (cost + unitCost * amount) / total,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'code': code,
        'amount': amount,
        if (avgCost != null) 'avgCost': avgCost,
      };
}
