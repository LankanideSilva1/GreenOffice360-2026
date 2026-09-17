import 'package:hive_flutter/hive_flutter.dart';

import '../../models/user_model.dart';
import '../../services/local_database_service.dart';

/// Hive-backed cache for user profiles.
///
/// Entries carry a `syncStatus` of `synced` or `pending`. Pending entries
/// were modified locally while offline and are never overwritten by
/// server data until they have been pushed to Firebase.
class OfflineUserRepository {
  static const String _boxName = LocalDatabaseService.usersBox;

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }

    return Hive.box(_boxName);
  }

  /// Cache a user profile fetched from the server.
  Future<void> cacheUser(UserModel user) async {
    if (user.uid.isEmpty) return;

    final box = await _getBox();
    final existing = box.get(user.uid) as Map?;
    if (existing?['syncStatus'] == 'pending') {
      return;
    }

    final data = user.toMap()
      ..['id'] = user.uid
      ..['syncStatus'] = 'synced';
    await box.put(user.uid, data);
  }

  /// Cache a raw user document (used when caching leaderboard data).
  Future<void> cacheUserData(String uid, Map<String, dynamic> data) async {
    if (uid.isEmpty) return;

    final box = await _getBox();
    final existing = box.get(uid) as Map?;
    if (existing?['syncStatus'] == 'pending') {
      return;
    }

    final userData = Map<String, dynamic>.from(data)
      ..['id'] = uid
      ..['syncStatus'] = 'synced';
    await box.put(uid, userData);
  }

  /// Update fields locally first and mark the entry as pending so the
  /// change is pushed to Firebase once a connection is available.
  Future<void> updateUserFields(
    String uid,
    Map<String, dynamic> fields,
  ) async {
    final box = await _getBox();
    final existing = box.get(uid) as Map?;
    final base = existing == null
        ? <String, dynamic>{'id': uid}
        : Map<String, dynamic>.from(existing);
    base.addAll(fields);
    base['syncStatus'] = 'pending';
    await box.put(uid, base);
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final box = await _getBox();
    final data = box.get(uid) as Map?;

    return data == null ? null : Map<String, dynamic>.from(data);
  }

  Future<UserModel?> getUser(String uid) async {
    final data = await getUserData(uid);

    return data == null ? null : UserModel.fromMap(uid, data);
  }

  Future<List<UserModel>> getAllUsers() async {
    final usersData = await getAllUsersData();

    return usersData
        .map((data) => UserModel.fromMap(data['id'] as String? ?? '', data))
        .where((user) => user.uid.isNotEmpty)
        .toList();
  }

  Future<List<Map<String, dynamic>>> getAllUsersData() async {
    final box = await _getBox();

    return box.values
        .whereType<Map>()
        .map((data) => Map<String, dynamic>.from(data))
        .toList();
  }

  Future<void> markAsSynced(String uid) async {
    final box = await _getBox();
    final data = box.get(uid) as Map?;
    if (data == null) return;

    final updated = Map<String, dynamic>.from(data)
      ..['syncStatus'] = 'synced';
    await box.put(uid, updated);
  }

  Future<void> clear() async {
    final box = await _getBox();
    await box.clear();
  }
}
