import 'asset_type.dart';
import 'quote.dart';

/// Borcun yönü.
enum DebtDirection {
  /// Kullanıcının başkasına verdiği; geri alacağı.
  lent('Alacaklarım', 'Borç verdim'),

  /// Kullanıcının başkasından aldığı; geri ödeyeceği.
  borrowed('Borçlarım', 'Borç aldım');

  const DebtDirection(this.title, this.action);

  /// Liste bölüm başlığı.
  final String title;

  /// Ekleme ekranındaki seçenek.
  final String action;

  /// Birim değer. Alacak, geri alındığında bozdurulacağı için alış fiyatıyla;
  /// borç, ödemek için varlığın piyasadan satın alınması gerektiğinden satış
  /// fiyatıyla değerlenir.
  double unitPrice(Quote quote) => this == lent ? quote.buy : quote.sell;
}

/// Bir kişiyle arasındaki borç ya da alacak. Miktar herhangi bir varlık
/// cinsinden olabilir (ör. 2 çeyrek altın, 100 dolar) ve güncel fiyatla
/// TL'ye çevrilir.
class Debt {
  const Debt({
    required this.id,
    required this.direction,
    required this.person,
    required this.type,
    required this.code,
    required this.amount,
    this.dueDate,
    this.note,
  });

  factory Debt.fromJson(Map<String, dynamic> json) => Debt(
        id: json['id'] as String,
        direction: DebtDirection.values.byName(json['direction'] as String),
        person: json['person'] as String,
        type: AssetType.values.byName(json['type'] as String),
        code: json['code'] as String,
        amount: (json['amount'] as num).toDouble(),
        dueDate: json['dueDate'] == null
            ? null
            : DateTime.parse(json['dueDate'] as String),
        note: json['note'] as String?,
      );

  final String id;
  final DebtDirection direction;
  final String person;
  final AssetType type;
  final String code;
  final double amount;
  final DateTime? dueDate;
  final String? note;

  bool get isLent => direction == DebtDirection.lent;

  /// Vadesi bugünden önceyse `true`.
  bool isOverdue(DateTime now) {
    final due = dueDate;
    if (due == null) return false;
    return due.isBefore(DateTime(now.year, now.month, now.day));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'direction': direction.name,
        'person': person,
        'type': type.name,
        'code': code,
        'amount': amount,
        if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
        if (note != null) 'note': note,
      };
}
