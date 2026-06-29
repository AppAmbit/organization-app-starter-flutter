import 'package:shared_preferences/shared_preferences.dart';

/// Isolated wrapper for shared_preferences.
/// If the package changes API, only this file changes.
class LocalStorageService {
  static Future<SharedPreferences> _instance() =>
      SharedPreferences.getInstance();

  static Future<void> reload() async => (await _instance()).reload();

  static Future<String?> getString(String key) async =>
      (await _instance()).getString(key);

  static Future<bool> setString(String key, String value) async =>
      (await _instance()).setString(key, value);

  static Future<List<String>?> getStringList(String key) async =>
      (await _instance()).getStringList(key);

  static Future<bool> setStringList(String key, List<String> values) async =>
      (await _instance()).setStringList(key, values);
}
