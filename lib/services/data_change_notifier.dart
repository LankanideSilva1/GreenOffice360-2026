import 'package:flutter/foundation.dart';

/// Lightweight broadcast bus that tells providers when the local data has
/// changed (e.g. after a sync pushes offline changes to Firebase and
/// refreshes the Hive cache), so open screens reload and show the changes.
class DataChangeNotifier extends ChangeNotifier {
  /// Notify all listeners that cached data was updated.
  void notifyDataChanged() {
    notifyListeners();
  }
}
