import 'package:cloud_firestore/cloud_firestore.dart';

class IssueModel {
  final String? id;
  final String userId;
  final String category;
  final String title;
  final String description;
  final String priority;
  final String? imageUrl;
  final double latitude;
  final double longitude;
  final String status;
  final String? address;
  final String? assigneeName;
  final DateTime? deadline;
  final String? specialInstructions;
  final DateTime createdAt;

  IssueModel({
    this.id,
    required this.userId,
    required this.category,
    required this.title,
    required this.description,
    required this.priority,
    this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.address,
    this.assigneeName,
    this.deadline,
    this.specialInstructions,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'category': category,
      'title': title,
      'description': description,
      'priority': priority,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'address': address,
      'assigneeName': assigneeName,
      'deadline': deadline,
      'specialInstructions': specialInstructions,
      'createdAt': createdAt,
    };
  }

  factory IssueModel.fromMap(Map<String, dynamic> map, String documentId) {
    return IssueModel(
      id: documentId,
      userId: map['userId'] ?? '',
      category: map['category'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      priority: map['priority'] ?? 'Medium',
      imageUrl: map['imageUrl'],
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      status: map['status'] ?? 'Pending',
      address: map['address'],
      assigneeName: map['assigneeName'],
      deadline: map['deadline'] is Timestamp
          ? (map['deadline'] as Timestamp).toDate()
          : map['deadline'] is DateTime
          ? map['deadline'] as DateTime
          : map['deadline'] is String
          ? DateTime.tryParse(map['deadline'] as String)
          : null,
      specialInstructions: map['specialInstructions'] ?? map['instructions'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : map['createdAt'] is DateTime
          ? map['createdAt'] as DateTime
          : map['createdAt'] is String
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
