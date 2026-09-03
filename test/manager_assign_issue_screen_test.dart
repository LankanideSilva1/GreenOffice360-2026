import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:greenoffice360/features/issues/controllers/issue_controller.dart';
import 'package:greenoffice360/features/issues/providers/issue_provider.dart';
import 'package:greenoffice360/features/manager/screens/manager_assign_issue.dart';
import 'package:greenoffice360/models/issue_model.dart';
import 'package:greenoffice360/models/user_model.dart';
import 'package:greenoffice360/repositories/issue_repository.dart';

class _FakeIssueController extends IssueController {
  _FakeIssueController() : super(repository: IssueRepository());

  @override
  Future<List<UserModel>> getAvailableEmployees(String issueCreatorId) async {
    return [
      UserModel(
        uid: 'emp_1',
        name: 'Carlos Rivera',
        email: 'carlos@example.com',
        employeeId: 'EMP-001',
        department: 'Operations',
        role: 'Employee',
        greenScore: 0,
        points: 0,
      ),
      UserModel(
        uid: 'emp_2',
        name: 'Maya Patel',
        email: 'maya@example.com',
        employeeId: 'EMP-002',
        department: 'Maintenance',
        role: 'Technician',
        greenScore: 0,
        points: 0,
      ),
    ];
  }
}

class _IssueProviderUpdateController extends IssueController {
  _IssueProviderUpdateController() : super(repository: IssueRepository());

  @override
  Future<List<IssueModel>> getIssues() async {
    return [
      IssueModel(
        id: 'issue_123',
        userId: 'user_1',
        category: 'Plumbing',
        title: 'Leak',
        description: 'desc',
        priority: 'High',
        latitude: 0,
        longitude: 0,
        status: 'Pending',
        createdAt: DateTime(2026, 8, 25),
      ),
    ];
  }

  @override
  Future<void> assignIssue({
    required String issueId,
    required String assigneeName,
    required String priority,
    required String status,
    DateTime? deadline,
    String? specialInstructions,
  }) async {}
}

void main() {
  testWidgets('Assign issue screen shows required labels and editable input fields', (tester) async {
    final issue = IssueModel(
      id: 'issue_123',
      userId: 'user_1',
      category: 'Plumbing',
      title: 'Water Leakage in Basement',
      description: 'Please inspect the corroded pipe joint in the ceiling. Bring waterproofing materials and coordinate with the electrical team for conduit safety.',
      priority: 'High',
      latitude: 0,
      longitude: 0,
      status: 'Pending',
      address: 'Office Block A',
      assigneeName: 'Carlos Rivera',
      createdAt: DateTime(2026, 8, 25),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<IssueProvider>(
        create: (_) => IssueProvider(controller: _FakeIssueController()),
        child: MaterialApp(
          home: ManagerAssignIssueScreen(issue: issue),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Assign Issue'), findsNWidgets(2));
    expect(find.text('Water Leakage in Basement'), findsOneWidget);
    expect(find.text('SELECT EMPLOYEE'), findsOneWidget);
    expect(find.text('SET PRIORITY'), findsOneWidget);
    expect(find.text('SET DEADLINE'), findsOneWidget);
    expect(find.text('SPECIAL INSTRUCTIONS'), findsOneWidget);
    expect(find.text('High'), findsWidgets);
    expect(find.byType(DropdownButtonFormField<UserModel>), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
  });

  test('Issue provider updates issue list after assignment', () async {
    final provider = IssueProvider(controller: _IssueProviderUpdateController());

    await provider.loadIssues();
    await provider.assignIssue(
      issueId: 'issue_123',
      assigneeName: 'Carlos Rivera',
      priority: 'Medium',
      status: 'Assigned',
    );

    expect(provider.issues, isNotEmpty);
    expect(provider.issues.first.status, 'Assigned');
    expect(provider.issues.first.assigneeName, 'Carlos Rivera');
    expect(provider.issues.first.priority, 'Medium');
  });
}
