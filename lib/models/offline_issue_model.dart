class OfflineIssueModel {
  final String localId;
  final String title;
  final String description;
  final String category;
  final String location;
  final String imagePath;
  final String employeeId;

  final bool isSynced;

  final DateTime createdAt;

  OfflineIssueModel({
    required this.localId,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.imagePath,
    required this.employeeId,
    required this.isSynced,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'localId': localId,
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'imagePath': imagePath,
      'employeeId': employeeId,
      'isSynced': isSynced,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory OfflineIssueModel.fromMap(Map<String, dynamic> map) {
    return OfflineIssueModel(
      localId: map['localId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      location: map['location'] ?? '',
      imagePath: map['imagePath'] ?? '',
      employeeId: map['employeeId'] ?? '',
      isSynced: map['isSynced'] ?? false,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}