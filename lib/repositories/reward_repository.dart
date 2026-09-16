import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/reward_model.dart';
import '../models/reward_redemption_model.dart';

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
  FirestoreRewardRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<RewardModel>> getRewards() async {
    try {
      final snapshot = await _firestore
          .collection('rewards')
          .where('active', isEqualTo: true)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => RewardModel.fromDocument(doc))
            .toList();
      }
    } catch (_) {
      // Fall back to the bundled demo rewards when no Firestore collection is available.
    }
    return [];
  }

  @override
  Future<List<RewardRedemptionModel>> getUserRedemptions(String userId) async {
    if (userId.isEmpty) return [];
    try {
      final snapshot = await _firestore
          .collection('reward_redemptions')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => RewardRedemptionModel.fromDocument(doc))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> createRedemption({
    required String userId,
    required String rewardId,
    required String rewardName,
    required int pointsUsed,
  }) async {
    await _firestore.collection('reward_redemptions').add({
      'userId': userId,
      'rewardId': rewardId,
      'rewardName': rewardName,
      'pointsUsed': pointsUsed,
      'status': 'pending',
      'redeemedAt': DateTime.now().toUtc().toIso8601String(),
    });

    if (rewardId.isNotEmpty) {
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
        // Ignored if offline or doc does not exist
      }
    }
  }
}
