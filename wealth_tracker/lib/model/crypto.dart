class Crypto{
  final String marketCode;
  final String assetCode;
  final double currentPrice;

  Crypto({
    required this.marketCode,
    required this.assetCode,
    required this.currentPrice,
  });

    // JSON'dan Sınıfa (Deserialization)
  factory Crypto.fromJson(Map<String, dynamic> json) {
    String marketCode = json['marketCode'] as String;
    String currentQuote = json['currentQuote'] as String;
    return Crypto(
      marketCode: marketCode,
      assetCode: marketCode.substring(0, marketCode.lastIndexOf("-")),
      currentPrice: double.parse(currentQuote),
    );
    }
}