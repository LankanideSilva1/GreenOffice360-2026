import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RewardModel {
  const RewardModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.requiredPoints,
    required this.icon,
    required this.isActive,
    this.stock,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final int requiredPoints;
  final String icon;
  final bool isActive;
  final int? stock;

  factory RewardModel.fromMap(Map<String, dynamic> data, {String? docId}) {
    return RewardModel(
      id: (data['id'] as String?) ?? docId ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? '',
      requiredPoints: _toInt(data['requiredPoints']),
      icon: data['icon'] as String? ?? '',
      isActive: data['active'] as bool? ?? true,
      stock: data['stock'] is int ? data['stock'] as int : null,
    );
  }

  factory RewardModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return RewardModel.fromMap(data, docId: doc.id);
  }

  RewardModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    int? requiredPoints,
    String? icon,
    bool? isActive,
    int? stock,
  }) {
    return RewardModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      requiredPoints: requiredPoints ?? this.requiredPoints,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      stock: stock ?? this.stock,
    );
  }

  String get pointsLabel => '$requiredPoints pts';

  String get availabilityLabel {
    if (stock == null) return 'In Stock';
    if (stock == 0) return 'Out of stock';
    if (stock == 1) return '1 left';
    return '$stock left';
  }

  IconData get iconData {
    switch (icon) {
      case 'workspace_premium':
        return Icons.workspace_premium_rounded;
      case 'local_cafe':
        return Icons.local_cafe_rounded;
      case 'card_giftcard':
        return Icons.card_giftcard_rounded;
      case 'checkroom':
        return Icons.checkroom_rounded;
      case 'timelapse':
        return Icons.timelapse_rounded;
      default:
        return Icons.card_giftcard_rounded;
    }
  }
}

int _toInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
