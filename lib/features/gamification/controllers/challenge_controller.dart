import '../../../models/challenge_model.dart';
import '../../../repositories/challenge_repository.dart';

class ChallengeController {
  const ChallengeController({required ChallengeRepository repository})
    : _repository = repository;

  final ChallengeRepository _repository;

  Future<List<ChallengeModel>> getChallenges() {
    return _repository.getChallenges();
  }

  Future<String> createParticipation({required String challengeId}) {
    return _repository.createParticipation(challengeId: challengeId);
  }

  Future<void> deleteParticipation({required String challengeId}) {
    return _repository.deleteParticipation(challengeId: challengeId);
  }

  Future<void> updateCompletedSubsteps({
    required String challengeId,
    required List<String> completedSubstepIds,
    required int pointsEarned,
    required int totalSubsteps,
  }) {
    return _repository.updateCompletedSubsteps(
      challengeId: challengeId,
      completedSubstepIds: completedSubstepIds,
      pointsEarned: pointsEarned,
      totalSubsteps: totalSubsteps,
    );
  }
}
