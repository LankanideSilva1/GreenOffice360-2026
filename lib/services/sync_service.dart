import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../repositories/offline/offline_issue_repository.dart';
import '../repositories/offline/sync_queue_repository.dart';
import '../models/sync_operation_model.dart';
import 'cloudinary_service.dart';
import 'connectivity_service.dart';

class SyncService {
  final ConnectivityService connectivityService;
  final SyncQueueRepository syncQueueRepository;
  final OfflineIssueRepository offlineIssueRepository;
  final CloudinaryService cloudinaryService;

  bool _isSyncing = false;

  SyncService({
    required this.connectivityService,
    required this.syncQueueRepository,
    OfflineIssueRepository? offlineIssueRepository,
    CloudinaryService? cloudinaryService,
  })  : offlineIssueRepository = offlineIssueRepository ?? OfflineIssueRepository(),
        cloudinaryService = cloudinaryService ?? CloudinaryService();

  Future<void> synchronize() async {
    if (_isSyncing) return;

    final isConnected = await connectivityService.hasInternetConnection();

    if (!isConnected) return;

    _isSyncing = true;

    try {
      final operations = await syncQueueRepository.getOperations();

      for (final operation in operations) {
        try {
          await _processOperation(operation);

          await syncQueueRepository.removeOperation(
            operation.id,
          );
        } catch (error) {
          // Keep the operation in the queue.
          // It will retry later.
          // ignore: avoid_print
          print('Sync failed for ${operation.feature}/${operation.id}: $error');
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processOperation(
    SyncOperationModel operation,
  ) async {
    switch (operation.feature) {
      case 'issue':
        await _syncIssue(operation);
        break;

      case 'profile':
        await _syncProfile(operation);
        break;

      case 'settings':
        await _syncSettings(operation);
        break;

      default:
        throw FormatException(
          'Unsupported sync feature: ${operation.feature}',
        );
    }
  }

  Future<void> _syncIssue(
    SyncOperationModel operation,
  ) async {
    final userId = operation.data['userId'] as String?;
    if (userId == null || userId.isEmpty) {
      throw const FormatException('Issue sync data is missing userId.');
    }

    final issueId = operation.data['id'] as String?;
    final issueData = Map<String, dynamic>.from(operation.data)
      ..remove('id');
    final localImagePath = issueData.remove('localImagePath') as String?;

    if (localImagePath != null && localImagePath.isNotEmpty) {
      final image = File(localImagePath);
      if (await image.exists()) {
        final documentId = issueId ?? FirebaseFirestore.instance.collection('issues').doc().id;
        issueData['imageUrl'] = await cloudinaryService.uploadIssueImage(
          image: image,
          issueId: documentId,
          userId: userId,
        );
      }
    }

    if (operation.operation == 'update') {
      if (issueId == null || issueId.isEmpty) {
        throw const FormatException('Issue update is missing id.');
      }

      await FirebaseFirestore.instance
          .collection('issues')
          .doc(issueId)
          .set(issueData, SetOptions(merge: true));
        await _removeSyncedOfflineIssue(issueId);
      return;
    }

    final document = issueId == null || issueId.isEmpty
        ? FirebaseFirestore.instance.collection('issues').doc()
        : FirebaseFirestore.instance.collection('issues').doc(issueId);
    await document.set(issueData, SetOptions(merge: true));

    await _removeSyncedOfflineIssue(issueId);
  }

  Future<void> _removeSyncedOfflineIssue(String? issueId) async {
    if (issueId == null || !issueId.startsWith('offline_')) return;

    await offlineIssueRepository.markAsSynced(issueId);
    await offlineIssueRepository.deleteIssue(issueId);
  }

  Future<void> _syncProfile(
    SyncOperationModel operation,
  ) async {
    final userId = operation.data['userId'] as String?;
    if (userId == null || userId.isEmpty) {
      throw const FormatException('Profile sync data is missing userId.');
    }

    final profileData = Map<String, dynamic>.from(operation.data)
      ..remove('userId');

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .set(profileData, SetOptions(merge: true));
  }

  Future<void> _syncSettings(
    SyncOperationModel operation,
  ) async {
    // Firebase settings synchronization
  }

  void startAutoSync() {
    connectivityService.onConnectivityChanged.listen(
      (isConnected) {
        if (isConnected) {
          synchronize();
        }
      },
    );
    synchronize();
  }
}