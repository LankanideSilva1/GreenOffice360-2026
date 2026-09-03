import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../models/issue_model.dart';
import '../../../models/user_model.dart';
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
  final List<IssueModel> _issues = [];
  UserModel? _reporter;
  final List<UserModel> _employees = [];

  IssueStatus get status => _status;
  String? get errorMessage => _errorMessage;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  IssueModel? get createdIssue => _createdIssue;
  List<IssueModel> get issues => _issues;
  UserModel? get reporter => _reporter;
  List<UserModel> get employees => _employees;
  bool get isLoading => _status == IssueStatus.loading;

  Future<void> loadIssues() async {
    _status = IssueStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _issues.clear();
      _issues.addAll(await _controller.getIssues());
      _status = IssueStatus.success;
      notifyListeners();
    } catch (error) {
      _status = IssueStatus.error;
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<UserModel?> getReporter(String uid) async {
    try {
      _reporter = await _controller.getUserProfile(uid);
      notifyListeners();
      return _reporter;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<List<UserModel>> getAvailableEmployees(String issueCreatorId) async {
    try {
      _employees.clear();
      _employees.addAll(await _controller.getAvailableEmployees(issueCreatorId));
      notifyListeners();
      return _employees;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return const [];
    }
  }

  void _syncIssueInList({
    required String issueId,
    String? status,
    String? priority,
    String? assigneeName,
    DateTime? deadline,
    String? specialInstructions,
  }) {
    final index = _issues.indexWhere((issue) => issue.id == issueId);
    if (index == -1) return;

    final currentIssue = _issues[index];
    _issues[index] = IssueModel(
      id: currentIssue.id,
      userId: currentIssue.userId,
      category: currentIssue.category,
      title: currentIssue.title,
      description: currentIssue.description,
      priority: priority ?? currentIssue.priority,
      imageUrl: currentIssue.imageUrl,
      latitude: currentIssue.latitude,
      longitude: currentIssue.longitude,
      status: status ?? currentIssue.status,
      address: currentIssue.address,
      assigneeName: assigneeName ?? currentIssue.assigneeName,
      deadline: deadline ?? currentIssue.deadline,
      specialInstructions: specialInstructions ?? currentIssue.specialInstructions,
      createdAt: currentIssue.createdAt,
    );
  }

  Future<void> updateIssueStatus({
    required String issueId,
    required String status,
  }) async {
    _status = IssueStatus.loading;
    notifyListeners();

    try {
      await _controller.updateIssueStatus(issueId: issueId, status: status);
      _syncIssueInList(issueId: issueId, status: status);
      _status = IssueStatus.success;
      notifyListeners();
    } catch (error) {
      _status = IssueStatus.error;
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> assignIssue({
    required String issueId,
    required String assigneeName,
    required String priority,
    required String status,
    DateTime? deadline,
    String? specialInstructions,
  }) async {
    _status = IssueStatus.loading;
    notifyListeners();

    try {
      await _controller.assignIssue(
        issueId: issueId,
        assigneeName: assigneeName,
        priority: priority,
        status: status,
        deadline: deadline,
        specialInstructions: specialInstructions,
      );
      _syncIssueInList(
        issueId: issueId,
        status: status,
        priority: priority,
        assigneeName: assigneeName,
        deadline: deadline,
        specialInstructions: specialInstructions,
      );
      _status = IssueStatus.success;
      notifyListeners();
    } catch (error) {
      _status = IssueStatus.error;
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

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