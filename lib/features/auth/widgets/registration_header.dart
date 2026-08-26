import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class RegistrationHeader extends StatelessWidget {
  final VoidCallback? onBack;

  const RegistrationHeader({
    super.key,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE9EEEF),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFCAD4D7),
                ),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: AppColors.textPrimary,
                size: 22,
              ),
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}