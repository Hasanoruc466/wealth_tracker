class Asset{
  final String assetType;
  final String name;
  double amount;

  Asset({
    required this.assetType,
    required this.name,
    required this.amount,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      assetType: json['assetType'],
      name: json['name'],
      amount: json['amount'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assetType': assetType,
      'name': name,
      'amount': amount,
    };
  }
}