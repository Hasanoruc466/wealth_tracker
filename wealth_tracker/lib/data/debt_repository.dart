import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/debt.dart';

/// Kullanıcının borç ve alacaklarını cihazda saklar.
class DebtRepository {
  DebtRepository(this._prefs);

  static const _key = 'debts.v1';

  final SharedPreferences _prefs;

  List<Debt> load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    final debts = <Debt>[];
    for (final item in jsonDecode(raw) as List) {
      try {
        debts.add(Debt.fromJson(item as Map<String, dynamic>));
      } catch (e) {
        debugPrint('Bozuk borç kaydı atlandı: $item ($e)');
      }
    }
    return debts;
  }

  Future<void> save(List<Debt> debts) => _prefs.setString(
        _key,
        jsonEncode([for (final debt in debts) debt.toJson()]),
      );
}
