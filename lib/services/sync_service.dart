import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../repositories/offline/offline_challenge_repository.dart';
import '../repositories/offline/offline_issue_repository.dart';
import '../repositories/offline/offline_reward_repository.dart';
import '../repositories/offline/offline_user_repository.dart';
import '../repositories/offline/sync_queue_repository.dart';
import '../models/sync_operation_model.dart';
import 'cache_service.dart';
import 'cloudinary_service.dart';
import 'connectivity_service.dart';
import 'data_change_notifier.dart';

class SyncService {
  final ConnectivityService connectivityService;
  final SyncQueueRepository syncQueueRepository;
  final OfflineIssueRepository offlineIssueRepository;
  final CloudinaryService cloudinaryService;
  final OfflineUserRepository offlineUserRepository;
  final OfflineChallengeRepository offlineChallengeRepository;
  final OfflineRewardRepository offlineRewardRepository;
  final CacheService? cacheService;
  final DataChangeNotifier? dataChangeNotifier;

  bool _isSyncing = false;

  SyncService({
    required this.connectivityService,
    required this.syncQueueRepository,
    OfflineIssueRepository? offlineIssueRepository,
    CloudinaryService? cloudinaryService,
    OfflineUserRepository? offlineUserRepository,
    OfflineChallengeRepository? offlineChallengeRepository,
    OfflineRewardRepository? offlineRewardRepository,
    this.cacheService,
    this.dataChangeNotifier,
  }) : offlineIssueRepository =
           offlineIssueRepository ?? OfflineIssueRepository(),
       cloudinaryService = cloudinaryService ?? CloudinaryService(),
       offlineUserRepository =
           offlineUserRepository ?? OfflineUserRepository(),
       offlineChallengeRepository =
           offlineChallengeRepository ?? OfflineChallengeRepository(),
       offlineRewardRepository =
           offlineRewardRepository ?? OfflineRewardRepository();

  Future<void> synchronize() async {
    if (_isSyncing) return;

    final isConnected = await connectivityService.hasInternetConnection();

    if (!isConnected) return;

    _isSyncing = true;

    try {
      final operations = await syncQueueRepository.getOperations();

      for (final operation in operations) {
        try {
          await _processOperation(operation);

          await syncQueueRepository.removeOperation(operation.id);
        } catch (error) {
          // Keep the operation in the queue.
          // It will retry later.
          // ignore: avoid_print
          print('Sync failed for ${operation.feature}/${operation.id}: $error');
        }
      }

      // Refresh the local cache with the latest server data.
      await cacheService?.hydrateAll();

      // Tell open screens to reload so synced changes become visible.
      dataChangeNotifier?.notifyDataChanged();
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processOperation(SyncOperationModel operation) async {
    switch (operation.feature) {
      case 'issue':
        await _syncIssue(operation);
        break;

      case 'profile':
        await _syncProfile(operation);
        break;

      case 'challenge':
        await _syncChallenge(operation);
        break;

      case 'redemption':
        await _syncRedemption(operation);
        break;

      default:
        throw FormatException('Unsupported sync feature: ${operation.feature}');
    }
  }

  Future<void> _syncIssue(SyncOperationModel operation) async {
    final userId = operation.data['userId'] as String?;
    final issueId = operation.data['id'] as String?;
    final issueData = Map<String, dynamic>.from(operation.data)..remove('id');
    final localImagePath = issueData.remove('localImagePath') as String?;

    if (localImagePath != null && localImagePath.isNotEmpty) {
      if (userId == null || userId.isEmpty) {
        throw const FormatException('Issue sync data is missing userId.');
      }

      final image = File(localImagePath);
      if (await image.exists()) {
        final documentId =
            issueId ?? FirebaseFirestore.instance.collection('issues').doc().id;
        issueData['imageUrl'] = await cloudinaryService.uploadIssueImage(
          image: image,
          issueId: documentId,
          userId: userId,
        );
      }
    }

    if (operation.operation == 'update') {
      if (issueId == null || issueId.isEmpty) {
        throw const FormatException('Issue update is missing id.');
      }

      await FirebaseFirestore.instance
          .collection('issues')
          .doc(issueId)
          .set(issueData, SetOptions(merge: true));
      await offlineIssueRepository.markAsSynced(issueId);
      await _removeSyncedOfflineIssue(issueId);
      return;
    }

    if (userId == null || userId.isEmpty) {
      throw const FormatException('Issue sync data is missing userId.');
    }

    final document = issueId == null || issueId.isEmpty
        ? FirebaseFirestore.instance.collection('issues').doc()
        : FirebaseFirestore.instance.collection('issues').doc(issueId);
    await document.set(issueData, SetOptions(merge: true));

    if (issueId != null && issueId.isNotEmpty) {
      await offlineIssueRepository.markAsSynced(issueId);
    }
    await _removeSyncedOfflineIssue(issueId);
  }

  Future<void> _removeSyncedOfflineIssue(String? issueId) async {
    if (issueId == null || !issueId.startsWith('offline_')) return;

    await offlineIssueRepository.markAsSynced(issueId);
    await offlineIssueRepository.deleteIssue(issueId);
  }

  Future<void> _syncProfile(SyncOperationModel operation) async {
    final userId = operation.data['userId'] as String?;
    if (userId == null || userId.isEmpty) {
      throw const FormatException('Profile sync data is missing userId.');
    }

    final profileData = Map<String, dynamic>.from(operation.data)
      ..remove('userId')
      ..remove('id')
      ..remove('syncStatus');

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .set(profileData, SetOptions(merge: true));
    await offlineUserRepository.markAsSynced(userId);
  }

  Future<void> _syncChallenge(SyncOperationModel operation) async {
    switch (operation.operation) {
      case 'join':
        await _syncChallengeJoin(operation);
        break;
      case 'leave':
        await _syncChallengeLeave(operation);
        break;
      case 'progress':
        await _syncChallengeProgress(operation);
        break;
      default:
        throw FormatException(
          'Unsupported challenge operation: ${operation.operation}',
        );
    }
  }

  Future<void> _syncChallengeJoin(SyncOperationModel operation) async {
    final participationId = operation.data['participationId'] as String?;
    final userId = operation.data['userId'] as String?;
    final challengeId = operation.data['challengeId'] as String?;
    if (participationId == null ||
        participationId.isEmpty ||
        userId == null ||
        userId.isEmpty ||
        challengeId == null ||
        challengeId.isEmpty) {
      throw const FormatException('Challenge join data is incomplete.');
    }

    final data = Map<String, dynamic>.from(operation.data)
      ..remove('id')
      ..remove('syncStatus');

    await FirebaseFirestore.instance
        .collection('challengeParticipation')
        .doc(participationId)
        .set(data, SetOptions(merge: true));
    await offlineChallengeRepository.markParticipationSynced(participationId);
  }

  Future<void> _syncChallengeLeave(SyncOperationModel operation) async {
    final userId = operation.data['userId'] as String?;
    final challengeId = operation.data['challengeId'] as String?;
    if (userId == null || userId.isEmpty || challengeId == null || challengeId.isEmpty) {
      throw const FormatException('Challenge leave data is incomplete.');
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('challengeParticipation')
        .where('userId', isEqualTo: userId)
        .get();
    for (final document in snapshot.docs) {
      if (document.data()['challengeId'] == challengeId) {
        await document.reference.delete();
      }
    }
  }

  Future<void> _syncChallengeProgress(SyncOperationModel operation) async {
    final participationId = operation.data['participationId'] as String?;
    final userId = operation.data['userId'] as String?;
    final challengeId = operation.data['challengeId'] as String?;
    if (participationId == null ||
        participationId.isEmpty ||
        userId == null ||
        userId.isEmpty ||
        challengeId == null ||
        challengeId.isEmpty) {
      throw const FormatException('Challenge progress data is incomplete.');
    }

    final firestore = FirebaseFirestore.instance;
    final participationReference = firestore
        .collection('challengeParticipation')
        .doc(participationId);
    final completed = operation.data['status'] == 'completed';

    await firestore.runTransaction((transaction) async {
      final current = await transaction.get(participationReference);
      final userReference = firestore.collection('users').doc(userId);
      final userSnapshot = await transaction.get(userReference);
      final currentData = current.data() ?? const <String, dynamic>{};
      final userData = userSnapshot.data() ?? const <String, dynamic>{};
      final alreadyAwarded = currentData['greenScoreAwarded'] == true;

      transaction.set(
        participationReference,
        {
          'participationId': participationId,
          'challengeId': challengeId,
          'userId': userId,
          if (!current.exists) 'joinedAt': FieldValue.serverTimestamp(),
          'completedSubsteps':
              operation.data['completedSubsteps'] ?? const <String>[],
          'pointsEarned': operation.data['pointsEarned'] ?? 0,
          'status': completed ? 'completed' : 'joined',
          'completedAt': completed ? FieldValue.serverTimestamp() : null,
          if (completed && !alreadyAwarded) 'greenScoreAwarded': true,
        },
        SetOptions(merge: true),
      );

      if (completed && !alreadyAwarded) {
        transaction.update(userReference, {
          'greenScore': _toInt(userData['greenScore']) + 25,
          'points': _toInt(userData['points']) + 25,
        });
      }
    });

    await offlineChallengeRepository.markParticipationSynced(participationId);
  }

  Future<void> _syncRedemption(SyncOperationModel operation) async {
    final redemptionId = operation.data['id'] as String?;
    if (redemptionId == null || redemptionId.isEmpty) {
      throw const FormatException('Redemption sync data is missing id.');
    }

    final rewardId = operation.data['rewardId'] as String? ?? '';
    final data = Map<String, dynamic>.from(operation.data)
      ..remove('id')
      ..remove('syncStatus');

    final firestore = FirebaseFirestore.instance;
    await firestore
        .collection('reward_redemptions')
        .doc(redemptionId)
        .set(data);

    // Best-effort stock decrement, mirroring the online path.
    if (rewardId.isNotEmpty) {
      try {
        final docRef = firestore.collection('rewards').doc(rewardId);
        final docSnapshot = await docRef.get();
        if (docSnapshot.exists && docSnapshot.data()?['stock'] != null) {
          final currentStock = (docSnapshot.data()?['stock'] as num).toInt();
          if (currentStock > 0) {
            await docRef.update({'stock': FieldValue.increment(-1)});
          }
        }
      } catch (_) {
        // Stock synchronization is best-effort.
      }
    }

    await offlineRewardRepository.markRedemptionSynced(redemptionId);
  }

  int _toInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _syncSettings(SyncOperationModel operation) async {
    // Firebase settings synchronization
  }

  void startAutoSync() {
    connectivityService.onConnectivityChanged.listen((isConnected) {
      if (isConnected) {
        synchronize();
      }
    });
    synchronize();
  }
}
