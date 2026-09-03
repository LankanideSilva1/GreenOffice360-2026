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
  final ConnectivityService _connectivityService;
  final OfflineIssueRepository _offlineIssueRepository =
      OfflineIssueRepository();
  final SyncQueueRepository _syncQueueRepository;

  IssueRepository({
    CloudinaryService? cloudinaryService,
    ConnectivityService? connectivityService,
    SyncQueueRepository? syncQueueRepository,
  }) : _cloudinaryService = cloudinaryService ?? CloudinaryService(),
       _connectivityService = connectivityService ?? ConnectivityService(),
       _syncQueueRepository = syncQueueRepository ?? SyncQueueRepository();

  Future<List<IssueModel>> getIssues() async {
    try {
      final query = _firestore
          .collection('issues')
          .orderBy('createdAt', descending: true);
      QuerySnapshot<Map<String, dynamic>> snapshot;

      try {
        snapshot = await query.get();
      } catch (_) {
        snapshot = await query.get(const GetOptions(source: Source.cache));
      }

      final fetchedIssues = snapshot.docs
          .map((doc) => IssueModel.fromMap(doc.data(), doc.id))
          .toList();
      final cachedIssues = await _offlineIssueRepository.getAllIssues();
      final cachedById = <String, IssueModel>{
        for (final issueData in cachedIssues)
          if (issueData['id'] is String)
            issueData['id'] as String: IssueModel.fromMap(
              issueData,
              issueData['id'] as String,
            ),
      };

      for (final issue in fetchedIssues) {
        final cachedIssue = cachedById[issue.id];
        final cachedData = cachedIssues.firstWhere(
          (data) => data['id'] == issue.id,
          orElse: () => const <String, dynamic>{},
        );
        if (cachedIssue != null && cachedData['syncStatus'] == 'pending') {
          continue;
        }
        await _offlineIssueRepository.cacheIssue(issue);
      }

      final mergedIssues = <String, IssueModel>{
        for (final issue in fetchedIssues) issue.id!: issue,
      };
      mergedIssues.addAll(cachedById);

      return mergedIssues.values.toList()
        ..sort((first, second) => second.createdAt.compareTo(first.createdAt));
    } catch (e) {
      throw Exception('Failed to load issues: $e');
    }
  }

  Future<IssueModel> createIssue({
    required IssueModel issue,
    File? image,
  }) async {
    try {
      final hasInternet = await _connectivityService.hasInternetConnection();

      if (!hasInternet) {
        return await _createIssueOffline(issue: issue, image: image);
      }

      // Create Firestore document ID first
      final document = _firestore.collection('issues').doc();

      String? imageUrl = issue.imageUrl;

      // Upload image to Cloudinary
      if (image != null) {
        imageUrl = await _cloudinaryService.uploadIssueImage(
          image: image,
          issueId: document.id,
          userId: issue.userId,
        );
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
      await document.set(savedIssue.toMap());

      return savedIssue;
    } catch (e) {
      throw Exception('Failed to create issue: $e');
    }
  }

  Future<void> updateIssueStatus({
    required String issueId,
    required String status,
  }) async {
    try {
      await _firestore.collection('issues').doc(issueId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update issue status: $e');
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
    try {
      final hasInternet = await _connectivityService.hasInternetConnection();
      final assignmentData = <String, dynamic>{
        'assigneeName': assigneeName,
        'priority': priority,
        'status': status,
        'updatedAt': DateTime.now(),
      };

      if (deadline != null) {
        assignmentData['deadline'] = deadline;
      }

      if (specialInstructions != null) {
        assignmentData['specialInstructions'] = specialInstructions;
      }

      if (!hasInternet) {
        await _offlineIssueRepository.updateIssueFields(
          issueId,
          assignmentData,
        );
        await _syncQueueRepository.addOperation(
          SyncOperationModel(
            id: issueId.startsWith('offline_')
                ? 'assignment_$issueId'
                : issueId,
            feature: 'issue',
            operation: 'update',
            data: {'id': issueId, ...assignmentData},
            createdAt: DateTime.now(),
          ),
        );
        return;
      }

      final data = {
        'assigneeName': assigneeName,
        'priority': priority,
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (deadline != null) {
        data['deadline'] = Timestamp.fromDate(deadline);
      }

      if (specialInstructions != null) {
        data['specialInstructions'] = specialInstructions;
      }

      await _firestore.collection('issues').doc(issueId).update(data);
    } catch (e) {
      throw Exception('Failed to assign issue: $e');
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
