import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth =
            firebaseAuth ?? FirebaseAuth.instance,
        _firestore =
            firestore ?? FirebaseFirestore.instance;

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final credential =
        await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw Exception('Unable to authenticate user.');
    }

    return getUserProfile(firebaseUser.uid);
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    required String employeeId,
    required String department,
  }) async {
    final credential =
        await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw Exception('Unable to create user.');
    }

    final user = UserModel(
      uid: firebaseUser.uid,
      email: email,
      name: name,
      employeeId: employeeId,
      department: department,
      role: 'employee',
    );

    await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .set(user.toMap());

    return user;
  }

  Future<UserModel> getUserProfile(String uid) async {
    final document = await _firestore
        .collection('users')
        .doc(uid)
        .get();

    if (!document.exists || document.data() == null) {
      throw Exception(
        'User profile was not found.',
      );
    }

    return UserModel.fromMap(
      document.id,
      document.data()!,
    );
  }

  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    await _firebaseAuth.sendPasswordResetEmail(
      email: email,
    );
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  User? get currentFirebaseUser =>
      _firebaseAuth.currentUser;
}