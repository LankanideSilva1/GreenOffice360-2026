import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/issue_model.dart';
import '../services/cloudinary_service.dart';

class IssueRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService;

  IssueRepository({
    required CloudinaryService? cloudinaryService,
  })  : _cloudinaryService =
            cloudinaryService ?? CloudinaryService();

  Future<IssueModel> createIssue({
    required IssueModel issue,
    File? image,
  }) async {
    try {
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
}