import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';

class IssueSelectCategoryScreen extends StatefulWidget {
  const IssueSelectCategoryScreen({super.key});

  @override
  State<IssueSelectCategoryScreen> createState() =>
      _IssueSelectCategoryScreenState();
}

class _IssueSelectCategoryScreenState extends State<IssueSelectCategoryScreen> {
  String _selectedCategory = 'Water';

  final List<IssueCategory> _categories = AppConstants.issueCategories;

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isLandscape ? 760 : 430),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = isLandscape ? 3 : 2;
                final cardHeight = isLandscape ? 170.0 : 150.0;

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLandscape ? 20 : 18,
                    vertical: isLandscape ? 18 : 26,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                                context,
                                AppRoutes.employeeDashboard,
                                (route) => false,
                              ),
                              icon: const Icon(Icons.arrow_back_ios_new_rounded),
                              color: AppColors.textDark,
                              splashRadius: 20,
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'STEP 1 OF 2',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Select Category',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                            letterSpacing: -1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'What type of environmental issue are you reporting today? Select one to begin.',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 20),
                        GridView.builder(
                          itemCount: _categories.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            mainAxisExtent: cardHeight,
                          ),
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            final isSelected = category.name == _selectedCategory;

                            return GestureDetector(
                              onTap: () => setState(() => _selectedCategory = category.name),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withOpacity(0.12)
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.fieldBorder,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      category.icon,
                                      size: isLandscape ? 32 : 34,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textDark.withOpacity(0.6),
                                    ),
                                    const SizedBox(height: 10),
                                    Flexible(
                                      child: Text(
                                        category.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 23,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Flexible(
                                      child: Text(
                                        category.subtitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: isLandscape ? 54 : 58,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.issueDetails,
                                arguments: _selectedCategory,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Next Step',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}


