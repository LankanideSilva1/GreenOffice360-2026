import 'package:hive_flutter/hive_flutter.dart';

class LocalDatabaseService {
  static const String issuesBox = 'issues';
  static const String offlineIssuesBox = 'offline_issues';
  static const String syncQueueBox = 'sync_queue';
  static const String usersBox = 'users';
  static const String settingsBox = 'settings';

  Future<void> initialize() async {
    await Hive.initFlutter();

    await _openBox(issuesBox);
    await _openBox(offlineIssuesBox);
    await _openBox(syncQueueBox);
    await _openBox(usersBox);
    await _openBox(settingsBox);
  }

  Future<void> _openBox(String boxName) async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
  }

  Box getIssuesBox() {
    return Hive.box(issuesBox);
  }

  Box getSyncQueueBox() {
    return Hive.box(syncQueueBox);
  }

  Box getUsersBox() {
    return Hive.box(usersBox);
  }

  Box getSettingsBox() {
    return Hive.box(settingsBox);
  }
}