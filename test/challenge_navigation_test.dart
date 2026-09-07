import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:greenoffice360/features/gamification/controllers/challenge_controller.dart';
import 'package:greenoffice360/features/gamification/screens/challenge_list_screen.dart';
import 'package:greenoffice360/features/gamification/providers/challenge_provider.dart';
import 'package:greenoffice360/models/challenge_model.dart';
import 'package:greenoffice360/repositories/challenge_repository.dart';

class _FakeChallengeRepository implements ChallengeRepository {
  bool participationCreated = false;

  @override
  Future<List<ChallengeModel>> getChallenges() async {
    return [
      const ChallengeModel(
        id: 'challenge_001',
        title: 'Zero Waste Week',
        description: 'Reduce workplace waste for seven days.',
        category: 'Waste Reduction',
        difficulty: 'Easy',
        points: 150,
        durationDays: 7,
        isActive: true,
        joinedByUser: false,
        substeps: [
          ChallengeSubstep(
            id: 'step_1',
            title: 'Use reusable containers',
            description: '',
            points: 30,
          ),
        ],
      ),
    ];
  }

  @override
  Future<String> createParticipation({required String challengeId}) async {
    participationCreated = true;
    return 'participation_001';
  }
}

void main() {
  testWidgets('tapping a challenge opens its detail screen', (tester) async {
    final repository = _FakeChallengeRepository();
    await tester.pumpWidget(
      ChangeNotifierProvider<ChallengeProvider>(
        create: (_) => ChallengeProvider(
          controller: ChallengeController(repository: repository),
        ),
        child: MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: ChallengeListScreen(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Zero Waste Week'));
    await tester.pumpAndSettle();

    expect(repository.participationCreated, isTrue);
    expect(find.text('Challenge Details'), findsOneWidget);
    expect(find.text('Zero Waste Week'), findsOneWidget);
    expect(find.text('ABOUT'), findsOneWidget);
    expect(find.text('REQUIRED ACTIONS'), findsOneWidget);
    expect(find.text('YOUR PROGRESS'), findsOneWidget);
  });
}
