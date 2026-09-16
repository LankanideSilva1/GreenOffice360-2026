import 'package:cloud_firestore/cloud_firestore.dart';

class RewardRedemptionModel {
  const RewardRedemptionModel({
    required this.id,
    required this.userId,
    required this.rewardId,
    required this.rewardName,
    required this.pointsUsed,
    required this.status,
    required this.redeemedAt,
  });

  final String id;
  final String userId;
  final String rewardId;
  final String rewardName;
  final int pointsUsed;
  final String status;
  final DateTime redeemedAt;

  factory RewardRedemptionModel.fromMap(Map<String, dynamic> data, {String? docId}) {
    DateTime parsedDate;
    if (data['redeemedAt'] is String) {
      parsedDate = DateTime.tryParse(data['redeemedAt'] as String) ?? DateTime.now();
    } else if (data['redeemedAt'] is Timestamp) {
      parsedDate = (data['redeemedAt'] as Timestamp).toDate();
    } else {
      parsedDate = DateTime.now();
    }

    return RewardRedemptionModel(
      id: docId ?? (data['id'] as String? ?? ''),
      userId: data['userId'] as String? ?? '',
      rewardId: data['rewardId'] as String? ?? '',
      rewardName: data['rewardName'] as String? ?? '',
      pointsUsed: data['pointsUsed'] is num ? (data['pointsUsed'] as num).toInt() : 0,
      status: data['status'] as String? ?? 'pending',
      redeemedAt: parsedDate,
    );
  }

  factory RewardRedemptionModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return RewardRedemptionModel.fromMap(data, docId: doc.id);
  }
}
