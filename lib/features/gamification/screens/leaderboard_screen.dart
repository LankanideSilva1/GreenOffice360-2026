import 'package:flutter/material.dart';
import 'package:greenoffice360/core/constants/app_colors.dart';
import 'package:greenoffice360/features/gamification/providers/leaderboard_provider.dart';
import 'package:greenoffice360/models/leaderboard_model.dart';
import 'package:provider/provider.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _scope = 'Departments';
  String _period = 'This Month';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<LeaderboardProvider>().loadLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LeaderboardProvider>();
    final data = provider.data;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildScopeTabs(),
                    const SizedBox(height: 12),
                    _buildPeriodTabs(),
                    const SizedBox(height: 20),
                    if (provider.isLoading && data == null)
                      const SizedBox(
                        height: 275,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (provider.status == LeaderboardStatus.error)
                      SizedBox(
                        height: 275,
                        child: Center(
                          child: Text(
                            provider.errorMessage ??
                                'Unable to load leaderboard',
                          ),
                        ),
                      )
                    else
                      _buildPodium(data?.entries ?? const []),
                    const SizedBox(height: 20),
                    _buildInsight(data),
                    const SizedBox(height: 20),
                    _buildRankCard(data),
                    const SizedBox(height: 20),
                    Text(
                      provider.scope == LeaderboardScope.departments
                          ? 'Department Standings'
                          : 'Individual Standings',
                      style: TextStyle(
                        color: Color(0xFF5B6F8B),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    ...(data?.entries.skip(3).map(_buildStanding) ??
                        const <Widget>[]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, size: 21),
            style: IconButton.styleFrom(
              foregroundColor: const Color(0xFF24324A),
              backgroundColor: AppColors.white,
              side: const BorderSide(color: Color(0xFFDDE5ED)),
              fixedSize: const Size(34, 34),
            ),
          ),
          const Expanded(
            child: Text(
              'Leaderboard',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF24324A),
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 34),
        ],
      ),
    );
  }

  Widget _buildScopeTabs() {
    final provider = context.read<LeaderboardProvider>();
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEE9),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: ['Departments', 'Individuals'].map((scope) {
          final selected = provider.scope == _scopeForLabel(scope);
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _scope = scope);
                provider.loadLeaderboard(scope: _scopeForLabel(scope));
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: selected
                      ? const [
                          BoxShadow(color: Color(0x12000000), blurRadius: 4),
                        ]
                      : null,
                ),
                child: Text(
                  scope,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF0D9B49)
                        : const Color(0xFF5B6F8B),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPeriodTabs() {
    final provider = context.read<LeaderboardProvider>();
    return Row(
      children: ['This Week', 'This Month', 'All Time'].map((period) {
        final selected = provider.period == _periodForLabel(period);
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              setState(() => _period = period);
              provider.loadLeaderboard(period: _periodForLabel(period));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF155847) : AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF155847)
                      : const Color(0xFFDDE5ED),
                ),
              ),
              child: Text(
                period,
                style: TextStyle(
                  color: selected ? AppColors.white : const Color(0xFF5B6F8B),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  LeaderboardScope _scopeForLabel(String value) {
    return value == 'Individuals'
        ? LeaderboardScope.individuals
        : LeaderboardScope.departments;
  }

  LeaderboardPeriod _periodForLabel(String value) {
    if (value == 'This Week') return LeaderboardPeriod.week;
    if (value == 'All Time') return LeaderboardPeriod.allTime;
    return LeaderboardPeriod.month;
  }

  Widget _buildPodium(List<LeaderboardEntry> entries) {
    final podium = entries.take(3).toList();
    if (podium.isEmpty) {
      return const SizedBox(
        height: 275,
        child: Center(child: Text('Not enough ranking data yet')),
      );
    }
    final places = podium.length == 1
        ? podium
        : [podium[1], podium[0], if (podium.length > 2) podium[2]];
    return _PodiumCard(
      places: List.generate(places.length, (index) {
        final entry = places[index];
        return _PodiumData(
          rank: entry.rank,
          name: entry.name,
          avatarLabel: entry.avatarLabel,
          points: '${_formatPoints(entry.points)} pts',
          color: index == 1
              ? const Color(0xFFE26800)
              : index == 0
              ? const Color(0xFF647896)
              : const Color(0xFFC34D00),
          height: index == 1
              ? 119
              : index == 0
              ? 89
              : 70,
        );
      }),
    );
  }

  String _formatPoints(int points) =>
      points.toString().replaceAllMapped(RegExp(r'(?=(\d{3})+$)'), (_) => ',');

  Widget _buildDepartmentPodium() {
    return Container(
      height: 275,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE5ED)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x081B3245),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _PodiumPlace(
              rank: 2,
              name: 'HR',
              points: '2,180 pts',
              color: const Color(0xFF647896),
              height: 89,
            ),
          ),
          Expanded(
            child: _PodiumPlace(
              rank: 1,
              name: 'IT',
              points: '2,450 pts',
              color: const Color(0xFFE26800),
              height: 119,
            ),
          ),
          Expanded(
            child: _PodiumPlace(
              rank: 3,
              name: 'Finance',
              points: '1,950 pts',
              color: const Color(0xFFC34D00),
              height: 70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualPodium() {
    return _PodiumCard(
      places: const [
        _PodiumData(
          rank: 2,
          name: 'James Wilson',
          avatarLabel: 'JW',
          points: '2,890 pts',
          color: Color(0xFF647896),
          height: 89,
        ),
        _PodiumData(
          rank: 1,
          name: 'Sarah Chen',
          avatarLabel: 'SC',
          points: '3,240 pts',
          color: Color(0xFFE26800),
          height: 119,
        ),
        _PodiumData(
          rank: 3,
          name: 'Maria Lopez',
          avatarLabel: 'ML',
          points: '2,450 pts',
          color: Color(0xFFC34D00),
          height: 70,
        ),
      ],
    );
  }

  Widget _buildInsight(LeaderboardData? data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFD8F9E5),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 20)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              data?.currentUser == null
                  ? 'Complete challenges to appear on the leaderboard.'
                  : _scope == 'Departments'
                  ? 'Your department is climbing this month. Keep it up!'
                  : 'You are making progress this month. Keep it up!',
              style: TextStyle(
                color: Color(0xFF167443),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankCard(LeaderboardData? data) {
    final current = data?.currentUser;
    final next = data?.nextEntry;
    final rankLabel = current == null
        ? 'Not ranked yet'
        : '#${current.rank} ${current.name}';
    final nextLabel = next == null
        ? 'You are at the top'
        : 'Next: #${next.rank} ${next.name} (${_formatPoints(next.points)} pts)';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 15, 15, 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(11),
        border: const Border(
          left: BorderSide(color: Color(0xFF0EA44D), width: 4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x081B3245),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MY RANK',
                    style: TextStyle(
                      color: Color(0xFF647896),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    rankLabel,
                    style: TextStyle(
                      color: Color(0xFF24324A),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Text(
                current?.previousRank == null || current == null
                    ? ''
                    : '↑ +${current.previousRank! - current.rank} this month',
                style: TextStyle(
                  color: Color(0xFF0D9B49),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                current == null
                    ? '0 pts'
                    : '${_formatPoints(current.points)} pts',
                style: TextStyle(
                  color: Color(0xFF24324A),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                nextLabel,
                style: TextStyle(color: Color(0xFF647896), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(5)),
            child: LinearProgressIndicator(
              value: current == null || next == null
                  ? 0
                  : current.points / next.points,
              minHeight: 7,
              backgroundColor: Color(0xFFEAF0F4),
              valueColor: AlwaysStoppedAnimation(Color(0xFF13A451)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStanding(LeaderboardEntry standing) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: standing.isCurrentUser
            ? const Color(0xFFD9F8E5)
            : AppColors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: standing.isCurrentUser
              ? const Color(0xFFB0EAC5)
              : const Color(0xFFDDE5ED),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${standing.rank}',
              style: const TextStyle(
                color: Color(0xFF526176),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  standing.name,
                  style: const TextStyle(
                    color: Color(0xFF24324A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                SizedBox(
                  width: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: standing.progress,
                      minHeight: 4,
                      backgroundColor: const Color(0xFFEAF0F4),
                      valueColor: AlwaysStoppedAnimation(
                        standing.isCurrentUser
                            ? const Color(0xFF155847)
                            : const Color(0xFFBFC8D2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_formatPoints(standing.points)} pts',
            style: const TextStyle(
              color: Color(0xFF24324A),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Standing {
  const _Standing({
    required this.rank,
    required this.name,
    required this.points,
    required this.progress,
    this.selected = false,
  });

  final int rank;
  final String name;
  final int points;
  final double progress;
  final bool selected;
}

class _PodiumData {
  const _PodiumData({
    required this.rank,
    required this.name,
    required this.avatarLabel,
    required this.points,
    required this.color,
    required this.height,
  });

  final int rank;
  final String name;
  final String avatarLabel;
  final String points;
  final Color color;
  final double height;
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({required this.places});

  final List<_PodiumData> places;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 275,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE5ED)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x081B3245),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: places
            .map(
              (place) => Expanded(
                child: _PodiumPlace(
                  rank: place.rank,
                  name: place.name,
                  avatarLabel: place.avatarLabel,
                  points: place.points,
                  color: place.color,
                  height: place.height,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PodiumPlace extends StatelessWidget {
  const _PodiumPlace({
    required this.rank,
    required this.name,
    this.avatarLabel,
    required this.points,
    required this.color,
    required this.height,
  });

  final int rank;
  final String name;
  final String? avatarLabel;
  final String points;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FC),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            avatarLabel ?? (name == 'Finance' ? 'FI' : name),
            style: TextStyle(
              color: const Color(0xFF155847),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: rank == 1
                ? const Color(0xFFFFF0B8)
                : const Color(0xFFEAF0F4),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            '${rank == 1
                ? '1ST'
                : rank == 2
                ? '2ND'
                : '3RD'}',
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF24324A),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          points,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF155847),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        Container(height: height, color: const Color(0xFFF0F4F8)),
      ],
    );
  }
}
