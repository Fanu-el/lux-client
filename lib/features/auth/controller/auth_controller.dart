// features/auth/controller/auth_controller.dart
//
// Pure data service — no BuildContext, no navigation.
// Every method throws on failure; callers handle UX.

import '../../../core/storage/token_storage.dart';
import '../data/auth_api.dart';

class AuthController {
  final AuthApi _api = AuthApi();

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final res = await _api.login({'email': email, 'password': password});
    await TokenStorage.saveTokens(
      res.data['access_token'] as String,
      res.data['refresh_token'] as String?,
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _api.register({'name': name, 'email': email, 'password': password});
  }

  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    await _api.verifyEmail({'email': email, 'code': code});
  }

  Future<void> resendCode(String email) async {
    await _api.resendCode(email);
  }

  Future<void> forgotPassword(String email) async {
    await _api.forgotPassword(email);
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _api.resetPassword({
      'email': email,
      'code': code,
      'new_password': newPassword,
    });
  }
}
