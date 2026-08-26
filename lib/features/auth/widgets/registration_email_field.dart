import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class RegistrationEmailField extends StatelessWidget {
  final String email;
  final bool verified;
  final TextEditingController? controller;

  const RegistrationEmailField({
    super.key,
    required this.email,
    this.verified = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Work Email',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Color(0xFF9AA5AA),
              // width: 1.5,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              const Icon(
                Icons.email_outlined,
                color: Color(0xFF9AA5AA),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  // initialValue: email,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'alex.j@greenoffice360.com',
                    hintStyle: TextStyle(
                      color: Color(0xFF9AA5AA),
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  controller: controller,
                ),
              ),
              if (verified)
                Container(
                  width: 26,
                  height: 26,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFB7EFC7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Color(0xFF117B43),
                    size: 18,
                  ),
                ),
            ],
          ),
        ),

        if (verified) ...[
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.only(left: 6),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Color(0xFF1E9D62),
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  'Verified company address',
                  style: TextStyle(
                    color: Color(0xFF1E9D62),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}