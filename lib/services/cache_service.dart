import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/issue_model.dart';
import '../repositories/offline/offline_challenge_repository.dart';
import '../repositories/offline/offline_issue_repository.dart';
import '../repositories/offline/offline_reward_repository.dart';
import '../repositories/offline/offline_user_repository.dart';
import 'connectivity_service.dart';
import 'hive_cache_sanitizer.dart';

/// Pulls the app's real data from Firestore into the Hive cache.
///
/// Runs after login and whenever the app starts with an authenticated
/// session, so the user can keep working from the cache with or without
/// a connection. Entries that were modified locally and are still pending
/// synchronization are never overwritten by server data.
class CacheService {
  CacheService({
    FirebaseFirestore? firestore,
    ConnectivityService? connectivityService,
    OfflineUserRepository? offlineUserRepository,
    OfflineIssueRepository? offlineIssueRepository,
    OfflineChallengeRepository? offlineChallengeRepository,
    OfflineRewardRepository? offlineRewardRepository,
  }) : _firestore = firestore,
       _connectivityService = connectivityService ?? ConnectivityService(),
       _offlineUserRepository =
           offlineUserRepository ?? OfflineUserRepository(),
       _offlineIssueRepository =
           offlineIssueRepository ?? OfflineIssueRepository(),
       _offlineChallengeRepository =
           offlineChallengeRepository ?? OfflineChallengeRepository(),
       _offlineRewardRepository =
           offlineRewardRepository ?? OfflineRewardRepository();

  // Resolved lazily so constructing the service never requires Firebase
  // to be initialized (e.g. in unit tests).
  FirebaseFirestore? _firestore;
  final ConnectivityService _connectivityService;
  final OfflineUserRepository _offlineUserRepository;
  final OfflineIssueRepository _offlineIssueRepository;
  final OfflineChallengeRepository _offlineChallengeRepository;
  final OfflineRewardRepository _offlineRewardRepository;

  FirebaseFirestore get _firestoreInstance =>
      _firestore ??= FirebaseFirestore.instance;

  bool _isHydrating = false;

  /// Fetch every collection into Hive. Failures are swallowed so the app
  /// keeps working from whatever is already cached.
  Future<void> hydrateAll({String? userId}) async {
    if (_isHydrating) return;
    if (!await _connectivityService.hasInternetConnection()) return;

    _isHydrating = true;
    try {
      await Future.wait([
        _hydrateUsers(),
        _hydrateIssues(),
        _hydrateChallenges(),
        _hydrateParticipation(),
        _hydrateRewards(),
        _hydrateRedemptions(userId),
      ]);
    } finally {
      _isHydrating = false;
    }
  }

  Future<void> _hydrateUsers() async {
    try {
      final snapshot = await _firestoreInstance.collection('users').get();
      for (final doc in snapshot.docs) {
        await _offlineUserRepository.cacheUserData(
          doc.id,
          sanitizeMapForHive(doc.data()),
        );
      }
    } catch (_) {
      // Keep the existing cache.
    }
  }

  Future<void> _hydrateIssues() async {
    try {
      final pendingIds = (await _offlineIssueRepository.getPendingIssues())
          .map((data) => data['id'])
          .whereType<String>()
          .toSet();
      final snapshot = await _firestoreInstance.collection('issues').get();
      for (final doc in snapshot.docs) {
        if (pendingIds.contains(doc.id)) continue;
        await _offlineIssueRepository.cacheIssue(
          IssueModel.fromMap(doc.data(), doc.id),
        );
      }
    } catch (_) {
      // Keep the existing cache.
    }
  }

  Future<void> _hydrateChallenges() async {
    try {
      final snapshot = await _firestoreInstance.collection('challenges').get();
      for (final doc in snapshot.docs) {
        await _offlineChallengeRepository.cacheChallenge(
          doc.id,
          sanitizeMapForHive(doc.data()),
        );
      }
    } catch (_) {
      // Keep the existing cache.
    }
  }

  Future<void> _hydrateParticipation() async {
    try {
      final snapshot = await _firestoreInstance
          .collection('challengeParticipation')
          .get();
      for (final doc in snapshot.docs) {
        await _offlineChallengeRepository.cacheParticipation(
          doc.id,
          sanitizeMapForHive(doc.data()),
        );
      }
    } catch (_) {
      // Keep the existing cache.
    }
  }

  Future<void> _hydrateRewards() async {
    try {
      final snapshot = await _firestoreInstance.collection('rewards').get();
      for (final doc in snapshot.docs) {
        await _offlineRewardRepository.cacheReward(
          doc.id,
          sanitizeMapForHive(doc.data()),
        );
      }
    } catch (_) {
      // Keep the existing cache.
    }
  }

  Future<void> _hydrateRedemptions(String? userId) async {
    try {
      final query = userId == null || userId.isEmpty
          ? _firestoreInstance.collection('reward_redemptions')
          : _firestoreInstance
                .collection('reward_redemptions')
                .where('userId', isEqualTo: userId);
      final snapshot = await query.get();
      for (final doc in snapshot.docs) {
        await _offlineRewardRepository.cacheRedemption(
          doc.id,
          sanitizeMapForHive(doc.data()),
        );
      }
    } catch (_) {
      // Keep the existing cache.
    }
  }
}
