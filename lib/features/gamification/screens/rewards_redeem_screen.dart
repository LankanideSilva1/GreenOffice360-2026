import 'package:flutter/material.dart';
import 'package:greenoffice360/core/constants/app_colors.dart';
import 'package:greenoffice360/core/routes/app_routes.dart';

class RewardsRedeemScreen extends StatelessWidget {
  const RewardsRedeemScreen({
    super.key,
    this.rewardName = 'Coffee Voucher',
    this.redemptionId = '#RWD-2026-0847',
    this.pointsUsed = 200,
    this.remainingBalance = 620,
  });

  final String rewardName;
  final String redemptionId;
  final int pointsUsed;
  final int remainingBalance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F3F1),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 18),
                  _buildSuccessIcon(),
                  const SizedBox(height: 18),
                  const Text(
                    'Reward Redeemed!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Your redemption request has been completed successfully.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        const Text(
                          'Redemption Summary',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: Color(0xFFE6E3E0), height: 1),
                        const SizedBox(height: 18),
                        _summaryRow('Reward Item', rewardName),
                        const SizedBox(height: 14),
                        _summaryRow('Redemption ID', redemptionId),
                        const SizedBox(height: 14),
                        _summaryRow('Points Used', '$pointsUsed pts'),
                        const SizedBox(height: 14),
                        _summaryRow('Remaining Balance', '$remainingBalance pts'),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.employeeRewards,
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textDark,
                        side: const BorderSide(color: Color(0xFFDAD5D1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: AppColors.white,
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'Back to Marketplace',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildSuccessIcon() {
    return Container(
      width: 134,
      height: 134,
      decoration: const BoxDecoration(
        color: Color(0xFFE2F4EC),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: Color(0xFF1FAE72),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: Colors.white,
              size: 52,
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF1FAE72),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}
