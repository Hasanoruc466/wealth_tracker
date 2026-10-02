import 'catalog.dart';
import 'models/asset_type.dart';
import 'models/quote.dart';

const gramsPerTroyOunce = 31.1034768;

/// Bir altın/gümüş türünün fiyatlanma kuralı.
class MetalSpec {
  const MetalSpec({
    required this.fineGrams,
    required this.buyMargin,
    required this.sellMargin,
  });

  /// Bir birimdeki saf metal (gram).
  final double fineGrams;

  /// Saf metal değerine göre kuyumcu alış/satış farkı (−0,005 = %0,5 altı).
  final double buyMargin;
  final double sellMargin;
}

/// Sikkeler 22 ayardır (0,916 milyem); ağırlıklar Darphane standardıdır.
///
/// Marjlar 2 Ekim 2026'da Kapalıçarşı (Altınkaynak) ve Harem Altın
/// fiyatlarıyla ölçülmüştür. Alış marjları kararlıdır; satış marjları
/// (işçilik, kuyumcu primi) piyasayla değişebilir, gerekirse buradan ayarlanır.
const goldSpecs = <String, MetalSpec>{
  'gram-altin': MetalSpec(fineGrams: 0.995, buyMargin: -0.001, sellMargin: 0.020),
  'gram-has-altin': MetalSpec(fineGrams: 1, buyMargin: -0.001, sellMargin: 0.010),
  'ceyrek-altin': MetalSpec(fineGrams: 1.754 * 0.916, buyMargin: -0.005, sellMargin: 0.035),
  'yarim-altin': MetalSpec(fineGrams: 3.508 * 0.916, buyMargin: -0.005, sellMargin: 0.040),
  'tam-altin': MetalSpec(fineGrams: 7.016 * 0.916, buyMargin: -0.006, sellMargin: 0.031),
  'cumhuriyet-altini': MetalSpec(fineGrams: 7.216 * 0.916, buyMargin: -0.006, sellMargin: 0.023),
  'resat-altin': MetalSpec(fineGrams: 7.216 * 0.916, buyMargin: -0.008, sellMargin: 0.088),
  '22-ayar-bilezik': MetalSpec(fineGrams: 0.916, buyMargin: -0.005, sellMargin: 0.031),
};

/// Kuyumcular gümüşü saf değerinin belirgin şekilde altında alır.
const silverSpec = MetalSpec(fineGrams: 1, buyMargin: -0.090, sellMargin: 0.027);

/// Gram başına saf altın ve gümüş fiyatından (TL) [goldNames] sırasıyla
/// alış/satış fiyatlarını üretir. Gümüş fiyatı yoksa gümüş atlanır.
List<Quote> priceMetals({
  required double fineGoldGram,
  required double? fineSilverGram,
  double? goldChangePercent,
  double? silverChangePercent,
}) {
  Quote price(String code, MetalSpec spec, double base, double? change) {
    final value = base * spec.fineGrams;
    return Quote(
      type: AssetType.gold,
      code: code,
      name: goldNames[code]!,
      buy: value * (1 + spec.buyMargin),
      sell: value * (1 + spec.sellMargin),
      changePercent: change,
    );
  }

  return [
    for (final code in goldNames.keys)
      if (goldSpecs[code] case final spec?)
        price(code, spec, fineGoldGram, goldChangePercent)
      else if (code == 'gumus' && fineSilverGram != null)
        price(code, silverSpec, fineSilverGram, silverChangePercent),
  ];
}

/// Ons (USD) fiyatını gram başına TL'ye çevirir.
double ounceToGramTry(double ounceUsd, double usdTry) =>
    ounceUsd * usdTry / gramsPerTroyOunce;
