import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/issue_model.dart';
import '../../issues/providers/issue_provider.dart';

class ManagerIssueListScreen extends StatefulWidget {
  const ManagerIssueListScreen({super.key});

  @override
  State<ManagerIssueListScreen> createState() => _ManagerIssueListScreenState();
}

class _ManagerIssueListScreenState extends State<ManagerIssueListScreen> {
  String _selectedCategory = 'All';
  String _selectedPriority = 'All';
  String _selectedStatus = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<IssueProvider>().loadIssues();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final issueProvider = context.watch<IssueProvider>();
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final issues = issueProvider.issues;
    final categories = <String>['All', ...issues.map((issue) => issue.category).toSet().toList()]
      ..sort((a, b) => a == 'All' ? -1 : b == 'All' ? 1 : a.compareTo(b));

    final filteredIssues = issues.where((issue) {
      final matchesCategory = _selectedCategory == 'All' || issue.category == _selectedCategory;
      final matchesPriority = _selectedPriority == 'All' || issue.priority.toLowerCase() == _selectedPriority.toLowerCase();
      final matchesStatus = _selectedStatus == 'All' || issue.status.toLowerCase() == _selectedStatus.toLowerCase();
      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          issue.title.toLowerCase().contains(query) ||
          issue.category.toLowerCase().contains(query) ||
          issue.status.toLowerCase().contains(query) ||
          issue.priority.toLowerCase().contains(query);
      return matchesCategory && matchesPriority && matchesStatus && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Issue Management',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'MANAGER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.chartGrid),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: AppColors.fieldIcon,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        onChanged: (value) => setState(() => _searchQuery = value),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Search issues...',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final selected = _selectedCategory == category;

                  return ChoiceChip(
                    label: Text(category),
                    labelStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.white : AppColors.textDark,
                    ),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedCategory = category),
                    backgroundColor: AppColors.white,
                    selectedColor: AppColors.primary,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: isLandscape
                  ? Row(
                      children: [
                        Expanded(
                          child: _FilterDropdown(
                            label: 'Priority',
                            value: _selectedPriority,
                            items: const ['All', 'High', 'Medium', 'Low'],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedPriority = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _FilterDropdown(
                            label: 'Status',
                            value: _selectedStatus,
                            items: const ['All', 'Pending', 'In Progress', 'Resolved', 'Reviewed'],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedStatus = value);
                              }
                            },
                          ),
                        ),
                      ],
                    )
                  : Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width - 32,
                          child: _FilterDropdown(
                            label: 'Priority',
                            value: _selectedPriority,
                            items: const ['All', 'High', 'Medium', 'Low'],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedPriority = value);
                              }
                            },
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width - 32,
                          child: _FilterDropdown(
                            label: 'Status',
                            value: _selectedStatus,
                            items: const ['All', 'Pending', 'In Progress', 'Resolved', 'Reviewed'],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedStatus = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Showing ${filteredIssues.length} active issue${filteredIssues.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (issueProvider.status == IssueStatus.loading && issues.isEmpty)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (issueProvider.status == IssueStatus.error)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      issueProvider.errorMessage ?? 'Unable to load issues.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.logout),
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filteredIssues.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final issue = filteredIssues[index];
                    final issueData = _buildIssueData(issue);

                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.managerIssueDetail,
                          arguments: issue,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.only(left: 14, right: 14, top: 14, bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.chartGrid),
                        ),
                        child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 4,
                            height: 120,
                            decoration: BoxDecoration(
                              color: _priorityBarColor(issue.priority),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        issue.title,
                                        style: const TextStyle(
                                          color: AppColors.textDark,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          height: 1.15,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      issueData['date'],
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: issueData['categoryColor'],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        issue.category,
                                        style: TextStyle(
                                          color: issueData['categoryTextColor'],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: issueData['severityBackground'],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        issue.priority,
                                        style: TextStyle(
                                          color: issueData['severityTextColor'],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: issueData['statusBackground'],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        issue.status,
                                        style: TextStyle(
                                          color: issueData['statusTextColor'],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_rounded,
                                      color: AppColors.textSecondary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        issueData['location'],
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.person_rounded,
                                      color: AppColors.textSecondary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'By ${issue.userId.length > 8 ? issue.userId.substring(0, 8) : issue.userId}',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _buildIssueData(IssueModel issue) {
    final categoryColor = _categoryColor(issue.category);
    final severity = issue.priority.toLowerCase();
    final severityMap = {
      'high': (
        const Color(0xFFFFEAEA),
        const Color(0xFFE15B5B),
      ),
      'medium': (
        const Color(0xFFFFF2C9),
        const Color(0xFFC28200),
      ),
      'low': (
        const Color(0xFFEAF7F1),
        const Color(0xFF2F8F5B),
      ),
    };
    final status = issue.status.toLowerCase();
    final statusMap = {
      'pending': (
        const Color(0xFFF8F3D9),
        const Color(0xFFB58410),
      ),
      'in progress': (
        const Color(0xFFEAF7F1),
        const Color(0xFF2F8F5B),
      ),
      'resolved': (
        const Color(0xFFEAECEF),
        const Color(0xFF6B7280),
      ),
      'reviewed': (
        const Color(0xFFEAECEF),
        const Color(0xFF6B7280),
      ),
    };

    final statusStyle = statusMap[status] ?? (const Color(0xFFEAF7F1), const Color(0xFF2F8F5B));
    final severityStyle = severityMap[severity] ?? (const Color(0xFFFFF2C9), const Color(0xFFC28200));

    return {
      'date': _formatShortDate(issue.createdAt),
      'categoryColor': categoryColor['background'],
      'categoryTextColor': categoryColor['text'],
      'severityBackground': severityStyle.$1,
      'severityTextColor': severityStyle.$2,
      'statusBackground': statusStyle.$1,
      'statusTextColor': statusStyle.$2,
      'location': issue.latitude == 0 && issue.longitude == 0
          ? 'Location not available'
          : 'Lat ${issue.latitude.toStringAsFixed(4)}, Lng ${issue.longitude.toStringAsFixed(4)}',
    };
  }

  Map<String, Color> _categoryColor(String category) {
    final normalized = category.toLowerCase();
    final map = {
      'plumbing': {'background': const Color(0xFFFFE5E5), 'text': const Color(0xFFE15B5B)},
      'electrical': {'background': const Color(0xFFFFE7E5), 'text': const Color(0xFFE15B5B)},
      'safety': {'background': const Color(0xFFF8F1D8), 'text': const Color(0xFFB77A00)},
      'structural': {'background': const Color(0xFFFFE9E5), 'text': const Color(0xFFE15B5B)},
      'water': {'background': const Color(0xFFFFE5E5), 'text': const Color(0xFFE15B5B)},
      'maintenance': {'background': const Color(0xFFEAF7F1), 'text': const Color(0xFF2F8F5B)},
    };

    final colorSet = map[normalized] ?? {'background': const Color(0xFFEAF7F1), 'text': const Color(0xFF2F8F5B)};
    return {
      'background': colorSet['background'] as Color,
      'text': colorSet['text'] as Color,
    };
  }

  Color _priorityBarColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFE15B5B);
      case 'medium':
        return const Color(0xFFE4B55A);
      default:
        return const Color(0xFF2F8F5B);
    }
  }

  String _formatShortDate(DateTime value) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[value.month - 1]} ${value.day}';
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.chartGrid),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textDark,
                size: 20,
              ),
              dropdownColor: AppColors.white,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              items: items
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
