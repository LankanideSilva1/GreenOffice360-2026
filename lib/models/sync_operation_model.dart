class SyncOperationModel {
  final String id;

  final String feature;

  final String operation;

  final Map<String, dynamic> data;

  final DateTime createdAt;

  SyncOperationModel({
    required this.id,
    required this.feature,
    required this.operation,
    required this.data,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'feature': feature,
      'operation': operation,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SyncOperationModel.fromMap(
    Map<dynamic, dynamic> map,
  ) {
    return SyncOperationModel(
      id: map['id'],
      feature: map['feature'],
      operation: map['operation'],
      data: Map<String, dynamic>.from(map['data']),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}