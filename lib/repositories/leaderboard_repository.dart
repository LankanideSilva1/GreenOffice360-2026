import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/leaderboard_model.dart';

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
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  @override
  Future<LeaderboardData> getLeaderboard({
    required LeaderboardScope scope,
    required LeaderboardPeriod period,
  }) async {
    final usersSnapshot = await _firestore.collection('users').get();
    final challengesSnapshot = await _firestore.collection('challenges').get();
    final participationSnapshot = await _firestore
        .collection('challengeParticipation')
        .get(
          const GetOptions(
            serverTimestampBehavior: ServerTimestampBehavior.estimate,
          ),
        );

    final users = {
      for (final document in usersSnapshot.docs)
        if ((document.data()['role'] as String? ?? '').toLowerCase() !=
            'manager')
          document.id: document.data(),
    };
    final challengeIds = challengesSnapshot.docs
        .map((document) => document.id)
        .toSet();
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

    for (final document in participationSnapshot.docs) {
      final data = document.data();
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
