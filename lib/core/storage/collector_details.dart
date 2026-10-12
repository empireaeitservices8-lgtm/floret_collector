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

  Future<String> getUsername() async {
    final collector = await getCollector();
    final username = collector?['username']?.toString() ??
        collector?['user_name']?.toString();
    if (username != null && username.trim().isNotEmpty) {
      return username.trim();
    }
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('saved_username') ??
        prefs.getString('KEY_USER_NAME');
    if (saved != null && saved.trim().isNotEmpty) {
      return saved.trim();
    }
    return 'shyam';
  }

  Future<String> getCollectorId() async {
    final collector = await getCollector();
    final id = collector?['id']?.toString();
    if (id != null && id.trim().isNotEmpty && id.trim() != '0') {
      return id.trim();
    }
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('KEY_USER_ID');
    if (savedId != null && savedId.trim().isNotEmpty) {
      return savedId.trim();
    }
    return '68';
  }

  Future<void> clearCollector() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_collectorKey);
  }
}
