import 'package:flutter/foundation.dart';

import '../../../models/leaderboard_model.dart';
import '../../../services/data_change_notifier.dart';
import '../controllers/leaderboard_controller.dart';

enum LeaderboardStatus { initial, loading, success, error }

class LeaderboardProvider extends ChangeNotifier {
  LeaderboardProvider({
    required LeaderboardController controller,
    DataChangeNotifier? dataChangeNotifier,
  }) : _controller = controller {
    _dataChangeSubscription = dataChangeNotifier;
    dataChangeNotifier?.addListener(_reload);
  }

  final LeaderboardController _controller;
  DataChangeNotifier? _dataChangeSubscription;
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

  void _reload() {
    if (_data == null) return;
    loadLeaderboard();
  }

  @override
  void dispose() {
    _dataChangeSubscription?.removeListener(_reload);
    _dataChangeSubscription = null;
    super.dispose();
  }

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
