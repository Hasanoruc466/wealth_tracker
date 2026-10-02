import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_tracker/core/format.dart';

void main() {
  test('parseAmount virgül ve noktayı kabul eder', () {
    expect(Fmt.parseAmount('1,5'), 1.5);
    expect(Fmt.parseAmount('1.5'), 1.5);
    expect(Fmt.parseAmount('1.234,5'), 1234.5);
    expect(Fmt.parseAmount(' 10 '), 10);
    expect(Fmt.parseAmount(''), isNull);
    expect(Fmt.parseAmount(','), isNull);
  });

  test('para ve yüzde Türkçe biçimlenir', () {
    expect(Fmt.money(1234567.891), '₺1.234.567,89');
    expect(Fmt.price(0.000512), '₺0,00051200');
    expect(Fmt.percent(1.234), '+%1,23');
    expect(Fmt.percent(-0.5), '−%0,50');
    expect(Fmt.percent(0), '%0,00');
    expect(Fmt.signedMoney(-12), '−₺12,00');
    expect(Fmt.amountInput(1234.5), '1234,5');
  });

  test('portföy payı uç değerlerde yanıltıcı yuvarlanmaz', () {
    expect(Fmt.share(45.24), '%45,2');
    expect(Fmt.share(0.04), '<%0,1');
    expect(Fmt.share(99.99), '>%99,9');
    expect(Fmt.share(100), '%100,0');
    expect(Fmt.percentAbs(-0.35), '%0,35');
  });
}
