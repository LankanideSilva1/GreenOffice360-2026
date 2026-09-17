import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/leaderboard_model.dart';
import '../services/connectivity_service.dart';
import '../services/hive_cache_sanitizer.dart';
import 'offline/offline_challenge_repository.dart';
import 'offline/offline_user_repository.dart';

abstract class LeaderboardRepository {
  Future<LeaderboardData> getLeaderboard({
    required LeaderboardScope scope,
    required LeaderboardPeriod period,
  });
}

class FirestoreLeaderboardRepository implements LeaderboardRepository {
  FirestoreLeaderboardRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    ConnectivityService? connectivityService,
    OfflineUserRepository? offlineUserRepository,
    OfflineChallengeRepository? offlineChallengeRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _connectivityService = connectivityService ?? ConnectivityService(),
       _offlineUserRepository =
           offlineUserRepository ?? OfflineUserRepository(),
       _offlineChallengeRepository =
           offlineChallengeRepository ?? OfflineChallengeRepository();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final ConnectivityService _connectivityService;
  final OfflineUserRepository _offlineUserRepository;
  final OfflineChallengeRepository _offlineChallengeRepository;

  @override
  Future<LeaderboardData> getLeaderboard({
    required LeaderboardScope scope,
    required LeaderboardPeriod period,
  }) async {
    Map<String, Map<String, dynamic>> allUsers;
    Set<String> challengeIds;
    List<Map<String, dynamic>> participationsData;

    if (await _connectivityService.hasInternetConnection()) {
      try {
        final usersSnapshot = await _firestore.collection('users').get();
        final challengesSnapshot = await _firestore
            .collection('challenges')
            .get();
        final participationSnapshot = await _firestore
            .collection('challengeParticipation')
            .get(
              const GetOptions(
                serverTimestampBehavior: ServerTimestampBehavior.estimate,
              ),
            );

        allUsers = {
          for (final document in usersSnapshot.docs)
            document.id: sanitizeMapForHive(document.data()),
        };
        challengeIds = challengesSnapshot.docs
            .map((document) => document.id)
            .toSet();
        participationsData = participationSnapshot.docs
            .map((doc) => sanitizeMapForHive(doc.data())..['id'] = doc.id)
            .toList();

        // Refresh the local cache so every screen can work offline.
        for (final entry in allUsers.entries) {
          await _offlineUserRepository.cacheUserData(entry.key, entry.value);
        }
        for (final doc in challengesSnapshot.docs) {
          await _offlineChallengeRepository.cacheChallenge(
            doc.id,
            sanitizeMapForHive(doc.data()),
          );
        }
        for (final doc in participationSnapshot.docs) {
          await _offlineChallengeRepository.cacheParticipation(
            doc.id,
            sanitizeMapForHive(doc.data()),
          );
        }
      } catch (_) {
        (allUsers, challengeIds, participationsData) = await _loadFromCache();
      }
    } else {
      (allUsers, challengeIds, participationsData) = await _loadFromCache();
    }

    final users = {
      for (final entry in allUsers.entries)
        if ((entry.value['role'] as String? ?? '').toLowerCase() != 'manager')
          entry.key: entry.value,
    };
    final startDate = _startDate(period);
    final scores = <String, int>{};
    final periodUserIds = <String>{};
    final currentUserId = _firebaseAuth.currentUser?.uid;

    if (period == LeaderboardPeriod.allTime) {
      for (final entry in users.entries) {
        final data = entry.value;
        final points = data['points'] ?? data['greenScore'];
        scores[entry.key] = _toInt(points);
      }
    }

    for (final data in participationsData) {
      final challengeId = data['challengeId'] as String?;
      final userId = data['userId'] as String?;
      if (challengeId == null ||
          userId == null ||
          !challengeIds.contains(challengeId)) {
        continue;
      }
      final joinedAt = _toDate(data['joinedAt']) ?? _toDate(data['createdAt']);
      if (startDate != null && joinedAt != null && joinedAt.isBefore(startDate))
        continue;
      if (period != LeaderboardPeriod.allTime) {
        periodUserIds.add(userId);
      }
    }

    if (period != LeaderboardPeriod.allTime) {
      for (final userId in periodUserIds) {
        final user = users[userId];
        if (user == null) continue;
        final currentScore = user['points'] ?? user['greenScore'];
        scores[userId] = _toInt(currentScore);
      }
    }

    final groupedScores = <String, int>{};
    final currentUserDepartment = currentUserId == null
        ? null
        : users[currentUserId]?['department'] as String?;
    for (final entry in scores.entries) {
      final user = users[entry.key];
      if (user == null) continue;
      final group = scope == LeaderboardScope.individuals
          ? entry.key
          : (user['department'] as String? ?? 'Unassigned');
      groupedScores[group] = (groupedScores[group] ?? 0) + entry.value;
    }

    final sortedGroups = groupedScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final entries = <LeaderboardEntry>[];
    for (var index = 0; index < sortedGroups.length; index++) {
      final group = sortedGroups[index];
      final user = scope == LeaderboardScope.individuals
          ? users[group.key]
          : null;
      final name = scope == LeaderboardScope.individuals
          ? (user?['name'] as String? ?? 'Unknown User')
          : group.key;
      entries.add(
        LeaderboardEntry(
          rank: index + 1,
          name: name,
          points: group.value,
          progress: sortedGroups.first.value == 0
              ? 0
              : group.value / sortedGroups.first.value,
          userId: scope == LeaderboardScope.individuals ? group.key : null,
          department: scope == LeaderboardScope.individuals
              ? (user?['department'] as String?)
              : group.key,
          isCurrentUser: scope == LeaderboardScope.individuals
              ? group.key == currentUserId
              : group.key == currentUserDepartment,
        ),
      );
    }

    final currentUser = entries.cast<LeaderboardEntry?>().firstWhere(
      (entry) => entry?.isCurrentUser == true,
      orElse: () => null,
    );
    final nextEntry = currentUser == null || currentUser.rank <= 1
        ? null
        : entries.firstWhere((entry) => entry.rank == currentUser.rank - 1);
    return LeaderboardData(
      entries: entries,
      currentUser: currentUser,
      nextEntry: nextEntry,
    );
  }

  /// Load leaderboard source data from the Hive cache for offline use.
  Future<(Map<String, Map<String, dynamic>>, Set<String>, List<Map<String, dynamic>>)>
  _loadFromCache() async {
    final usersData = await _offlineUserRepository.getAllUsersData();
    final challengesData = await _offlineChallengeRepository.getAllChallenges();
    final participationsData =
        await _offlineChallengeRepository.getAllParticipations();

    final users = <String, Map<String, dynamic>>{
      for (final data in usersData)
        if (data['id'] is String) data['id'] as String: data,
    };
    final challengeIds = challengesData
        .map((data) => data['id'])
        .whereType<String>()
        .toSet();

    return (users, challengeIds, participationsData);
  }

  DateTime? _startDate(LeaderboardPeriod period) {
    if (period == LeaderboardPeriod.allTime) return null;
    final now = DateTime.now();
    return period == LeaderboardPeriod.week
        ? now.subtract(const Duration(days: 7))
        : DateTime(now.year, now.month, 1);
  }

  int _toInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _toDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
