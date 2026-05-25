import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveTokens(String access, String? refresh) async {
    await _storage.write(key: "access_token", value: access);
    await _storage.write(key: "refresh_token", value: refresh);
  }

  static Future<String?> getAccessToken() =>
      _storage.read(key: "access_token");

  static Future<String?> getRefreshToken() =>
      _storage.read(key: "refresh_token");

  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}