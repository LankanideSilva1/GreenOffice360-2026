import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class RegistrationField extends StatelessWidget {
  final String label;
  final String hintText;
  final String? initialValue;
  final IconData? icon;
  final TextInputType? keyboardType;
  final bool enabled;
  final TextEditingController? controller;

  const RegistrationField({
    super.key,
    required this.label,
    required this.hintText,
    this.initialValue,
    this.icon,
    this.keyboardType,
    this.enabled = true,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.fieldBorder,
            ),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                const SizedBox(width: 14),
                Icon(
                  icon,
                  color: AppColors.fieldIcon,
                  size: 20,
                ),
                const SizedBox(width: 10),
              ] else
                const SizedBox(width: 12),

              Expanded(
                child: TextFormField(
                  enabled: enabled,
                  // initialValue: initialValue,
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(
                      color: AppColors.fieldHint,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),
            ],
          ),
        ),
      ],
    );
  }
}