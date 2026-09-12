import 'package:greenoffice360/repositories/auth_repository.dart';

import '../../../models/user_model.dart';

class AuthController {
  final AuthRepository _repository;

  AuthController({
    required AuthRepository repository,
  }) : _repository = repository;

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
}