import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class GreenLogo extends StatelessWidget {
  final double size;

  const GreenLogo({
    super.key,
    this.size = 244,
  });

  @override
  Widget build(BuildContext context) {
    final innerSize = size * 0.76;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.logoOuter,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: innerSize,
          height: innerSize,
          decoration: BoxDecoration(
            color: AppColors.darkGreen,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Transform.rotate(
            angle: -0.45,
            child: Icon(
              Icons.eco_rounded,
              size: size * 0.41,
              color: AppColors.lightGreen,
            ),
          ),
        ),
      ),
    );
  }
}