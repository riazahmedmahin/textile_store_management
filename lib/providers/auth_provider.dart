import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  bool _isAuthenticated = false;
  String? _email;
  String? _role;
  bool _isLoading = true;
  String? _errorMessage;

  bool get isAuthenticated => _isAuthenticated;
  String? get email => _email;
  String? get role => _role;
  bool get canEdit => _role == 'store';
  bool get isReadOnly => _role != 'store';
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    checkAuth();
  }

  Future<void> checkAuth() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session != null && session.user != null) {
        _isAuthenticated = true;
        _email = session.user!.email;
        _role = session.user!.userMetadata?['role'] as String?;
        _role ??= (_email?.toLowerCase().contains('admin') ?? false)
            ? 'admin'
            : 'store';
      } else {
        _isAuthenticated = false;
        _email = null;
        _role = null;
      }
    } catch (e) {
      _isAuthenticated = false;
      _email = null;
      _role = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _errorMessage = null;
    notifyListeners();

    var cleanEmail = email.trim().toLowerCase();
    if (!cleanEmail.contains('@')) {
      cleanEmail = '$cleanEmail@ktlbd.com';
    }
    final cleanPassword = password.trim();

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      if (response.session != null && response.user != null) {
        _isAuthenticated = true;
        _email = response.user!.email;
        _role = cleanEmail.contains('store') ? 'store' : 'admin';
        notifyListeners();
        return true;
      }
    } on AuthException catch (authErr) {
      // If user not found, try to auto sign up for the default accounts
      if ((authErr.message
                  .toLowerCase()
                  .contains('invalid login credentials') ||
              authErr.message.toLowerCase().contains('user not found')) &&
          ((cleanEmail == 'admin@ktlbd.com' ||
                  cleanEmail == 'store@ktlbd.com') &&
              cleanPassword == '123456')) {
        try {
          final signUpRole = cleanEmail.contains('store') ? 'store' : 'admin';
          final signUpResponse = await _supabase.auth.signUp(
            email: cleanEmail,
            password: cleanPassword,
            data: {'role': signUpRole},
          );
          if (signUpResponse.user != null) {
            if (signUpResponse.session != null) {
              _isAuthenticated = true;
              _email = signUpResponse.user!.email;
              _role = signUpRole;
              notifyListeners();
              return true;
            } else {
              _errorMessage =
                  "Sign-up successful! Please check your email to confirm your account, or disable 'Confirm email' in Supabase Auth settings.";
              notifyListeners();
              return false;
            }
          }
        } on AuthException catch (signUpErr) {
          _errorMessage = signUpErr.message;
          notifyListeners();
          return false;
        } catch (signUpErr) {
          _errorMessage = signUpErr.toString();
          notifyListeners();
          return false;
        }
      } else {
        _errorMessage = authErr.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
    return false;
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint("Sign out failed: $e");
    }
    _isAuthenticated = false;
    _email = null;
    _role = null;
    notifyListeners();
  }
}
