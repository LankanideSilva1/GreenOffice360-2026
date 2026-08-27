import 'package:hive_flutter/hive_flutter.dart';

import '../../models/issue_model.dart';
import '../../services/local_database_service.dart';

class OfflineIssueRepository {
  static const String _boxName = LocalDatabaseService.offlineIssuesBox;

  /// Initialize Hive and open the offline issues box.
  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<Map>(_boxName);
    }
  }

  /// Get the Hive box.
  Future<Box<Map>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<Map>(_boxName);
    }

    return Hive.box<Map>(_boxName);
  }

  /// Save an issue locally.
  Future<void> saveIssue({
    required IssueModel issue,
    String? localImagePath,
  }) async {
    final box = await _getBox();
    final issueData = issue.toMap()
      ..['id'] = issue.id
      ..['syncStatus'] = 'pending'
      ..['localImagePath'] = localImagePath;
    await box.put(issue.id, issueData);
  }

  /// Get all offline issues.
  Future<List<Map<String, dynamic>>> getAllIssues() async {
    final box = await _getBox();

    return box.values
        .map(
          (issue) => Map<String, dynamic>.from(issue),
        )
        .toList();
  }

  /// Get issues waiting to be synchronized.
  Future<List<Map<String, dynamic>>> getPendingIssues() async {
    final issues = await getAllIssues();

    return issues
        .where((issue) => issue['syncStatus'] == 'pending')
        .toList();
  }

  /// Change the synchronization status.
  Future<void> updateSyncStatus(
    String issueId,
    String status,
  ) async {
    final box = await _getBox();

    final issue = box.get(issueId);

    if (issue != null) {
      final updatedIssue = Map<String, dynamic>.from(issue);

      updatedIssue['syncStatus'] = status;

      await box.put(issueId, updatedIssue);
    }
  }

  /// Mark an issue as synchronized.
  Future<void> markAsSynced(String issueId) async {
    await updateSyncStatus(issueId, 'synced');
  }

  /// Delete a synchronized issue.
  Future<void> deleteIssue(String issueId) async {
    final box = await _getBox();

    await box.delete(issueId);
  }

  /// Get the number of pending issues.
  Future<int> getPendingCount() async {
    final pendingIssues = await getPendingIssues();

    return pendingIssues.length;
  }
}