import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class RegistrationDepartmentField extends StatelessWidget {
  final String? value;
  final ValueChanged<String?>? onChanged;

  const RegistrationDepartmentField({
    super.key,
    required this.value,
    this.onChanged,
  });

  static const List<String> departments = [
    'Product & Tech',
    'Human Resources',
    'Finance',
    'Marketing',
    'Operations',
    'Sales',
    'Administration',
    'Sustainability',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Department',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),

        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,

          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.fieldDropdownIcon,
          ),

          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.white,

            contentPadding:
                const EdgeInsets.symmetric(
              horizontal: 12,
            ),

            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.fieldBorder,
              ),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.fieldBorder,
              ),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),

          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),

          items: departments.map(
            (department) {
              return DropdownMenuItem<String>(
                value: department,
                child: Text(
                  department,
                  overflow:
                      TextOverflow.ellipsis,
                ),
              );
            },
          ).toList(),

          onChanged: onChanged,
        ),
      ],
    );
  }
}