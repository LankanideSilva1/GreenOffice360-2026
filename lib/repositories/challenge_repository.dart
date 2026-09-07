import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/challenge_model.dart';

abstract class ChallengeRepository {
  Future<List<ChallengeModel>> getChallenges();

  Future<String> createParticipation({required String challengeId});
}

class FirestoreChallengeRepository implements ChallengeRepository {
  FirestoreChallengeRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  @override
  Future<List<ChallengeModel>> getChallenges() async {
    final userId = _firebaseAuth.currentUser?.uid;
    final allParticipationSnapshot = await _firestore
        .collection('challengeParticipation')
        .get();
    final participantCounts = <String, int>{};
    for (final document in allParticipationSnapshot.docs) {
      final challengeId = document.data()['challengeId'] as String?;
      if (challengeId != null && challengeId.isNotEmpty) {
        participantCounts[challengeId] =
            (participantCounts[challengeId] ?? 0) + 1;
      }
    }
    final participationSnapshot = userId == null
        ? null
        : await _firestore
              .collection('challengeParticipation')
              .where('userId', isEqualTo: userId)
              .get();
    final participations = {
      for (final document
          in participationSnapshot?.docs ??
              <QueryDocumentSnapshot<Map<String, dynamic>>>[])
        document.data()['challengeId'] as String? ?? '': document.data(),
    };

    final snapshot = await _firestore
        .collection('challenges')
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs.map((document) {
      final participation = participations[document.id];
      final substeps = (document.data()['substeps'] as List?) ?? const [];
      final completedCount = _completedSubstepCount(participation);
      final progress = substeps.isEmpty
          ? 0.0
          : completedCount / substeps.length;
      return ChallengeModel.fromDocument(
        document,
        joinedByUser: participation != null,
        participantCount: participantCounts[document.id] ?? 0,
        progress: progress,
      );
    }).toList();
  }

  @override
  Future<String> createParticipation({required String challengeId}) async {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) {
      throw StateError('You must be signed in to join a challenge.');
    }

    final existing = await _firestore
        .collection('challengeParticipation')
        .where('userId', isEqualTo: userId)
        .get();
    for (final document in existing.docs) {
      if (document.data()['challengeId'] == challengeId) {
        return document.id;
      }
    }

    final document = _firestore.collection('challengeParticipation').doc();
    await document.set({
      'participationId': document.id,
      'challengeId': challengeId,
      'userId': userId,
      'joinedAt': FieldValue.serverTimestamp(),
      'completedAt': null,
      'status': 'joined',
      'pointsEarned': 0,
    });
    return document.id;
  }

  int _completedSubstepCount(Map<String, dynamic>? participation) {
    final completed = participation?['completedSubsteps'];
    return completed is List ? completed.length : 0;
  }
}
