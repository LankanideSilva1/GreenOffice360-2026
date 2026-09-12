import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:greenoffice360/features/auth/controllers/auth_controller.dart';
import 'package:greenoffice360/features/auth/providers/auth_provider.dart';
import 'package:greenoffice360/features/gamification/controllers/challenge_controller.dart';
import 'package:greenoffice360/features/gamification/screens/challenge_list_screen.dart';
import 'package:greenoffice360/features/gamification/providers/challenge_provider.dart';
import 'package:greenoffice360/models/challenge_model.dart';
import 'package:greenoffice360/models/user_model.dart';
import 'package:greenoffice360/repositories/auth_repository.dart';
import 'package:greenoffice360/repositories/challenge_repository.dart';

class _FakeChallengeRepository implements ChallengeRepository {
  bool participationCreated = false;
  List<String> savedSubstepIds = [];
  int savedPoints = 0;
  String? deletedChallengeId;

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

  @override
  Future<void> updateCompletedSubsteps({
    required String challengeId,
    required List<String> completedSubstepIds,
    required int pointsEarned,
    required int totalSubsteps,
  }) async {
    savedSubstepIds = completedSubstepIds;
    savedPoints = pointsEarned;
  }

  @override
  Future<void> deleteParticipation({required String challengeId}) async {
    deletedChallengeId = challengeId;
  }
}

class _FakeAuthRepository extends AuthRepository {}

class _FakeAuthController extends AuthController {
  _FakeAuthController() : super(repository: _FakeAuthRepository());

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    return const UserModel(
      uid: 'user_1',
      name: 'Test User',
      email: 'test@example.com',
      employeeId: 'EMP-01',
      department: 'Operations',
      role: 'employee',
      greenScore: 10,
      points: 35,
    );
  }

  @override
  Future<UserModel> refreshCurrentUser() async {
    return const UserModel(
      uid: 'user_1',
      name: 'Test User',
      email: 'test@example.com',
      employeeId: 'EMP-01',
      department: 'Operations',
      role: 'employee',
      greenScore: 20,
      points: 85,
    );
  }
}

void main() {
  test('auth provider refreshes cached points after challenge completion', () async {
    final provider = AuthProvider(controller: _FakeAuthController());

    final loggedIn = await provider.login(
      email: 'test@example.com',
      password: 'password',
    );

    expect(loggedIn.points, 35);
    expect(provider.user?.points, 35);

    await provider.refreshCurrentUser();

    expect(provider.user?.points, 85);
    expect(provider.user?.greenScore, 20);
  });

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

    await tester.ensureVisible(find.text('Use reusable containers'));
    await tester.tap(find.text('Use reusable containers'));
    await tester.pumpAndSettle();

    expect(repository.savedSubstepIds, ['step_1']);
    expect(repository.savedPoints, 30);

    await tester.tap(find.text('Leave Challenge'));
    await tester.pumpAndSettle();

    expect(repository.deletedChallengeId, 'challenge_001');
  });
}
