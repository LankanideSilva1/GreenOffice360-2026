import 'package:greenoffice360/repositories/auth_repository.dart';
import 'package:greenoffice360/services/cache_service.dart';

import '../../../models/user_model.dart';

class AuthController {
  final AuthRepository _repository;
  final CacheService _cacheService;

  AuthController({
    required AuthRepository repository,
    CacheService? cacheService,
  }) : _repository = repository,
       _cacheService = cacheService ?? CacheService();

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    return _repository.login(
      email: email,
      password: password,
    );
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    required String employeeId,
    required String department,
  }) async {
    return _repository.register(
      email: email,
      password: password,
      name: name,
      employeeId: employeeId,
      department: department,
    );
  }

  Future<void> resetPassword({
    required String email,
  }) async {
    await _repository.sendPasswordResetEmail(
      email: email,
    );
  }

  Future<void> logout() async {
    await _repository.logout();
  }

  Future<void> updateUserPoints(String uid, int newPoints) async {
    await _repository.updateUserPoints(uid, newPoints);
  }

  Future<UserModel> refreshCurrentUser() async {
    final uid = _repository.currentFirebaseUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception('No authenticated user found.');
    }
    return _repository.getUserProfile(uid);
  }

  Future<UserModel> getUserProfile(String uid) async {
    return _repository.getUserProfile(uid);
  }

  /// Pull all real data from Firestore into the Hive cache so the user
  /// can keep working offline. Never throws: the app continues with
  /// whatever is already cached.
  Future<void> hydrateCache({String? userId}) async {
    try {
      await _cacheService.hydrateAll(userId: userId);
    } catch (_) {
      // Offline: keep working from the existing cache.
    }
  }
}