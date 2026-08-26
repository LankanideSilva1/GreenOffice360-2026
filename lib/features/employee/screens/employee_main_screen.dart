import 'package:flutter/material.dart';
import 'package:greenoffice360/core/constants/app_colors.dart';

class EmployeeMainScreen extends StatefulWidget {
  const EmployeeMainScreen({
    super.key,
    this.homeTabContent,
    this.profileTabContent,
  });

  final Widget? homeTabContent;
  final Widget? profileTabContent;

  @override
  State<EmployeeMainScreen> createState() => _EmployeeMainScreenState();
}

class _EmployeeMainScreenState extends State<EmployeeMainScreen> {
  int _selectedIndex = 0;

  final List<_EmployeeTab> _tabs = const [
    _EmployeeTab(label: 'Home', icon: Icons.home_rounded),
    _EmployeeTab(label: 'Reports', icon: Icons.bar_chart_rounded),
    _EmployeeTab(label: 'Challenges', icon: Icons.emoji_events_rounded),
    _EmployeeTab(label: 'Rewards', icon: Icons.card_giftcard_rounded),
    _EmployeeTab(label: 'Profile', icon: Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final screens = [
      widget.homeTabContent ?? const _EmployeeScreenContent(title: 'Home'),
      const _EmployeeScreenContent(title: 'Reports'),
      const _EmployeeScreenContent(title: 'Challenges'),
      const _EmployeeScreenContent(title: 'Rewards'),
      widget.profileTabContent ?? const _EmployeeScreenContent(title: 'Profile'),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 0),
          child: screens[_selectedIndex],
        ),
      ),
      bottomNavigationBar: Container(
        height: 88,
        padding: const EdgeInsets.only(top: 10, bottom: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_tabs.length, (index) {
            final tab = _tabs[index];
            final isSelected = _selectedIndex == index;

            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tab.icon,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      size: 26,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _EmployeeTab {
  const _EmployeeTab({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

class _EmployeeScreenContent extends StatelessWidget {
  const _EmployeeScreenContent({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
