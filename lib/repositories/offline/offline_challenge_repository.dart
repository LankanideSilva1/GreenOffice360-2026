import 'package:hive_flutter/hive_flutter.dart';

import '../../services/local_database_service.dart';

/// Hive-backed cache for challenges and challenge participation.
///
/// Participation entries carry a `syncStatus` of `synced` or `pending`.
/// Pending entries represent joins, leaves or progress updates made while
/// offline and are pushed to Firebase by the sync service.
class OfflineChallengeRepository {
  static const String _challengesBoxName = LocalDatabaseService.challengesBox;
  static const String _participationBoxName =
      LocalDatabaseService.challengeParticipationBox;

  Future<Box> _getChallengesBox() async {
    if (!Hive.isBoxOpen(_challengesBoxName)) {
      await Hive.openBox(_challengesBoxName);
    }

    return Hive.box(_challengesBoxName);
  }

  Future<Box> _getParticipationBox() async {
    if (!Hive.isBoxOpen(_participationBoxName)) {
      await Hive.openBox(_participationBoxName);
    }

    return Hive.box(_participationBoxName);
  }

  // -------------------------------------------------------------------
  // Challenges
  // -------------------------------------------------------------------

  /// Cache a challenge document fetched from the server.
  Future<void> cacheChallenge(String id, Map<String, dynamic> data) async {
    if (id.isEmpty) return;

    final box = await _getChallengesBox();
    final challengeData = Map<String, dynamic>.from(data)
      ..['id'] = id
      ..['syncStatus'] = 'synced';
    await box.put(id, challengeData);
  }

  Future<List<Map<String, dynamic>>> getAllChallenges() async {
    final box = await _getChallengesBox();

    return box.values
        .whereType<Map>()
        .map((data) => Map<String, dynamic>.from(data))
        .toList();
  }

  // -------------------------------------------------------------------
  // Participation
  // -------------------------------------------------------------------

  /// Cache a participation document fetched from the server. Pending
  /// (locally modified) entries are not overwritten.
  Future<void> cacheParticipation(String id, Map<String, dynamic> data) async {
    if (id.isEmpty) return;

    final box = await _getParticipationBox();
    final existing = box.get(id) as Map?;
    if (existing?['syncStatus'] == 'pending') {
      return;
    }

    final participationData = Map<String, dynamic>.from(data)
      ..['id'] = id
      ..['syncStatus'] = 'synced';
    await box.put(id, participationData);
  }

  /// Save a participation created locally (offline join).
  Future<void> saveParticipation(
    String id,
    Map<String, dynamic> data,
  ) async {
    final box = await _getParticipationBox();
    final participationData = Map<String, dynamic>.from(data)
      ..['id'] = id
      ..['syncStatus'] = 'pending';
    await box.put(id, participationData);
  }

  /// Update fields locally first and mark the entry as pending sync.
  Future<void> updateParticipationFields(
    String id,
    Map<String, dynamic> fields,
  ) async {
    final box = await _getParticipationBox();
    final existing = box.get(id) as Map?;
    if (existing == null) return;

    final updated = Map<String, dynamic>.from(existing)
      ..addAll(fields)
      ..['syncStatus'] = 'pending';
    await box.put(id, updated);
  }

  Future<void> deleteParticipation(String id) async {
    final box = await _getParticipationBox();
    await box.delete(id);
  }

  Future<Map<String, dynamic>?> getParticipation(String id) async {
    final box = await _getParticipationBox();
    final data = box.get(id) as Map?;

    return data == null ? null : Map<String, dynamic>.from(data);
  }

  Future<List<Map<String, dynamic>>> getAllParticipations() async {
    final box = await _getParticipationBox();

    return box.values
        .whereType<Map>()
        .map((data) => Map<String, dynamic>.from(data))
        .toList();
  }

  Future<void> markParticipationSynced(String id) async {
    final box = await _getParticipationBox();
    final data = box.get(id) as Map?;
    if (data == null) return;

    final updated = Map<String, dynamic>.from(data)
      ..['syncStatus'] = 'synced';
    await box.put(id, updated);
  }
}
