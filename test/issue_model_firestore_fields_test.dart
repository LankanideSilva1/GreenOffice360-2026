import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenoffice360/models/issue_model.dart';

void main() {
  test('IssueModel parses assignee and address from Firestore data', () {
    final issue = IssueModel.fromMap({
      'userId': 'user_123',
      'category': 'Plumbing',
      'title': 'Water leakage',
      'description': 'Leak in basement',
      'priority': 'High',
      'imageUrl': 'https://example.com/issue.jpg',
      'latitude': 12.3456,
      'longitude': 78.9012,
      'status': 'In Progress',
      'assigneeName': 'Maria Gonzales',
      'address': 'Building A, Floor 2',
      'createdAt': Timestamp.fromDate(DateTime(2026, 8, 18, 10, 30)),
    }, 'issue_1');

    expect(issue.imageUrl, 'https://example.com/issue.jpg');
    expect(issue.assigneeName, 'Maria Gonzales');
    expect(issue.address, 'Building A, Floor 2');
  });
}
