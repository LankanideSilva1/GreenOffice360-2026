import 'package:flutter/material.dart';
import 'package:greenoffice360/core/constants/app_colors.dart';
import 'package:greenoffice360/features/auth/providers/auth_provider.dart';
import 'package:greenoffice360/features/gamification/providers/reward_provider.dart';
import 'package:greenoffice360/features/gamification/screens/rewards_redeem_screen.dart';
import 'package:greenoffice360/models/reward_model.dart';
import 'package:provider/provider.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final userId = context.read<AuthProvider>().user?.uid;
        context.read<RewardProvider>().loadRewards(userId: userId);
      }
    });
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Redeemed just now';
    if (diff.inMinutes < 60) return 'Redeemed ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Redeemed ${diff.inHours}h ago';
    if (diff.inDays < 7) return 'Redeemed ${diff.inDays}d ago';
    return 'Redeemed ${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthProvider>().user;
    final rewardProvider = context.watch<RewardProvider>();
    final rewards = rewardProvider.rewards
        .where((reward) => reward.isActive)
        .toList();
    final availableBalance = authUser?.points ?? 0;

    final List<_RedemptionItem> recentRedemptions = rewardProvider.redemptions.isNotEmpty
        ? rewardProvider.redemptions.map((r) {
            return _RedemptionItem(
              title: r.rewardName,
              description: _formatTimeAgo(r.redeemedAt),
              value: '-${r.pointsUsed} pts',
            );
          }).toList()
        : const [];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F3),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Rewards',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F8A6E),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Available Balance',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$availableBalance pts',
                            style: const TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.05,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFD25B),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Available Rewards',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: rewardProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : rewardProvider.status == RewardStatus.error
                        ? Center(
                            child: Text(
                              rewardProvider.errorMessage ?? 'Unable to load rewards',
                            ),
                          )
                        : rewards.isEmpty
                            ? const Center(
                                child: Text(
                                  'No rewards available right now.',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  children: [
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: rewards.length,
                                      padding: EdgeInsets.zero,
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        childAspectRatio: 0.82,
                                      ),
                                      itemBuilder: (context, index) {
                                        return _RewardCard(
                                          reward: rewards[index],
                                          userPoints: availableBalance,
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 22),
                                    const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Recently Redeemed',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        children: List.generate(
                                          recentRedemptions.length,
                                          (index) {
                                            final item = recentRedemptions[index];
                                            final isLast =
                                                index == recentRedemptions.length - 1;

                                            return Column(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        width: 30,
                                                        height: 30,
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFF3F1EE),
                                                          borderRadius:
                                                              BorderRadius.circular(10),
                                                        ),
                                                        child: Center(
                                                          child: Text(
                                                            item.title.contains('Coffee')
                                                                ? '☕'
                                                                : '⏱️',
                                                            style: const TextStyle(
                                                                fontSize: 16),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              item.title,
                                                              style: const TextStyle(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight.w600,
                                                                color:
                                                                    AppColors.textDark,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 2),
                                                            Text(
                                                              item.description,
                                                              style: const TextStyle(
                                                                fontSize: 12,
                                                                color: AppColors
                                                                    .textSecondary,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Text(
                                                        item.value,
                                                        style: const TextStyle(
                                                          fontSize: 15,
                                                          fontWeight: FontWeight.w700,
                                                          color: AppColors.textDark,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (!isLast)
                                                  const Divider(
                                                    height: 1,
                                                    thickness: 1,
                                                    color: Color(0xFFE7E5E4),
                                                  ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.reward,
    required this.userPoints,
  });

  final RewardModel reward;
  final int userPoints;

  void _showRedeemConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F1EE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Image.network(
                    reward.icon,
                    width: 44,
                    height: 44,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        reward.iconData,
                        size: 36,
                        color: AppColors.textDark,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                reward.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                reward.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F6ED),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${reward.requiredPoints} pts',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F8A6E),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Would you like to redeem this reward?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textDark,
                      side: const BorderSide(color: Color(0xFFDAD5D1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      final authProvider = context.read<AuthProvider>();
                      final rewardProvider = context.read<RewardProvider>();
                      final userId = authProvider.user?.uid ?? '';

                      await authProvider.deductPoints(reward.requiredPoints);
                      await rewardProvider.redeemReward(
                        userId: userId,
                        reward: reward,
                      );

                      final remaining =
                          authProvider.user?.points ?? (userPoints - reward.requiredPoints);
                      final redemptionId =
                          '#RWD-${DateTime.now().year}-${(1000 + (reward.name.hashCode % 8999)).abs()}';

                      if (context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RewardsRedeemScreen(
                              rewardName: reward.name,
                              redemptionId: redemptionId,
                              pointsUsed: reward.requiredPoints,
                              remainingBalance: remaining,
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F8A6E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Redeem',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canRedeem = userPoints >= reward.requiredPoints &&
        (reward.stock == null || reward.stock! > 0);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F1EE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Image.network(
                reward.icon,
                width: 32,
                height: 32,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.card_giftcard,
                    size: 32,
                    color: AppColors.textDark,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            reward.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Flexible(
                child: Text(
                  reward.pointsLabel,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: Icon(
                  Icons.circle,
                  size: 4,
                  color: AppColors.textSecondary,
                ),
              ),
              Flexible(
                child: Text(
                  reward.availabilityLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          if (canRedeem)
            SizedBox(
              height: 38,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showRedeemConfirmationDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F8A6E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'Redeem',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 38),
        ],
      ),
    );
  }
}

class _RedemptionItem {
  const _RedemptionItem({
    required this.title,
    required this.description,
    required this.value,
  });

  final String title;
  final String description;
  final String value;
}