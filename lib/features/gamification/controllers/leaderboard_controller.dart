import '../../../models/leaderboard_model.dart';
import '../../../repositories/leaderboard_repository.dart';

class LeaderboardController {
  const LeaderboardController({required LeaderboardRepository repository})
    : _repository = repository;

  final LeaderboardRepository _repository;

  Future<LeaderboardData> getLeaderboard({
    required LeaderboardScope scope,
    required LeaderboardPeriod period,
  }) {
    return _repository.getLeaderboard(scope: scope, period: period);
  }
}
