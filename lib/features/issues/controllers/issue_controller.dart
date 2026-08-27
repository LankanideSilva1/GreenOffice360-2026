import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import '../../../models/issue_model.dart';
import '../../../repositories/issue_repository.dart';
import '../../../services/location_service.dart';

class IssueController {
  IssueController({
    required IssueRepository repository,
    LocationService? locationService,
  })  : _repository = repository,
      _locationService = locationService ?? LocationService();

  final IssueRepository _repository;
  final LocationService _locationService;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<Position> getCurrentLocation() {
    return _locationService.getCurrentLocation();
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