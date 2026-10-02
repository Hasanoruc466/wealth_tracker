import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'catalog.dart';
import 'models/asset_type.dart';
import 'models/holding.dart';

/// Kullanıcının varlıklarını cihazda saklar.
class PortfolioRepository {
  PortfolioRepository(this._prefs);

  static const _key = 'portfolio.v2';

  /// 2.x sürümünün kullandığı anahtar.
  static const legacyKey = 'assets';

  final SharedPreferences _prefs;

  List<Holding> load() {
    final raw = _prefs.getString(_key);
    if (raw != null) return _decode(raw);

    final legacy = _prefs.getStringList(legacyKey);
    if (legacy == null) return [];
    final migrated = migrateLegacyAssets(legacy);
    save(migrated).then((_) => _prefs.remove(legacyKey));
    return migrated;
  }

  Future<void> save(List<Holding> holdings) => _prefs.setString(
        _key,
        jsonEncode([for (final holding in holdings) holding.toJson()]),
      );

  List<Holding> _decode(String raw) {
    final holdings = <String, Holding>{};
    for (final item in jsonDecode(raw) as List) {
      try {
        var holding = Holding.fromJson(item as Map<String, dynamic>);
        final alias = holding.type == AssetType.gold
            ? goldAliases[holding.code]
            : null;
        if (alias != null) {
          holding = Holding(
            type: holding.type,
            code: alias,
            amount: holding.amount,
            avgCost: holding.avgCost,
          );
        }
        final existing = holdings[holding.key];
        holdings[holding.key] = existing == null
            ? holding
            : existing.merge(holding.amount, holding.avgCost);
      } catch (e) {
        debugPrint('Bozuk varlık kaydı atlandı: $item ($e)');
      }
    }
    return holdings.values.toList();
  }
}

/// 2.x kayıtlarını (`{"assetType": "Döviz", "name": "ABD DOLARI", "amount": 10}`)
/// yeni biçime çevirir. Aynı varlığa ait kayıtlar birleştirilir.
List<Holding> migrateLegacyAssets(List<String> rows) {
  final merged = <String, Holding>{};
  for (final row in rows) {
    try {
      final json = jsonDecode(row) as Map<String, dynamic>;
      final name = (json['name'] as String).trim();
      final amount = (json['amount'] as num).toDouble();
      final (type, code) = switch (json['assetType']) {
        'Altın' => (AssetType.gold, legacyGoldNames[name] ?? name),
        'Döviz' => (AssetType.currency, legacyCurrencyNames[name] ?? name),
        'Kripto' => (AssetType.crypto, name),
        _ => (AssetType.cash, 'TRY'),
      };
      if (amount <= 0) continue;

      final holding = Holding(type: type, code: code, amount: amount);
      final existing = merged[holding.key];
      merged[holding.key] = existing == null
          ? holding
          : existing.copyWith(amount: existing.amount + amount);
    } catch (e) {
      debugPrint('Eski kayıt taşınamadı: $row ($e)');
    }
  }
  return merged.values.toList();
}
