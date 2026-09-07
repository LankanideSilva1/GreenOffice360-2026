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
}
