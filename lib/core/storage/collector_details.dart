import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CollectorLocalStorage {
  static const String _collectorKey = 'collector_data';

  Future<void> saveCollector(
    Map<String, dynamic> collector,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _collectorKey,
      jsonEncode(collector),
    );
  }

  Future<Map<String, dynamic>?> getCollector() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getString(_collectorKey);

    if (data == null) return null;

    return jsonDecode(data) as Map<String, dynamic>;
  }

  Future<void> clearCollector() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_collectorKey);
  }
}
