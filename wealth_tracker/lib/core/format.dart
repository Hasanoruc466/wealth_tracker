import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

const _locale = 'tr_TR';

abstract final class Fmt {
  static final _money =
      NumberFormat.currency(locale: _locale, symbol: '₺', decimalDigits: 2);
  static final _amount = NumberFormat.decimalPattern(_locale)
    ..maximumFractionDigits = 8;
  static final _percent = NumberFormat('0.00', _locale);
  static final _plain = NumberFormat('0.########', _locale);
  static final _share = NumberFormat('0.0', _locale);

  /// ₺1.234,56
  static String money(double value) => _money.format(value);

  /// Küçük fiyatlarda (ör. SHIB) daha fazla ondalık gösterir.
  static String price(double value) {
    final abs = value.abs();
    if (abs >= 1) return money(value);
    final digits = abs >= 0.01 ? 4 : 8;
    return NumberFormat.currency(
            locale: _locale, symbol: '₺', decimalDigits: digits)
        .format(value);
  }

  /// 1.234,5
  static String amount(double value) => _amount.format(value);

  /// Düzenleme alanı için gruplama ayırıcısı olmadan: 1234,5
  static String amountInput(double value) => _plain.format(value);

  /// +%1,23 / −%0,45
  static String percent(double value) {
    final sign = value > 0.004 ? '+' : (value < -0.004 ? '−' : '');
    return '$sign%${_percent.format(value.abs())}';
  }

  /// İşaretsiz yüzde: %1,23 (yön ok simgesiyle gösterildiğinde).
  static String percentAbs(double value) => '%${_percent.format(value.abs())}';

  /// Gizli bakiye modunda tutarların yerine geçer.
  static const hidden = '₺•••••';

  /// Gizli bakiye modunda miktarların yerine geçer.
  static const hiddenAmount = '•••';

  /// Portföy payı: %45,2. Yuvarlama yanıltmasın diye çok küçük paylar
  /// "<%0,1", %100'e çok yakın paylar ">%99,9" olarak gösterilir.
  static String share(double value) => switch (value) {
        > 0 && < 0.1 => '<%0,1',
        >= 99.95 && < 100 => '>%99,9',
        _ => '%${_share.format(value)}',
      };

  /// +₺1.234,56 / −₺12,00
  static String signedMoney(double value) {
    final sign = value > 0.004 ? '+' : (value < -0.004 ? '−' : '');
    return '$sign${money(value.abs())}';
  }

  static const _months = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', //
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];

  /// 12 Ekim; farklı yıldaysa 12 Ekim 2027.
  static String date(DateTime d, {DateTime? now}) {
    final text = '${d.day} ${_months[d.month - 1]}';
    return d.year == (now ?? DateTime.now()).year ? text : '$text ${d.year}';
  }

  static String time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// Kullanıcı girdisini sayıya çevirir. Hem "1,5" hem "1.5" kabul edilir;
  /// virgül varsa noktalar binlik ayırıcı sayılır.
  static double? parseAmount(String input) {
    var text = input.trim().replaceAll(' ', '');
    if (text.isEmpty) return null;
    if (text.contains(',')) {
      text = text.replaceAll('.', '').replaceAll(',', '.');
    }
    final value = double.tryParse(text);
    return value == null || value.isNaN || value.isInfinite ? null : value;
  }

  /// Rakam ve en fazla bir ondalık ayırıcıya izin verir.
  static final amountInputFormatter = TextInputFormatter.withFunction(
    (oldValue, newValue) =>
        RegExp(r'^\d*([.,]\d*)?$').hasMatch(newValue.text) ? newValue : oldValue,
  );
}
