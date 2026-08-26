import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class RegistrationPasswordField extends StatelessWidget {
  final String label;
  final String hintText;
  final String? initialValue;
  final bool isVisible;
  final bool hasError;
  final String? errorText;
  final VoidCallback? onVisibilityToggle;
  final TextEditingController? controller;

  const RegistrationPasswordField({
    super.key,
    required this.label,
    required this.hintText,
    this.initialValue,
    this.isVisible = false,
    this.hasError = false,
    this.errorText,
    this.onVisibilityToggle,
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
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasError
                  ? const Color(0xFFE15E5E)
                  : const Color(0xFFD8D1CE),
              width: hasError ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.lock_outline,
                color: Color(0xFF9AA5AA),
                size: 20,
              ),
              const SizedBox(width: 10),

              Expanded(
                child: TextFormField(
                  // initialValue: initialValue,
                  obscureText: !isVisible,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(
                      color: Color(0xFFA3A9AE),
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                  ),
                  controller: controller,
                ),
              ),

              GestureDetector(
                onTap: onVisibilityToggle,
                child: Icon(
                  isVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: hasError
                      ? const Color(0xFFE15E5E)
                      : const Color(0xFF7B8388),
                  size: 18,
                ),
              ),
            ],
          ),
        ),

        if (hasError) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFE15E5E),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                errorText ?? 'Invalid password',
                style: const TextStyle(
                  color: Color(0xFFE15E5E),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}