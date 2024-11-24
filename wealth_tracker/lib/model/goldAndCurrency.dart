class GoldAndCurrency{
  final String fullName;
  final double buy;
  final double sell;
  GoldAndCurrency({
    required this.fullName,
    required this.buy,
    required this.sell,
  });

    // JSON'dan Sınıfa (Deserialization)
  factory GoldAndCurrency.fromJson(Map<String, dynamic> json) {
    return GoldAndCurrency(
      fullName: json['Isim'] as String,
      buy: parseDouble(json['ForexBuying']),
      sell: parseDouble(json['ForexSelling']),
    );
  }
}


  double parseDouble(dynamic value) {
  if (value is int) {
    return value.toDouble();
  } else if (value is double) {
    return value;
  } else {
    return 0;
  }
}
