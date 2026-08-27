import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:greenoffice360/repositories/offline/offline_issue_repository.dart';
import 'package:greenoffice360/services/connectivity_service.dart';

import '../models/issue_model.dart';
import '../models/sync_operation_model.dart';
import '../services/cloudinary_service.dart';
import 'offline/sync_queue_repository.dart';

class IssueRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService;
  final ConnectivityService _connectivityService = ConnectivityService();
  final OfflineIssueRepository _offlineIssueRepository = OfflineIssueRepository();
  final SyncQueueRepository _syncQueueRepository;

  IssueRepository({
    CloudinaryService? cloudinaryService,
    SyncQueueRepository? syncQueueRepository,
  })  : _cloudinaryService = cloudinaryService ?? CloudinaryService(),
        _syncQueueRepository = syncQueueRepository ?? SyncQueueRepository();
        

  Future<IssueModel> createIssue({
    required IssueModel issue,
    File? image,
  }) async {
    try {
      final hasInternet = await _connectivityService.hasInternetConnection();

      if (!hasInternet) {
        return await _createIssueOffline(
          issue: issue,
          image: image,
        );
      }
      
      // Create Firestore document ID first
      final document = _firestore.collection('issues').doc();

      String? imageUrl = issue.imageUrl;

      // Upload image to Cloudinary
      if (image != null) {
        imageUrl = await _cloudinaryService.uploadIssueImage(image: image, issueId: document.id, userId: issue.userId);
      }

      // Create final issue object
      final savedIssue = IssueModel(
        id: document.id,
        userId: issue.userId,
        category: issue.category,
        title: issue.title,
        description: issue.description,
        priority: issue.priority,
        imageUrl: imageUrl,
        latitude: issue.latitude,
        longitude: issue.longitude,
        status: issue.status,
        createdAt: issue.createdAt,
      );

      // Save issue details + Cloudinary URL
      await document.set(
        savedIssue.toMap(),
      );

      return savedIssue;
    } catch (e) {
      throw Exception(
        'Failed to create issue: $e',
      );
    }
  }

  Future<IssueModel> _createIssueOffline({
    required IssueModel issue,
    File? image,
  }) async {
    // Generate a local ID.
    final localId = 'offline_${DateTime.now().millisecondsSinceEpoch}';

    final localImagePath = image?.path;

    final offlineIssue = IssueModel(
      id: localId,
      userId: issue.userId,
      category: issue.category,
      title: issue.title,
      description: issue.description,
      priority: issue.priority,
      imageUrl: null,
      latitude: issue.latitude,
      longitude: issue.longitude,
      status: issue.status,
      createdAt: issue.createdAt,
    );

    // Save issue to local database.
    await _offlineIssueRepository.saveIssue(
      issue: offlineIssue,
      localImagePath: localImagePath,
    );

    await _syncQueueRepository.addOperation(
      SyncOperationModel(
        id: localId,
        feature: 'issue',
        operation: 'create',
        data: {
          ...offlineIssue.toMap(),
          'id': localId,
          'localImagePath': localImagePath,
        },
        createdAt: offlineIssue.createdAt,
      ),
    );

    return offlineIssue;
  }
}