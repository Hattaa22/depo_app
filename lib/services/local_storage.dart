import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStorage {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  LocalStorage(this._prefs, this._secureStorage);

  // ======= Regular Storage =======
  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);

  String? getString(String key) => _prefs.getString(key);

  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);

  bool? getBool(String key) => _prefs.getBool(key);

  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);

  int? getInt(String key) => _prefs.getInt(key);

  Future<bool> remove(String key) => _prefs.remove(key);

  Future<bool> clear() => _prefs.clear();

  bool containsKey(String key) => _prefs.containsKey(key);

  // ======= Secure Storage =======
  Future<void> setSecure(String key, String value) =>
      _secureStorage.write(key: key, value: value);

  Future<String?> getSecure(String key) => _secureStorage.read(key: key);

  Future<void> removeSecure(String key) => _secureStorage.delete(key: key);

  Future<void> clearSecure() => _secureStorage.deleteAll();
}