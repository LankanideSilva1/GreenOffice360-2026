import 'package:flutter/material.dart';

import 'manager_main_screen.dart';

class ManagerDashboardScreen extends StatelessWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ManagerMainScreen(
      dashboardTabContent: _ManagerDashboardContent(),
    );
  }
}

class _ManagerDashboardContent extends StatelessWidget {
  const _ManagerDashboardContent();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Manager Dashboard',
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}