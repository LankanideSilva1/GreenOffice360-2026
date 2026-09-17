import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/user_model.dart';
import '../../models/sync_operation_model.dart';
import '../../services/connectivity_service.dart';
import 'offline/offline_user_repository.dart';
import 'offline/sync_queue_repository.dart';

class AuthRepository {
  // Resolved lazily so constructing the repository never requires
  // Firebase to be initialized (e.g. in unit tests).
  FirebaseAuth? _firebaseAuthInstance;
  FirebaseFirestore? _firestoreInstance;
  final ConnectivityService _connectivityService;
  final OfflineUserRepository _offlineUserRepository;
  final SyncQueueRepository _syncQueueRepository;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    ConnectivityService? connectivityService,
    OfflineUserRepository? offlineUserRepository,
    SyncQueueRepository? syncQueueRepository,
  })  : _firebaseAuthInstance = firebaseAuth,
        _firestoreInstance = firestore,
        _connectivityService =
            connectivityService ?? ConnectivityService(),
        _offlineUserRepository =
            offlineUserRepository ?? OfflineUserRepository(),
        _syncQueueRepository =
            syncQueueRepository ?? SyncQueueRepository();

  FirebaseAuth get _firebaseAuth =>
      _firebaseAuthInstance ??= FirebaseAuth.instance;

  FirebaseFirestore get _firestore =>
      _firestoreInstance ??= FirebaseFirestore.instance;

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

    await _offlineUserRepository.cacheUser(user);

    return user;
  }

  Future<UserModel> getUserProfile(String uid) async {
    if (await _connectivityService.hasInternetConnection()) {
      try {
        final document = await _firestore
            .collection('users')
            .doc(uid)
            .get();

        if (document.exists && document.data() != null) {
          final user = UserModel.fromMap(
            document.id,
            document.data()!,
          );
          await _offlineUserRepository.cacheUser(user);
          return user;
        }
      } catch (_) {
        // Fall through to the local cache.
      }
    }

    final cached = await _offlineUserRepository.getUser(uid);
    if (cached != null) {
      return cached;
    }

    throw Exception(
      'User profile was not found.',
    );
  }

  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    await _firebaseAuth.sendPasswordResetEmail(
      email: email,
    );
  }

  /// Write-through: the local cache is updated first, then the change is
  /// pushed to Firebase. When offline (or the push fails) the change is
  /// queued so only the pending update syncs once connectivity returns.
  Future<void> updateUserPoints(String uid, int newPoints) async {
    if (uid.isEmpty) return;

    await _offlineUserRepository.updateUserFields(uid, {
      'points': newPoints,
    });

    if (await _connectivityService.hasInternetConnection()) {
      try {
        await _firestore.collection('users').doc(uid).update({
          'points': newPoints,
        });
        await _offlineUserRepository.markAsSynced(uid);
        return;
      } catch (_) {
        // Fall through and queue the change for the next sync.
      }
    }

    final cached = await _offlineUserRepository.getUserData(uid);
    final profileData = <String, dynamic>{
      if (cached != null) ...cached,
      'userId': uid,
      'points': newPoints,
    }
      ..remove('id')
      ..remove('syncStatus');

    await _syncQueueRepository.addOperation(
      SyncOperationModel(
        id: 'profile_$uid',
        feature: 'profile',
        operation: 'update',
        data: profileData,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  User? get currentFirebaseUser =>
      _firebaseAuth.currentUser;
}