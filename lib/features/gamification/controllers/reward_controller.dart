import '../../../models/reward_model.dart';
import '../../../models/reward_redemption_model.dart';
import '../../../repositories/reward_repository.dart';

class RewardController {
  const RewardController({required RewardRepository repository})
    : _repository = repository;

  final RewardRepository _repository;

  Future<List<RewardModel>> getRewards() async {
    return _repository.getRewards();
  }

  Future<List<RewardRedemptionModel>> getUserRedemptions(String userId) async {
    return _repository.getUserRedemptions(userId);
  }

  Future<void> redeemReward({
    required String userId,
    required String rewardId,
    required String rewardName,
    required int pointsUsed,
  }) async {
    return _repository.createRedemption(
      userId: userId,
      rewardId: rewardId,
      rewardName: rewardName,
      pointsUsed: pointsUsed,
    );
  }
}
