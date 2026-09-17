import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/challenge_model.dart';
import '../models/sync_operation_model.dart';
import '../services/connectivity_service.dart';
import '../services/hive_cache_sanitizer.dart';
import 'offline/offline_challenge_repository.dart';
import 'offline/sync_queue_repository.dart';

abstract class ChallengeRepository {
  Future<List<ChallengeModel>> getChallenges();

  Future<String> createParticipation({required String challengeId});

  Future<void> deleteParticipation({required String challengeId});

  Future<void> updateCompletedSubsteps({
    required String challengeId,
    required List<String> completedSubstepIds,
    required int pointsEarned,
    required int totalSubsteps,
  });
}

class FirestoreChallengeRepository implements ChallengeRepository {
  FirestoreChallengeRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    ConnectivityService? connectivityService,
    OfflineChallengeRepository? offlineChallengeRepository,
    SyncQueueRepository? syncQueueRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _connectivityService = connectivityService ?? ConnectivityService(),
       _offlineChallengeRepository =
           offlineChallengeRepository ?? OfflineChallengeRepository(),
       _syncQueueRepository = syncQueueRepository ?? SyncQueueRepository();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final ConnectivityService _connectivityService;
  final OfflineChallengeRepository _offlineChallengeRepository;
  final SyncQueueRepository _syncQueueRepository;

  @override
  Future<List<ChallengeModel>> getChallenges() async {
    final userId = _firebaseAuth.currentUser?.uid;

    List<Map<String, dynamic>> challengesData;
    List<Map<String, dynamic>> participationsData;

    if (await _connectivityService.hasInternetConnection()) {
      try {
        final participationSnapshot = await _firestore
            .collection('challengeParticipation')
            .get();
        final challengesSnapshot = await _firestore
            .collection('challenges')
            .where('isActive', isEqualTo: true)
            .get();

        participationsData = participationSnapshot.docs
            .map((doc) => sanitizeMapForHive(doc.data())..['id'] = doc.id)
            .toList();
        challengesData = challengesSnapshot.docs
            .map((doc) => sanitizeMapForHive(doc.data())..['id'] = doc.id)
            .toList();

        // Refresh the local cache with the latest server data.
        for (final doc in participationSnapshot.docs) {
          await _offlineChallengeRepository.cacheParticipation(
            doc.id,
            sanitizeMapForHive(doc.data()),
          );
        }
        for (final doc in challengesSnapshot.docs) {
          await _offlineChallengeRepository.cacheChallenge(
            doc.id,
            sanitizeMapForHive(doc.data()),
          );
        }
      } catch (_) {
        // Fall back to the local cache.
        challengesData = await _offlineChallengeRepository.getAllChallenges();
        participationsData =
            await _offlineChallengeRepository.getAllParticipations();
      }
    } else {
      challengesData = await _offlineChallengeRepository.getAllChallenges();
      participationsData =
          await _offlineChallengeRepository.getAllParticipations();
    }

    return _buildChallenges(
      challengesData: challengesData,
      participationsData: participationsData,
      userId: userId,
    );
  }

  List<ChallengeModel> _buildChallenges({
    required List<Map<String, dynamic>> challengesData,
    required List<Map<String, dynamic>> participationsData,
    String? userId,
  }) {
    final participantCounts = <String, int>{};
    final userParticipations = <String, Map<String, dynamic>>{};

    for (final data in participationsData) {
      final challengeId = data['challengeId'] as String?;
      if (challengeId == null || challengeId.isEmpty) continue;
      participantCounts[challengeId] =
          (participantCounts[challengeId] ?? 0) + 1;
      if (userId != null && data['userId'] == userId) {
        userParticipations[challengeId] = data;
      }
    }

    return challengesData
        .where((data) => data['isActive'] != false)
        .map((data) {
          final id = data['id'] as String? ?? '';
          final participation = userParticipations[id];
          final substeps = data['substeps'];
          final substepCount = substeps is List ? substeps.length : 0;
          final completedCount = _completedSubstepCount(participation);
          final progress = substepCount == 0
              ? 0.0
              : completedCount / substepCount;
          return ChallengeModel.fromMap(
            data,
            id,
            joinedByUser: participation != null,
            participantCount: participantCounts[id] ?? 0,
            progress: progress,
            completedSubstepIds: _completedSubstepIds(participation),
          );
        })
        .where((challenge) => challenge.id.isNotEmpty)
        .toList();
  }

  @override
  Future<void> deleteParticipation({required String challengeId}) async {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) {
      throw StateError('You must be signed in to leave a challenge.');
    }

    final participationId = await _findParticipationId(userId, challengeId);

    // Remove from the local cache first so the UI reflects the leave.
    if (participationId != null) {
      await _offlineChallengeRepository.deleteParticipation(participationId);
    }

    if (await _connectivityService.hasInternetConnection()) {
      try {
        final participation = await _firestore
            .collection('challengeParticipation')
            .where('userId', isEqualTo: userId)
            .get();
        for (final document in participation.docs) {
          if (document.data()['challengeId'] == challengeId) {
            await document.reference.delete();
          }
        }
        return;
      } catch (_) {
        // Fall through and queue the leave for the next sync.
      }
    }

    await _syncQueueRepository.addOperation(
      SyncOperationModel(
        id: 'leave_${userId}_$challengeId',
        feature: 'challenge',
        operation: 'leave',
        data: {'challengeId': challengeId, 'userId': userId},
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<String> createParticipation({required String challengeId}) async {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) {
      throw StateError('You must be signed in to join a challenge.');
    }

    // Already joined (locally or on the server)?
    final existingId = await _findParticipationId(userId, challengeId);
    if (existingId != null) {
      return existingId;
    }

    final hasInternet = await _connectivityService.hasInternetConnection();
    final participationId = hasInternet
        ? _firestore.collection('challengeParticipation').doc().id
        : 'offline_${DateTime.now().millisecondsSinceEpoch}';

    final participationData = <String, dynamic>{
      'participationId': participationId,
      'challengeId': challengeId,
      'userId': userId,
      'joinedAt': DateTime.now(),
      'completedAt': null,
      'status': 'joined',
      'pointsEarned': 0,
      'completedSubsteps': <String>[],
    };

    // Write-through: save to the local cache first.
    await _offlineChallengeRepository.saveParticipation(
      participationId,
      participationData,
    );

    if (hasInternet) {
      try {
        await _firestore
            .collection('challengeParticipation')
            .doc(participationId)
            .set({
              ...participationData,
              'joinedAt': FieldValue.serverTimestamp(),
            });
        await _offlineChallengeRepository.markParticipationSynced(
          participationId,
        );
        return participationId;
      } catch (_) {
        // Fall through and queue the join for the next sync.
      }
    }

    await _syncQueueRepository.addOperation(
      SyncOperationModel(
        id: 'join_$participationId',
        feature: 'challenge',
        operation: 'join',
        data: participationData,
        createdAt: DateTime.now(),
      ),
    );

    return participationId;
  }

  @override
  Future<void> updateCompletedSubsteps({
    required String challengeId,
    required List<String> completedSubstepIds,
    required int pointsEarned,
    required int totalSubsteps,
  }) async {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) {
      throw StateError('You must be signed in to update a challenge.');
    }

    final participationId = await _findParticipationId(userId, challengeId);
    if (participationId == null) {
      throw StateError('Challenge participation was not found.');
    }

    final completed =
        totalSubsteps > 0 && completedSubstepIds.length == totalSubsteps;
    final progressData = <String, dynamic>{
      'completedSubsteps': completedSubstepIds,
      'pointsEarned': pointsEarned,
      'status': completed ? 'completed' : 'joined',
      'completedAt': completed ? DateTime.now() : null,
    };

    // Write-through: update the local cache first.
    await _offlineChallengeRepository.updateParticipationFields(
      participationId,
      progressData,
    );

    if (await _connectivityService.hasInternetConnection()) {
      try {
        final participationReference = _firestore
            .collection('challengeParticipation')
            .doc(participationId);
        await _firestore.runTransaction((transaction) async {
          final current = await transaction.get(participationReference);
          final userReference = _firestore.collection('users').doc(userId);
          final userSnapshot = await transaction.get(userReference);
          final data = current.data() ?? const <String, dynamic>{};
          final userData = userSnapshot.data() ?? const <String, dynamic>{};
          final completionAwarded = data['greenScoreAwarded'] == true;

          transaction.set(
            participationReference,
            {
              'participationId': participationId,
              'challengeId': challengeId,
              'userId': userId,
              'completedSubsteps': completedSubstepIds,
              'pointsEarned': pointsEarned,
              'status': completed ? 'completed' : 'joined',
              'completedAt': completed ? FieldValue.serverTimestamp() : null,
              if (completed && !completionAwarded) 'greenScoreAwarded': true,
            },
            SetOptions(merge: true),
          );

          if (completed && !completionAwarded) {
            transaction.update(userReference, {
              'greenScore': _toInt(userData['greenScore']) + 25,
              'points': _toInt(userData['points']) + 25,
            });
          }
        });
        await _offlineChallengeRepository.markParticipationSynced(
          participationId,
        );
        return;
      } catch (_) {
        // Fall through and queue the progress for the next sync.
      }
    }

    await _syncQueueRepository.addOperation(
      SyncOperationModel(
        id: 'progress_$participationId',
        feature: 'challenge',
        operation: 'progress',
        data: {
          'participationId': participationId,
          'challengeId': challengeId,
          'userId': userId,
          ...progressData,
        },
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Find a participation id in the local cache first, then on the server.
  Future<String?> _findParticipationId(
    String userId,
    String challengeId,
  ) async {
    final cached = await _offlineChallengeRepository.getAllParticipations();
    for (final data in cached) {
      if (data['userId'] == userId && data['challengeId'] == challengeId) {
        return data['id'] as String?;
      }
    }

    if (await _connectivityService.hasInternetConnection()) {
      try {
        final snapshot = await _firestore
            .collection('challengeParticipation')
            .where('userId', isEqualTo: userId)
            .get();
        for (final document in snapshot.docs) {
          if (document.data()['challengeId'] == challengeId) {
            await _offlineChallengeRepository.cacheParticipation(
              document.id,
              sanitizeMapForHive(document.data()),
            );
            return document.id;
          }
        }
      } catch (_) {
        // No server participation available.
      }
    }

    return null;
  }

  int _completedSubstepCount(Map<String, dynamic>? participation) {
    final completed = participation?['completedSubsteps'];
    return completed is List ? completed.length : 0;
  }

  List<String> _completedSubstepIds(Map<String, dynamic>? participation) {
    final completed = participation?['completedSubsteps'];
    return completed is List ? completed.whereType<String>().toList() : [];
  }

  int _toInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
