import 'package:cloud_firestore/cloud_firestore.dart';

class ChallengeSubstep {
  const ChallengeSubstep({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
  });

  final String id;
  final String title;
  final String description;
  final int points;

  factory ChallengeSubstep.fromMap(Map<String, dynamic> data) {
    return ChallengeSubstep(
      id: data['id'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      points: _toInt(data['points']),
    );
  }
}

class ChallengeModel {
  const ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.points,
    required this.durationDays,
    required this.isActive,
    required this.substeps,
    this.startDate,
    this.endDate,
    this.participantCount = 0,
    this.joinedByUser = false,
    this.progress = 0,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final int points;
  final int durationDays;
  final bool isActive;
  final List<ChallengeSubstep> substeps;
  final DateTime? startDate;
  final DateTime? endDate;
  final int participantCount;
  final bool joinedByUser;
  final double progress;

  factory ChallengeModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document, {
    bool joinedByUser = false,
    int participantCount = 0,
    double progress = 0,
  }) {
    final data = document.data() ?? const <String, dynamic>{};
    final rawSubsteps = data['substeps'];
    final substeps = rawSubsteps is List
        ? rawSubsteps
              .whereType<Map>()
              .map(
                (item) =>
                    ChallengeSubstep.fromMap(Map<String, dynamic>.from(item)),
              )
              .toList()
        : <ChallengeSubstep>[];

    return ChallengeModel(
      id: document.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? '',
      difficulty: data['difficulty'] as String? ?? '',
      points: _toInt(data['points']),
      durationDays: _toInt(data['durationDays']),
      isActive: data['isActive'] as bool? ?? true,
      substeps: substeps,
      startDate: _toDate(data['startDate']),
      endDate: _toDate(data['endDate']),
      joinedByUser: joinedByUser,
      participantCount: participantCount,
      progress: progress,
    );
  }

  String get durationLabel => '$durationDays days';
  String get pointsLabel => '$points pts';
  String get joinedLabel => '$participantCount joined';
  String get statusLabel => isActive ? 'ACTIVE' : 'UPCOMING';
}

int _toInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _toDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
