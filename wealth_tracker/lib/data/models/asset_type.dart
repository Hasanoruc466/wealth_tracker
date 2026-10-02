enum AssetType {
  gold('Altın'),
  currency('Döviz'),
  crypto('Kripto'),
  cash('Nakit');

  const AssetType(this.label);

  final String label;

  /// Piyasa ekranında listelenen türler (nakit TL'nin piyasası yoktur).
  static const markets = [gold, currency, crypto];
}
