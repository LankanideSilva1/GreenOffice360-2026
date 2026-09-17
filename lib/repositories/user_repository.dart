import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../services/connectivity_service.dart';
import 'offline/offline_user_repository.dart';

class UserRepository {
  final FirebaseFirestore _firestore;
  final ConnectivityService _connectivityService;
  final OfflineUserRepository _offlineUserRepository;

  UserRepository({
    FirebaseFirestore? firestore,
    ConnectivityService? connectivityService,
    OfflineUserRepository? offlineUserRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _connectivityService =
            connectivityService ?? ConnectivityService(),
        _offlineUserRepository =
            offlineUserRepository ?? OfflineUserRepository();

  Future<void> createUserProfile(UserModel user) async {
    await _offlineUserRepository.cacheUser(user);
    await _firestore.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUserProfile(String uid) async {
    if (await _connectivityService.hasInternetConnection()) {
      try {
        final document = await _firestore
            .collection('users')
            .doc(uid)
            .get();

        if (document.exists && document.data() != null) {
          final user = UserModel.fromMap(document.id, document.data()!);
          await _offlineUserRepository.cacheUser(user);
          return user;
        }
      } catch (_) {
        // Fall through to the local cache.
      }
    }

    return _offlineUserRepository.getUser(uid);
  }

  Future<List<UserModel>> getUsersByRole(String role) async {
    if (await _connectivityService.hasInternetConnection()) {
      try {
        final snapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: role)
            .get();

        final users = snapshot.docs
            .map((doc) => UserModel.fromMap(doc.id, doc.data()))
            .toList();
        for (final user in users) {
          await _offlineUserRepository.cacheUser(user);
        }
        return users;
      } catch (_) {
        // Fall through to the local cache.
      }
    }

    final cachedUsers = await _offlineUserRepository.getAllUsers();
    return cachedUsers
        .where((user) => user.role.toLowerCase() == role.toLowerCase())
        .toList();
  }

  Future<List<UserModel>> getUsers() async {
    if (await _connectivityService.hasInternetConnection()) {
      try {
        final snapshot = await _firestore.collection('users').get();
        final users = snapshot.docs
            .map((doc) => UserModel.fromMap(doc.id, doc.data()))
            .toList();
        for (final user in users) {
          await _offlineUserRepository.cacheUser(user);
        }
        return users;
      } catch (_) {
        // Fall through to the local cache.
      }
    }

    return _offlineUserRepository.getAllUsers();
  }
}
