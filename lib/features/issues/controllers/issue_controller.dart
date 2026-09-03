import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import '../../../models/issue_model.dart';
import '../../../models/user_model.dart';
import '../../../repositories/issue_repository.dart';
import '../../../repositories/user_repository.dart';
import '../../../services/location_service.dart';

class IssueController {
  IssueController({
    required IssueRepository repository,
    LocationService? locationService,
    UserRepository? userRepository,
  })  : _repository = repository,
      _locationService = locationService ?? LocationService(),
      _userRepository = userRepository ?? UserRepository();

  final IssueRepository _repository;
  final LocationService _locationService;
  final UserRepository _userRepository;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<Position> getCurrentLocation() {
    return _locationService.getCurrentLocation();
  }

  Future<List<IssueModel>> getIssues() {
    return _repository.getIssues();
  }

  Future<UserModel?> getUserProfile(String uid) {
    return _userRepository.getUserProfile(uid);
  }

  Future<List<UserModel>> getAvailableEmployees(String issueCreatorId) async {
    final users = await _userRepository.getUsers();
    return users.where((user) {
      final role = user.role.toLowerCase();
      final isAllowedRole = role == 'employee' || role == 'maintenance' || role == 'technician';
      final isIssueCreator = user.uid == issueCreatorId;
      return isAllowedRole && !isIssueCreator;
    }).toList();
  }

  Future<void> updateIssueStatus({
    required String issueId,
    required String status,
  }) {
    return _repository.updateIssueStatus(
      issueId: issueId,
      status: status,
    );
  }

  Future<void> assignIssue({
    required String issueId,
    required String assigneeName,
    required String priority,
    required String status,
    DateTime? deadline,
    String? specialInstructions,
  }) {
    return _repository.assignIssue(
      issueId: issueId,
      assigneeName: assigneeName,
      priority: priority,
      status: status,
      deadline: deadline,
      specialInstructions: specialInstructions,
    );
  }

  Future<IssueModel> createIssue({
    required String category,
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    required String status,
    required String priority,
    File? image,
  }) {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) {
      throw Exception('You must be signed in to submit an issue.');
    }

    final issue = IssueModel(
      userId: userId,
      category: category,
      title: title,
      description: description,
      priority: priority,
      latitude: latitude,
      longitude: longitude,
      status: status,
      createdAt: DateTime.now(),
    );

    return _repository.createIssue(issue: issue, image: image);
  }
}