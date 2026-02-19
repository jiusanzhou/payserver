import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static AppPreferences? _instance;
  static SharedPreferences? _prefs;

  AppPreferences._();

  static AppPreferences get instance {
    _instance ??= AppPreferences._();
    return _instance!;
  }

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw StateError('AppPreferences not initialized. Call init() first.');
    }
    return _prefs!;
  }

  int? getInt(String key) => _prefs?.getInt(key);
  String? getString(String key) => _prefs?.getString(key);
  bool? getBool(String key) => _prefs?.getBool(key);
  double? getDouble(String key) => _prefs?.getDouble(key);
  List<String>? getStringList(String key) => _prefs?.getStringList(key);

  Future<bool> putInt(String key, int value) => prefs.setInt(key, value);
  Future<bool> putString(String key, String value) =>
      prefs.setString(key, value);
  Future<bool> putBool(String key, bool value) => prefs.setBool(key, value);
  Future<bool> putDouble(String key, double value) =>
      prefs.setDouble(key, value);
  Future<bool> putStringList(String key, List<String> value) =>
      prefs.setStringList(key, value);

  Future<bool> remove(String key) => prefs.remove(key);
  Future<bool> clear() => prefs.clear();
}
