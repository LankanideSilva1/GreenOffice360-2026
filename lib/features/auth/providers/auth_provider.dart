import 'package:flutter/foundation.dart';

import '../../../models/user_model.dart';
import '../../../services/data_change_notifier.dart';
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
  DataChangeNotifier? _dataChangeSubscription;

  AuthProvider({
    required AuthController controller,
    DataChangeNotifier? dataChangeNotifier,
  }) : _controller = controller {
    _dataChangeSubscription = dataChangeNotifier;
    dataChangeNotifier?.addListener(refreshPointsFromCache);
  }

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

      // Load a full local cache of real data for offline use.
      await _controller.hydrateCache(userId: user.uid);

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

      // Load a full local cache of real data for offline use.
      await _controller.hydrateCache(userId: user.uid);

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

  Future<void> refreshCurrentUser() async {
    try {
      final refreshedUser = await _controller.refreshCurrentUser();
      _user = refreshedUser;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
    } catch (_) {
      // Keep the current user (e.g. when the refresh runs while offline).
    }
  }

  /// Refresh only points/score from the local cache after a sync, without
  /// touching auth status or showing errors.
  Future<void> refreshPointsFromCache() async {
    if (_user == null) return;

    try {
      final refreshedUser = await _controller.refreshCurrentUser();
      _user = refreshedUser;
      notifyListeners();
    } catch (_) {
      // Keep the current user.
    }
  }

  @override
  void dispose() {
    _dataChangeSubscription?.removeListener(refreshPointsFromCache);
    _dataChangeSubscription = null;
    super.dispose();
  }

  Future<bool> deductPoints(int pointsToDeduct) async {
    if (_user == null) return false;

    final newPoints = (_user!.points - pointsToDeduct).clamp(0, 999999);
    _user = _user!.copyWith(points: newPoints);
    notifyListeners();

    try {
      if (_user!.uid.isNotEmpty) {
        await _controller.updateUserPoints(_user!.uid, newPoints);
      }
    } catch (_) {
      // Ignored if local or offline demo
    }
    return true;
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