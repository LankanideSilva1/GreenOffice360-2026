import 'package:hive_flutter/hive_flutter.dart';

import '../../services/local_database_service.dart';

/// Hive-backed cache for rewards and the current user's redemptions.
///
/// Redemption entries carry a `syncStatus` of `synced` or `pending`.
/// Pending entries were created while offline and are pushed to Firebase
/// by the sync service.
class OfflineRewardRepository {
  static const String _rewardsBoxName = LocalDatabaseService.rewardsBox;
  static const String _redemptionsBoxName =
      LocalDatabaseService.rewardRedemptionsBox;

  Future<Box> _getRewardsBox() async {
    if (!Hive.isBoxOpen(_rewardsBoxName)) {
      await Hive.openBox(_rewardsBoxName);
    }

    return Hive.box(_rewardsBoxName);
  }

  Future<Box> _getRedemptionsBox() async {
    if (!Hive.isBoxOpen(_redemptionsBoxName)) {
      await Hive.openBox(_redemptionsBoxName);
    }

    return Hive.box(_redemptionsBoxName);
  }

  // -------------------------------------------------------------------
  // Rewards
  // -------------------------------------------------------------------

  /// Cache a reward document fetched from the server.
  Future<void> cacheReward(String id, Map<String, dynamic> data) async {
    if (id.isEmpty) return;

    final box = await _getRewardsBox();
    final rewardData = Map<String, dynamic>.from(data)..['id'] = id;
    await box.put(id, rewardData);
  }

  Future<List<Map<String, dynamic>>> getAllRewards() async {
    final box = await _getRewardsBox();

    return box.values
        .whereType<Map>()
        .map((data) => Map<String, dynamic>.from(data))
        .toList();
  }

  /// Optimistically decrement the cached stock after a local redemption.
  Future<void> decrementRewardStock(String rewardId) async {
    if (rewardId.isEmpty) return;

    final box = await _getRewardsBox();
    final data = box.get(rewardId) as Map?;
    if (data == null || data['stock'] is! num) return;

    final currentStock = (data['stock'] as num).toInt();
    if (currentStock <= 0) return;

    final updated = Map<String, dynamic>.from(data)
      ..['stock'] = currentStock - 1;
    await box.put(rewardId, updated);
  }

  // -------------------------------------------------------------------
  // Redemptions
  // -------------------------------------------------------------------

  /// Save a redemption created locally. Always starts as pending.
  Future<void> saveRedemption(String id, Map<String, dynamic> data) async {
    final box = await _getRedemptionsBox();
    final redemptionData = Map<String, dynamic>.from(data)
      ..['id'] = id
      ..['syncStatus'] = 'pending';
    await box.put(id, redemptionData);
  }

  /// Cache a redemption fetched from the server. Pending (local, not yet
  /// pushed) entries are not overwritten.
  Future<void> cacheRedemption(String id, Map<String, dynamic> data) async {
    if (id.isEmpty) return;

    final box = await _getRedemptionsBox();
    final existing = box.get(id) as Map?;
    if (existing?['syncStatus'] == 'pending') {
      return;
    }

    final redemptionData = Map<String, dynamic>.from(data)
      ..['id'] = id
      ..['syncStatus'] = 'synced';
    await box.put(id, redemptionData);
  }

  Future<List<Map<String, dynamic>>> getRedemptions(String userId) async {
    final box = await _getRedemptionsBox();

    return box.values
        .whereType<Map>()
        .map((data) => Map<String, dynamic>.from(data))
        .where((data) => data['userId'] == userId)
        .toList();
  }

  Future<void> markRedemptionSynced(String id) async {
    final box = await _getRedemptionsBox();
    final data = box.get(id) as Map?;
    if (data == null) return;

    final updated = Map<String, dynamic>.from(data)
      ..['syncStatus'] = 'synced';
    await box.put(id, updated);
  }
}
