import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../models/issue_model.dart';
import '../controllers/issue_controller.dart';

enum IssueStatus { initial, loading, success, error }

class IssueProvider extends ChangeNotifier {
  IssueProvider({required IssueController controller}) : _controller = controller;

  final IssueController _controller;
  IssueStatus _status = IssueStatus.initial;
  String? _errorMessage;
  double? _latitude;
  double? _longitude;
  IssueModel? _createdIssue;

  IssueStatus get status => _status;
  String? get errorMessage => _errorMessage;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  IssueModel? get createdIssue => _createdIssue;
  bool get isLoading => _status == IssueStatus.loading;

  Future<bool> loadCurrentLocation() async {
    _status = IssueStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final location = await _controller.getCurrentLocation();
      setLocation(latitude: location.latitude, longitude: location.longitude);
      _status = IssueStatus.initial;
      notifyListeners();
      return true;
    } catch (error) {
      _status = IssueStatus.error;
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void setLocation({required double latitude, required double longitude}) {
    _latitude = latitude;
    _longitude = longitude;
    notifyListeners();
  }

  Future<bool> saveIssue({
    required String category,
    required String title,
    required String description,
    required String priority,
    File? image,
  }) async {
    if ((_latitude == null || _longitude == null) &&
      !await loadCurrentLocation()) return false;

    _status = IssueStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _createdIssue = await _controller.createIssue(
        category: category,
        title: title,
        description: description,
        latitude: _latitude!,
        longitude: _longitude!,
        status: 'Pending',
        priority: priority,
        image: image,
      );
      _status = IssueStatus.success;
      notifyListeners();
      return true;
    } catch (error) {
      _status = IssueStatus.error;
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    if (_status == IssueStatus.error) _status = IssueStatus.initial;
    notifyListeners();
  }
}