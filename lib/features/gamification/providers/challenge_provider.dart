import 'package:flutter/foundation.dart';

import '../../../models/challenge_model.dart';
import '../controllers/challenge_controller.dart';

enum ChallengeStatus { initial, loading, success, error }

class ChallengeProvider extends ChangeNotifier {
  ChallengeProvider({required ChallengeController controller})
    : _controller = controller;

  final ChallengeController _controller;
  ChallengeStatus _status = ChallengeStatus.initial;
  String? _errorMessage;
  final List<ChallengeModel> _challenges = [];

  ChallengeStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<ChallengeModel> get challenges => List.unmodifiable(_challenges);
  bool get isLoading => _status == ChallengeStatus.loading;

  Future<void> loadChallenges() async {
    _status = ChallengeStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _challenges
        ..clear()
        ..addAll(await _controller.getChallenges());
      _status = ChallengeStatus.success;
    } catch (error) {
      _status = ChallengeStatus.error;
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  Future<bool> joinChallenge(String challengeId) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _controller.createParticipation(challengeId: challengeId);
      final index = _challenges.indexWhere(
        (challenge) => challenge.id == challengeId,
      );
      if (index != -1) {
        final challenge = _challenges[index];
        _challenges[index] = ChallengeModel(
          id: challenge.id,
          title: challenge.title,
          description: challenge.description,
          category: challenge.category,
          difficulty: challenge.difficulty,
          points: challenge.points,
          durationDays: challenge.durationDays,
          isActive: challenge.isActive,
          substeps: challenge.substeps,
          startDate: challenge.startDate,
          endDate: challenge.endDate,
          participantCount:
              challenge.participantCount + (challenge.joinedByUser ? 0 : 1),
          joinedByUser: true,
          progress: challenge.progress,
          completedSubstepIds: challenge.completedSubstepIds,
        );
      }
      notifyListeners();
      return true;
    } catch (error) {
      _status = ChallengeStatus.error;
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCompletedSubsteps({
    required String challengeId,
    required List<String> completedSubstepIds,
    required int pointsEarned,
    required int totalSubsteps,
  }) async {
    try {
      await _controller.updateCompletedSubsteps(
        challengeId: challengeId,
        completedSubstepIds: completedSubstepIds,
        pointsEarned: pointsEarned,
        totalSubsteps: totalSubsteps,
      );
      final index = _challenges.indexWhere(
        (challenge) => challenge.id == challengeId,
      );
      if (index != -1) {
        final challenge = _challenges[index];
        _challenges[index] = ChallengeModel(
          id: challenge.id,
          title: challenge.title,
          description: challenge.description,
          category: challenge.category,
          difficulty: challenge.difficulty,
          points: challenge.points,
          durationDays: challenge.durationDays,
          isActive: challenge.isActive,
          substeps: challenge.substeps,
          startDate: challenge.startDate,
          endDate: challenge.endDate,
          participantCount: challenge.participantCount,
          joinedByUser: true,
          progress: totalSubsteps == 0
              ? 0
              : completedSubstepIds.length / totalSubsteps,
          completedSubstepIds: completedSubstepIds,
        );
      }
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> leaveChallenge(String challengeId) async {
    _errorMessage = null;
    try {
      await _controller.deleteParticipation(challengeId: challengeId);
      // _challenges.removeWhere((challenge) => challenge.id == challengeId);
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
