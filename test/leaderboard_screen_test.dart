import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:greenoffice360/features/gamification/controllers/leaderboard_controller.dart';
import 'package:greenoffice360/features/gamification/providers/leaderboard_provider.dart';
import 'package:greenoffice360/features/gamification/screens/leaderboard_screen.dart';
import 'package:greenoffice360/models/leaderboard_model.dart';
import 'package:greenoffice360/repositories/leaderboard_repository.dart';

class _FakeLeaderboardRepository implements LeaderboardRepository {
  @override
  Future<LeaderboardData> getLeaderboard({
    required LeaderboardScope scope,
    required LeaderboardPeriod period,
  }) async {
    if (period == LeaderboardPeriod.week) {
      return const LeaderboardData(
        entries: [
          LeaderboardEntry(
            rank: 1,
            name: 'Solo User',
            points: 125,
            progress: 1,
          ),
        ],
        currentUser: null,
        nextEntry: null,
      );
    }
    final entries = scope == LeaderboardScope.departments
        ? const [
            LeaderboardEntry(
              rank: 1,
              name: 'Operations',
              points: 1720,
              progress: 1,
            ),
            LeaderboardEntry(
              rank: 2,
              name: 'Legal',
              points: 1410,
              progress: .8,
            ),
            LeaderboardEntry(
              rank: 3,
              name: 'Marketing',
              points: 1340,
              progress: .7,
            ),
            LeaderboardEntry(
              rank: 4,
              name: 'Sales',
              points: 1280,
              progress: .6,
            ),
          ]
        : const [
            LeaderboardEntry(
              rank: 1,
              name: 'Sarah Chen',
              points: 3240,
              progress: 1,
            ),
            LeaderboardEntry(
              rank: 2,
              name: 'James Wilson',
              points: 2890,
              progress: .8,
            ),
            LeaderboardEntry(
              rank: 3,
              name: 'Maria Lopez',
              points: 2450,
              progress: .7,
            ),
            LeaderboardEntry(
              rank: 4,
              name: 'David Park',
              points: 2120,
              progress: .6,
            ),
          ];
    return LeaderboardData(
      entries: entries,
      currentUser: null,
      nextEntry: null,
    );
  }
}

void main() {
  testWidgets('renders the leaderboard design and switches filters', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LeaderboardProvider(
          controller: LeaderboardController(
            repository: _FakeLeaderboardRepository(),
          ),
        ),
        child: const MaterialApp(home: LeaderboardScreen()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Leaderboard'), findsOneWidget);
    expect(find.text('Departments'), findsOneWidget);
    expect(find.text('Marketing'), findsOneWidget);
    expect(find.text('Department Standings'), findsOneWidget);

    await tester.tap(find.text('Individuals'));
    await tester.tap(find.text('All Time'));
    await tester.pumpAndSettle();

    expect(find.text('Individuals'), findsOneWidget);
    expect(find.text('All Time'), findsOneWidget);
    expect(find.text('Sarah Chen'), findsOneWidget);
    expect(find.text('James Wilson'), findsOneWidget);
    expect(find.text('Maria Lopez'), findsOneWidget);
    expect(find.text('Individual Standings'), findsOneWidget);
    expect(find.text('Not ranked yet'), findsOneWidget);

    await tester.tap(find.text('Departments'));
    await tester.tap(find.text('This Week'));
    await tester.pumpAndSettle();

    expect(find.text('Solo User'), findsOneWidget);
  });
}
