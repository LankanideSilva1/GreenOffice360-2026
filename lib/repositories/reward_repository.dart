import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/reward_model.dart';
import '../models/reward_redemption_model.dart';
import '../models/sync_operation_model.dart';
import '../services/connectivity_service.dart';
import '../services/hive_cache_sanitizer.dart';
import 'offline/offline_reward_repository.dart';
import 'offline/sync_queue_repository.dart';

abstract class RewardRepository {
  Future<List<RewardModel>> getRewards();
  Future<List<RewardRedemptionModel>> getUserRedemptions(String userId);
  Future<void> createRedemption({
    required String userId,
    required String rewardId,
    required String rewardName,
    required int pointsUsed,
  });
}

class FirestoreRewardRepository implements RewardRepository {
  FirestoreRewardRepository({
    FirebaseFirestore? firestore,
    ConnectivityService? connectivityService,
    OfflineRewardRepository? offlineRewardRepository,
    SyncQueueRepository? syncQueueRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _connectivityService = connectivityService ?? ConnectivityService(),
       _offlineRewardRepository =
           offlineRewardRepository ?? OfflineRewardRepository(),
       _syncQueueRepository = syncQueueRepository ?? SyncQueueRepository();

  final FirebaseFirestore _firestore;
  final ConnectivityService _connectivityService;
  final OfflineRewardRepository _offlineRewardRepository;
  final SyncQueueRepository _syncQueueRepository;

  @override
  Future<List<RewardModel>> getRewards() async {
    if (await _connectivityService.hasInternetConnection()) {
      try {
        final snapshot = await _firestore
            .collection('rewards')
            .where('active', isEqualTo: true)
            .get();

        if (snapshot.docs.isNotEmpty) {
          for (final doc in snapshot.docs) {
            await _offlineRewardRepository.cacheReward(
              doc.id,
              sanitizeMapForHive(doc.data()),
            );
          }
          return snapshot.docs
              .map((doc) => RewardModel.fromDocument(doc))
              .toList();
        }
      } catch (_) {
        // Fall through to the local cache.
      }
    }

    final cachedRewards = await _offlineRewardRepository.getAllRewards();
    return cachedRewards
        .where((data) => data['active'] != false)
        .map(
          (data) =>
              RewardModel.fromMap(data, docId: data['id'] as String? ?? ''),
        )
        .toList();
  }

  @override
  Future<List<RewardRedemptionModel>> getUserRedemptions(String userId) async {
    if (userId.isEmpty) return [];

    if (await _connectivityService.hasInternetConnection()) {
      try {
        final snapshot = await _firestore
            .collection('reward_redemptions')
            .where('userId', isEqualTo: userId)
            .get();

        for (final doc in snapshot.docs) {
          await _offlineRewardRepository.cacheRedemption(
            doc.id,
            sanitizeMapForHive(doc.data()),
          );
        }
      } catch (_) {
        // Fall through to the local cache.
      }
    }

    final cachedRedemptions = await _offlineRewardRepository.getRedemptions(
      userId,
    );
    return cachedRedemptions
        .map(
          (data) => RewardRedemptionModel.fromMap(
            data,
            docId: data['id'] as String? ?? '',
          ),
        )
        .toList();
  }

  /// Write-through: the redemption is saved to the local cache first and
  /// pushed to Firebase afterwards. When offline (or the push fails) only
  /// this new redemption is queued for the next sync.
  @override
  Future<void> createRedemption({
    required String userId,
    required String rewardId,
    required String rewardName,
    required int pointsUsed,
  }) async {
    final hasInternet = await _connectivityService.hasInternetConnection();
    final redemptionId = hasInternet
        ? _firestore.collection('reward_redemptions').doc().id
        : 'offline_${DateTime.now().millisecondsSinceEpoch}';
    final redeemedAt = DateTime.now().toUtc();

    final redemptionData = <String, dynamic>{
      'userId': userId,
      'rewardId': rewardId,
      'rewardName': rewardName,
      'pointsUsed': pointsUsed,
      'status': 'pending',
      'redeemedAt': redeemedAt,
    };

    await _offlineRewardRepository.saveRedemption(
      redemptionId,
      redemptionData,
    );
    await _offlineRewardRepository.decrementRewardStock(rewardId);

    if (hasInternet) {
      try {
        await _firestore
            .collection('reward_redemptions')
            .doc(redemptionId)
            .set({
              ...redemptionData,
              'redeemedAt': redeemedAt.toIso8601String(),
            });
        await _decrementRemoteStock(rewardId);
        await _offlineRewardRepository.markRedemptionSynced(redemptionId);
        return;
      } catch (_) {
        // Fall through and queue the redemption for the next sync.
      }
    }

    await _syncQueueRepository.addOperation(
      SyncOperationModel(
        id: 'redemption_$redemptionId',
        feature: 'redemption',
        operation: 'create',
        data: {
          ...redemptionData,
          'id': redemptionId,
          'redeemedAt': redeemedAt.toIso8601String(),
        },
        createdAt: redeemedAt,
      ),
    );
  }

  Future<void> _decrementRemoteStock(String rewardId) async {
    if (rewardId.isEmpty) return;

    try {
      final docRef = _firestore.collection('rewards').doc(rewardId);
      final docSnapshot = await docRef.get();
      if (docSnapshot.exists && docSnapshot.data()?['stock'] != null) {
        final currentStock = (docSnapshot.data()?['stock'] as num).toInt();
        if (currentStock > 0) {
          await docRef.update({
            'stock': FieldValue.increment(-1),
          });
        }
      }
    } catch (_) {
      // Ignored if the reward document does not exist.
    }
  }
}
