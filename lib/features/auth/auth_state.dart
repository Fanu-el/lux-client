// core/auth/auth_state.dart
import 'package:flutter/material.dart';
import '../../core/storage/token_storage.dart';

class AuthState extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isInitialized = false;

  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    final token = await TokenStorage.getAccessToken();

    _isLoggedIn = token != null;
    _isInitialized = true;

    notifyListeners();
  }

  void login() {
    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await TokenStorage.clear();
    _isLoggedIn = false;
    notifyListeners();
  }
}