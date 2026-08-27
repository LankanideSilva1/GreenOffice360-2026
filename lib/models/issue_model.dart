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
      'createdAt': createdAt,
    };
  }

  factory IssueModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
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
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }
}