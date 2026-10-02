import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Bir günün sonunda (ya da o güne ait son ölçümde) portföyün toplam değeri.
class HistoryPoint {
  const HistoryPoint(this.day, this.total);

  final DateTime day;
  final double total;
}

/// Portföyün günlük toplam değerlerini cihazda saklar. Her gün için yalnızca
/// son ölçüm tutulur.
class HistoryRepository {
  HistoryRepository(this._prefs);

  static const _key = 'history.v1';

  /// Bir yıldan eski kayıtlar atılır.
  static const maxDays = 366;

  final SharedPreferences _prefs;

  /// Eskiden yeniye sıralı.
  List<HistoryPoint> load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    try {
      final map = (jsonDecode(raw) as Map<String, dynamic>)
          .map((day, total) => MapEntry(day, (total as num).toDouble()));
      final days = map.keys.toList()..sort();
      return [for (final day in days) HistoryPoint(DateTime.parse(day), map[day]!)];
    } catch (_) {
      return [];
    }
  }

  /// Bugünün değerini kaydeder ve güncel listeyi döndürür.
  List<HistoryPoint> record(DateTime now, double total) {
    final today = DateTime(now.year, now.month, now.day);
    final points = [
      for (final p in load())
        if (p.day != today) p,
      HistoryPoint(today, total),
    ]..sort((a, b) => a.day.compareTo(b.day));
    final kept = points.length > maxDays
        ? points.sublist(points.length - maxDays)
        : points;
    _prefs.setString(
      _key,
      jsonEncode({for (final p in kept) _dayKey(p.day): p.total}),
    );
    return kept;
  }

  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
