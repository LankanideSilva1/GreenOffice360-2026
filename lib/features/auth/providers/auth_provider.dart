import 'package:flutter/foundation.dart';

import '../../../models/user_model.dart';
import '../controllers/auth_controller.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthController _controller;

  AuthProvider({
    required AuthController controller,
  }) : _controller = controller;

  AuthStatus _status = AuthStatus.initial;

  UserModel? _user;

  String? _errorMessage;

  AuthStatus get status => _status;

  UserModel? get user => _user;

  String? get errorMessage => _errorMessage;

  bool get isLoading =>
      _status == AuthStatus.loading;

  bool get isAuthenticated =>
      _status == AuthStatus.authenticated;

  String? get role => _user?.role;

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading();

    try {
      final user = await _controller.login(
        email: email,
        password: password,
      );

      _user = user;
      _status = AuthStatus.authenticated;
      _errorMessage = null;

      notifyListeners();

      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _getErrorMessage(e);

      notifyListeners();

      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String employeeId,
    required String department,
  }) async {
    _setLoading();

    try {
      final user = await _controller.register(
        email: email,
        password: password,
        name: name,
        employeeId: employeeId,
        department: department,
      );

      _user = user;
      _status = AuthStatus.authenticated;
      _errorMessage = null;

      notifyListeners();

      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _getErrorMessage(e);

      notifyListeners();

      return false;
    }
  }

  Future<void> resetPassword({
    required String email,
  }) async {
    await _controller.resetPassword(
      email: email,
    );
  }

  Future<void> logout() async {
    await _controller.logout();

    _user = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;

    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;

    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;

    notifyListeners();
  }

  String _getErrorMessage(Object error) {
    final message = error.toString();

    if (message.contains('invalid-credential')) {
      return 'Invalid email or password.';
    }

    if (message.contains('user-not-found')) {
      return 'No account found with this email.';
    }

    if (message.contains('wrong-password')) {
      return 'Incorrect password.';
    }

    if (message.contains('email-already-in-use')) {
      return 'An account already exists with this email.';
    }

    if (message.contains('weak-password')) {
      return 'Password is too weak.';
    }

    if (message.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }

    return 'Something went wrong. Please try again.';
  }
}