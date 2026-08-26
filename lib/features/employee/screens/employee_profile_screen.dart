import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../auth/providers/auth_provider.dart';

class EmployeeProfileScreen extends StatelessWidget {
  const EmployeeProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: EmployeeProfileContent(
          name: user?.name.trim().isNotEmpty == true ? user!.name : '',
          employeeId: user?.employeeId.trim().isNotEmpty == true ? user!.employeeId : '',
          department: user?.department.trim().isNotEmpty == true ? user!.department : '',
          greenScore: user?.greenScore ?? 0,
          points: user?.points ?? 0,
          onLogout: () async {
            await authProvider.logout();
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.login,
                (route) => false,
              );
            }
          },
        ),
      ),
    );
  }
}

class EmployeeProfileContent extends StatelessWidget {
  const EmployeeProfileContent({
    super.key,
    required this.name,
    required this.employeeId,
    required this.department,
    required this.greenScore,
    required this.points,
    this.onLogout,
  });

  final String name;
  final String employeeId;
  final String department;
  final int greenScore;
  final int points;
  final Future<void> Function()? onLogout;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    final reports = _clampValue((greenScore / 10).round() + 14, 1, 99);
    final challenges = _clampValue((greenScore ~/ 100) + 5, 1, 99);
    final redeemed = _clampValue((points ~/ 150) + 1, 1, 99);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Column(
          children: [
            const SizedBox(height: 14),
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ID: $employeeId',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              department,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1FAE72),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.eco_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'Green Score',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Level ${_levelForScore(greenScore)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$greenScore',
                              style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: Text(
                                'Eco Champion',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 54,
                    height: 54,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: CircularProgressIndicator(
                            value: (greenScore / 1000).clamp(0.0, 1.0),
                            backgroundColor: Colors.white.withOpacity(0.25),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 6,
                          ),
                        ),
                        Text(
                          '${((greenScore / 1000) * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.insert_chart_outlined_rounded,
                    value: '$reports',
                    label: 'Reports',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.emoji_events_outlined,
                    value: '$challenges',
                    label: 'Challenges',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.card_giftcard_outlined,
                    value: '$redeemed',
                    label: 'Redeemed',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            InkWell(
              onTap: onLogout,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.logout_rounded, color: Color(0xFFE15B5B), size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE15B5B),
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.chevron_right_rounded, color: Color(0xFFE15B5B), size: 22),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final values = name.trim().split(RegExp(r'\s+'))
      ..removeWhere((item) => item.isEmpty);

    if (values.isEmpty) return 'E';
    if (values.length == 1) return values[0].substring(0, 1).toUpperCase();

    return '${values[0][0]}${values[1][0]}'.toUpperCase();
  }

  int _clampValue(int value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  int _levelForScore(int score) {
    if (score >= 900) return 5;
    if (score >= 750) return 4;
    if (score >= 600) return 3;
    if (score >= 400) return 2;
    return 1;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}