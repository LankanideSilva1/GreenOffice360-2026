import 'package:flutter/foundation.dart';

import '../../../models/leaderboard_model.dart';
import '../controllers/leaderboard_controller.dart';

enum LeaderboardStatus { initial, loading, success, error }

class LeaderboardProvider extends ChangeNotifier {
  LeaderboardProvider({required LeaderboardController controller})
    : _controller = controller;

  final LeaderboardController _controller;
  LeaderboardStatus _status = LeaderboardStatus.initial;
  String? _errorMessage;
  LeaderboardData? _data;
  LeaderboardScope _scope = LeaderboardScope.departments;
  LeaderboardPeriod _period = LeaderboardPeriod.month;

  LeaderboardStatus get status => _status;
  String? get errorMessage => _errorMessage;
  LeaderboardData? get data => _data;
  LeaderboardScope get scope => _scope;
  LeaderboardPeriod get period => _period;
  bool get isLoading => _status == LeaderboardStatus.loading;

  Future<void> loadLeaderboard({
    LeaderboardScope? scope,
    LeaderboardPeriod? period,
  }) async {
    _scope = scope ?? _scope;
    _period = period ?? _period;
    _status = LeaderboardStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _data = await _controller.getLeaderboard(scope: _scope, period: _period);
      _status = LeaderboardStatus.success;
    } catch (error) {
      _status = LeaderboardStatus.error;
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }
}
