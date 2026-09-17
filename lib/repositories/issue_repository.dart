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
    } catch (_) {
      // No connection and no Firestore cache: work purely from Hive.
      return _getCachedIssues();
    }
  }

  Future<List<IssueModel>> _getCachedIssues() async {
    final cachedIssues = await _offlineIssueRepository.getAllIssues();

    return cachedIssues
        .where((data) => data['id'] is String)
        .map((data) => IssueModel.fromMap(data, data['id'] as String))
        .toList()
      ..sort((first, second) => second.createdAt.compareTo(first.createdAt));
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

      // Write-through: cache the issue locally (pending) before pushing.
      final pendingIssue = IssueModel(
        id: document.id,
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
      await _offlineIssueRepository.saveIssue(
        issue: pendingIssue,
        localImagePath: image?.path,
      );

      try {
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

        await _firestore.runTransaction((transaction) async {
          final userReference = _firestore.collection('users').doc(issue.userId);
          final userSnapshot = await transaction.get(userReference);
          final userData = userSnapshot.data() ?? const <String, dynamic>{};
          transaction.set(document, {
            ...savedIssue.toMap(),
            'greenScoreAwards': {'reported': true},
          });
          transaction.update(userReference, {
            'greenScore': _toInt(userData['greenScore']) + 10,
            'points': _toInt(userData['points']) + 10,
          });
        });

        // Push succeeded: refresh the cache entry and mark it synced.
        await _offlineIssueRepository.cacheIssue(savedIssue);
        await _offlineIssueRepository.markAsSynced(document.id);

        return savedIssue;
      } catch (_) {
        // Push failed: keep the cached copy and queue it for the next sync.
        await _queueIssueCreate(pendingIssue, localImagePath: image?.path);
        return pendingIssue;
      }
    } catch (e) {
      throw Exception('Failed to create issue: $e');
    }
  }

  Future<void> updateIssueStatus({
    required String issueId,
    required String status,
  }) async {
    try {
      // Write-through: update the local cache first.
      await _offlineIssueRepository.updateIssueFields(issueId, {
        'status': status,
      });

      final hasInternet = await _connectivityService.hasInternetConnection();
      if (!hasInternet) {
        await _queueIssueUpdate(issueId, {'status': status});
        return;
      }

      try {
        final issueReference = _firestore.collection('issues').doc(issueId);
        await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(issueReference);
        final data = snapshot.data() ?? const <String, dynamic>{};
        final currentStatus = (data['status'] as String? ?? '').toLowerCase();
        final normalizedStatus = status.toLowerCase();
        final userId = data['userId'] as String?;
        final userReference = userId == null || userId.isEmpty
            ? null
            : _firestore.collection('users').doc(userId);
        final userSnapshot = userReference == null
            ? null
            : await transaction.get(userReference);
        final userData = userSnapshot?.data() ?? const <String, dynamic>{};
        final awards = Map<String, dynamic>.from(
          (data['greenScoreAwards'] as Map?) ?? const {},
        );
        final awardKey = _issueAwardKey(normalizedStatus);
        final awardPoints = _issueAwardPoints(normalizedStatus);
        final shouldAward =
            awardKey != null &&
            awardPoints > 0 &&
            currentStatus != normalizedStatus &&
            awards[awardKey] != true;

        final updates = <String, dynamic>{
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (shouldAward && awardKey != null) {
          awards[awardKey] = true;
          updates['greenScoreAwards'] = awards;
        }
        transaction.update(issueReference, updates);
        if (shouldAward && userReference != null) {
          transaction.update(userReference, {
            'greenScore': _toInt(userData['greenScore']) + awardPoints,
            'points': _toInt(userData['points']) + awardPoints,
          });
        }
        });
        await _offlineIssueRepository.markAsSynced(issueId);
      } catch (_) {
        // Push failed: queue the status change for the next sync.
        await _queueIssueUpdate(issueId, {'status': status});
      }
    } catch (e) {
      throw Exception('Failed to update issue status: $e');
    }
  }

  /// Queue a new issue so only newly created data syncs when the
  /// connection returns.
  Future<void> _queueIssueCreate(
    IssueModel issue, {
    String? localImagePath,
  }) async {
    await _syncQueueRepository.addOperation(
      SyncOperationModel(
        id: issue.id!,
        feature: 'issue',
        operation: 'create',
        data: {
          ...issue.toMap(),
          'id': issue.id,
          'localImagePath': localImagePath,
        },
        createdAt: issue.createdAt,
      ),
    );
  }

  /// Queue a field update. The operation id is distinct from create and
  /// assignment operations so pending changes never overwrite each other.
  Future<void> _queueIssueUpdate(
    String issueId,
    Map<String, dynamic> fields,
  ) async {
    await _syncQueueRepository.addOperation(
      SyncOperationModel(
        id: 'update_$issueId',
        feature: 'issue',
        operation: 'update',
        data: {'id': issueId, ...fields},
        createdAt: DateTime.now(),
      ),
    );
  }

  String? _issueAwardKey(String status) {
    if (status == 'verified') return 'verified';
    if (status == 'resolved') return 'resolved';
    return null;
  }

  int _issueAwardPoints(String status) {
    if (status == 'verified') return 5;
    if (status == 'resolved') return 20;
    return 0;
  }

  int _toInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
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

      // Write-through: update the local cache first.
      await _offlineIssueRepository.updateIssueFields(
        issueId,
        assignmentData,
      );

      final hasInternet = await _connectivityService.hasInternetConnection();

      if (hasInternet) {
        final data = <String, dynamic>{
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

        try {
          await _firestore.collection('issues').doc(issueId).update(data);
          await _offlineIssueRepository.markAsSynced(issueId);
          return;
        } catch (_) {
          // Fall through and queue the assignment for the next sync.
        }
      }

      await _syncQueueRepository.addOperation(
        SyncOperationModel(
          id: 'assignment_$issueId',
          feature: 'issue',
          operation: 'update',
          data: {'id': issueId, ...assignmentData},
          createdAt: DateTime.now(),
        ),
      );
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

    await _queueIssueCreate(offlineIssue, localImagePath: localImagePath);

    return offlineIssue;
  }
}
