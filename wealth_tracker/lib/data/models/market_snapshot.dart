import 'asset_type.dart';
import 'quote.dart';

/// Belirli bir anda tüm piyasaların fiyatları.
class MarketSnapshot {
  MarketSnapshot({
    required this.quotes,
    required this.updatedAt,
    this.isStale = false,
  });

  factory MarketSnapshot.fromJson(Map<String, dynamic> json) {
    final quotes = <AssetType, List<Quote>>{};
    for (final item in json['quotes'] as List) {
      final quote = Quote.fromJson(item as Map<String, dynamic>);
      quotes.putIfAbsent(quote.type, () => []).add(quote);
    }
    return MarketSnapshot(
      quotes: quotes,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final Map<AssetType, List<Quote>> quotes;
  final DateTime updatedAt;

  /// Kaynaklardan en az biri yanıt vermediyse ve önbellekteki veri
  /// kullanıldıysa `true` olur.
  final bool isStale;

  late final Map<String, Quote> _index = {
    for (final list in quotes.values)
      for (final quote in list) quote.key: quote,
  };

  List<Quote> of(AssetType type) =>
      type == AssetType.cash ? const [Quote.cash] : quotes[type] ?? const [];

  Quote? find(AssetType type, String code) =>
      type == AssetType.cash ? Quote.cash : _index['${type.name}:$code'];

  Map<String, dynamic> toJson() => {
        'updatedAt': updatedAt.toIso8601String(),
        'quotes': [
          for (final list in quotes.values)
            for (final quote in list) quote.toJson(),
        ],
      };
}
