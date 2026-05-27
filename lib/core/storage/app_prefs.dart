import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Lightweight local preferences — stores non-secret app state flags.
class AppPrefs {
  static const _storage = FlutterSecureStorage();
  static const _introSeenKey = 'intro_seen';

  static Future<bool> hasSeenIntro() async {
    return await _storage.read(key: _introSeenKey) == 'true';
  }

  static Future<void> markIntroSeen() async {
    await _storage.write(key: _introSeenKey, value: 'true');
  }
}
