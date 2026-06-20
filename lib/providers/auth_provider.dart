import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _email;
  String? _role;
  bool _isLoading = true;

  bool get isAuthenticated => _isAuthenticated;
  String? get email => _email;
  String? get role => _role;
  bool get isLoading => _isLoading;

  AuthProvider() {
    checkAuth();
  }

  Future<void> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = prefs.getBool('is_authenticated') ?? false;
    if (_isAuthenticated) {
      _email = prefs.getString('auth_email');
      _role = prefs.getString('auth_role');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    String? role;
    if (cleanEmail == 'admin@ktlbd.com' && cleanPassword == '123456') {
      role = 'admin';
    } else if (cleanEmail == 'store@ktlbd.com' && cleanPassword == '123456') {
      role = 'store';
    }

    if (role != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_authenticated', true);
      await prefs.setString('auth_email', cleanEmail);
      await prefs.setString('auth_role', role);

      _isAuthenticated = true;
      _email = cleanEmail;
      _role = role;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_authenticated');
    await prefs.remove('auth_email');
    await prefs.remove('auth_role');

    _isAuthenticated = false;
    _email = null;
    _role = null;
    notifyListeners();
  }
}
