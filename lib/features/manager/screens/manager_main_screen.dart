import 'package:flutter/material.dart';
import 'package:greenoffice360/core/constants/app_colors.dart';

class ManagerMainScreen extends StatefulWidget {
	const ManagerMainScreen({
		super.key,
		this.dashboardTabContent,
		this.issuesTabContent,
		this.profileTabContent,
	});

	final Widget? dashboardTabContent;
	final Widget? issuesTabContent;
	final Widget? profileTabContent;

	@override
	State<ManagerMainScreen> createState() => _ManagerMainScreenState();
}

class _ManagerMainScreenState extends State<ManagerMainScreen> {
	int _selectedIndex = 0;

	static const _tabs = [
		_ManagerTab(label: 'Dashboard', icon: Icons.home_rounded),
		_ManagerTab(label: 'Issues', icon: Icons.description_outlined),
		_ManagerTab(label: 'Profile', icon: Icons.person_outline_rounded),
	];

	@override
	Widget build(BuildContext context) {
		final screens = [
			widget.dashboardTabContent ?? const _ManagerScreenContent(title: 'Dashboard'),
			widget.issuesTabContent ?? const _ManagerScreenContent(title: 'Issues'),
			widget.profileTabContent ?? const _ManagerScreenContent(title: 'Profile'),
		];

		return Scaffold(
			backgroundColor: AppColors.background,
			body: SafeArea(
				child: Padding(
					padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
					child: screens[_selectedIndex],
				),
			),
			bottomNavigationBar: Container(
				height: 88,
				padding: const EdgeInsets.only(top: 10, bottom: 12),
				decoration: const BoxDecoration(
					color: AppColors.white,
					borderRadius: BorderRadius.only(
						topLeft: Radius.circular(24),
						topRight: Radius.circular(24),
					),
					boxShadow: [
						BoxShadow(
			color: AppColors.navigationShadow,
							blurRadius: 10,
							offset: Offset(0, -2),
						),
					],
				),
				child: Row(
					children: List.generate(_tabs.length, (index) {
						final tab = _tabs[index];
						final isSelected = _selectedIndex == index;

						return Expanded(
							child: InkWell(
								borderRadius: BorderRadius.circular(14),
								onTap: () => setState(() => _selectedIndex = index),
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

class _ManagerTab {
	const _ManagerTab({required this.label, required this.icon});

	final String label;
	final IconData icon;
}

class _ManagerScreenContent extends StatelessWidget {
	const _ManagerScreenContent({required this.title});

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
