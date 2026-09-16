import 'package:flutter/foundation.dart';

import '../../../models/reward_model.dart';
import '../../../models/reward_redemption_model.dart';
import '../controllers/reward_controller.dart';

enum RewardStatus { initial, loading, success, error }

class RewardProvider extends ChangeNotifier {
  RewardProvider({required RewardController controller})
    : _controller = controller;

  final RewardController _controller;
  RewardStatus _status = RewardStatus.initial;
  String? _errorMessage;
  final List<RewardModel> _rewards = [];
  final List<RewardRedemptionModel> _redemptions = [];

  RewardStatus get status => _status;
  bool get isLoading => _status == RewardStatus.loading;
  String? get errorMessage => _errorMessage;
  List<RewardModel> get rewards => List.unmodifiable(_rewards);
  List<RewardRedemptionModel> get redemptions => List.unmodifiable(_redemptions);

  Future<void> loadRewards({String? userId}) async {
    _status = RewardStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _controller.getRewards();
      _rewards
        ..clear()
        ..addAll(result.whereType<RewardModel>());

      if (userId != null && userId.isNotEmpty) {
        final userRedemptions = await _controller.getUserRedemptions(userId);
        _redemptions
          ..clear()
          ..addAll(userRedemptions);
      }

      _status = RewardStatus.success;
    } catch (error) {
      _status = RewardStatus.error;
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
    }

    notifyListeners();
  }

  Future<bool> redeemReward({
    required String userId,
    required RewardModel reward,
  }) async {
    try {
      await _controller.redeemReward(
        userId: userId,
        rewardId: reward.id,
        rewardName: reward.name,
        pointsUsed: reward.requiredPoints,
      );

      final index = _rewards.indexWhere((r) => r.id == reward.id);
      if (index != -1) {
        final currentReward = _rewards[index];
        if (currentReward.stock != null) {
          final updatedStock = (currentReward.stock! - 1).clamp(0, 999999);
          _rewards[index] = currentReward.copyWith(stock: updatedStock);
        }
      }

      _redemptions.insert(
        0,
        RewardRedemptionModel(
          id: '',
          userId: userId,
          rewardId: reward.id,
          rewardName: reward.name,
          pointsUsed: reward.requiredPoints,
          status: 'pending',
          redeemedAt: DateTime.now(),
        ),
      );
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
