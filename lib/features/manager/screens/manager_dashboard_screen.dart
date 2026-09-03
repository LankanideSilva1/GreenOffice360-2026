import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/issue_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../employee/screens/employee_profile_screen.dart';
import '../../issues/providers/issue_provider.dart';
import 'manager_issue_list.dart';
import 'manager_main_screen.dart';

class ManagerDashboardScreen extends StatelessWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return ManagerMainScreen(
      dashboardTabContent: ManagerDashboardContent(
        managerName: user?.name ?? 'Manager',
      ),
      issuesTabContent: const ManagerIssueListScreen(),
      profileTabContent: const EmployeeProfileScreen(),
    );
  }
}

class ManagerDashboardContent extends StatefulWidget {
  const ManagerDashboardContent({super.key, required this.managerName});

  final String managerName;

  @override
  State<ManagerDashboardContent> createState() =>
      _ManagerDashboardContentState();
}

class _ManagerDashboardContentState extends State<ManagerDashboardContent> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          context.read<IssueProvider>().status == IssueStatus.initial) {
        context.read<IssueProvider>().loadIssues();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final allIssues = context.watch<IssueProvider>().issues;
    final issues = allIssues.where((issue) {
      return issue.createdAt.year == _selectedMonth.year &&
          issue.createdAt.month == _selectedMonth.month;
    }).toList();
    final pending = _countByStatus(issues, 'pending');
    final assigned = _countByStatus(issues, 'assigned');
    final inProgress = _countByStatus(issues, 'in progress');
    final resolved = _countByStatus(issues, 'resolved');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.badgeText,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text(
                  'MANAGER',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              _HeaderIcon(icon: Icons.notifications_none_rounded, badge: true),
            ],
          ),
          const SizedBox(height: 20),
          _MonthSelector(
            selectedMonth: _selectedMonth,
            onMonthChanged: (month) {
              setState(() => _selectedMonth = month);
            },
          ),
          const SizedBox(height: 20),
          const _SectionLabel('ISSUE STATISTICS'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  value: '${issues.length}',
                  label: 'Total Issues',
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  value: '$pending',
                  label: 'Pending',
                  color: AppColors.managerOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  value: '$assigned',
                  label: 'Assigned',
                  color: AppColors.managerBlue,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  value: '$inProgress',
                  label: 'In Progress',
                  color: AppColors.managerPurple,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  value: '$resolved',
                  label: 'Resolved',
                  color: AppColors.badgeText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          const Text(
            'Sustainability Metrics',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const Divider(height: 12, color: AppColors.chartGrid),
          const SizedBox(height: 10),
          _CategoryCard(issues: issues),
          // const SizedBox(height: 20),
          // _ResolutionCard(issues: issues),
          const SizedBox(height: 20),
          _DepartmentCard(issues: issues),
          const SizedBox(height: 20),
          _ActivityOverviewCard(issues: issues),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  int _countByStatus(List<IssueModel> issues, String status) {
    if (status == 'assigned') {
      return issues
          .where(
            (issue) =>
                issue.assigneeName != null && issue.assigneeName!.isNotEmpty,
          )
          .length;
    }
    return issues.where((issue) => issue.status.toLowerCase() == status).length;
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, this.badge = false});
  final IconData icon;
  final bool badge;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.chartGrid),
        ),
        child: Icon(icon, color: AppColors.textDark, size: 23),
      ),
      if (badge)
        Positioned(
          right: 7,
          top: 6,
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.logout,
              shape: BoxShape.circle,
            ),
          ),
        ),
    ],
  );
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: 38,
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.chartGrid),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => onMonthChanged(
            DateTime(selectedMonth.year, selectedMonth.month - 1),
          ),
          icon: const Icon(Icons.chevron_left_rounded),
          iconSize: 22,
          color: AppColors.textDark,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          constraints: const BoxConstraints(),
          tooltip: 'Previous month',
        ),
        Text(
          _monthName(selectedMonth),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        IconButton(
          onPressed: () => onMonthChanged(
            DateTime(selectedMonth.year, selectedMonth.month + 1),
          ),
          icon: const Icon(Icons.chevron_right_rounded),
          iconSize: 22,
          color: AppColors.textDark,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          constraints: const BoxConstraints(),
          tooltip: 'Next month',
        ),
      ],
    ),
  );

  String _monthName(DateTime month) =>
      const [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ][month.month - 1] +
      ' ${month.year}';
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondary,
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.value,
    required this.label,
    required this.color,
  });
  final String value;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 12, 8, 10),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.chartGrid),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.issues});
  final List<IssueModel> issues;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final issue in issues) {
      counts.update(issue.category, (count) => count + 1, ifAbsent: () => 1);
    }
    final data = counts.entries.toList()
      ..sort((first, second) => second.value.compareTo(first.value));
    final max = data.isEmpty ? 1 : data.first.value;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Issues by Category',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          if (data.isEmpty) const Text('No issue data available.'),
          ...data
              .take(5)
              .map(
                (item) => _BarRow(label: item.key, value: item.value, max: max),
              ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({required this.label, required this.value, required this.max});
  final String label;
  final int value;
  final int max;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        SizedBox(
          width: 102,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value / max,
              minHeight: 9,
              backgroundColor: AppColors.chartTrack,
              valueColor: const AlwaysStoppedAnimation(AppColors.badgeText),
            ),
          ),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.chartGrid),
    ),
    child: child,
  );
}

class _ResolutionCard extends StatelessWidget {
  const _ResolutionCard({required this.issues});
  final List<IssueModel> issues;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final points = <double>[];
    final labels = <String>[];
    for (var offset = 5; offset >= 0; offset--) {
      final month = DateTime(now.year, now.month - offset);
      final monthIssues = issues.where(
        (issue) =>
            issue.createdAt.year == month.year &&
            issue.createdAt.month == month.month,
      );
      final monthList = monthIssues.toList();
      final resolved = monthList
          .where((issue) => issue.status.toLowerCase() == 'resolved')
          .length;
      points.add(monthList.isEmpty ? 0 : resolved / monthList.length);
      labels.add(_monthName(month.month));
    }
    final average = points.isEmpty
        ? 0
        : points.reduce((first, second) => first + second) / points.length;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Monthly Resolution Rate',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Text(
                '${(average * 100).round()}% Avg',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.badgeText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 125,
            child: CustomPaint(painter: _LineChartPainter(points: points)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: labels.map(Text.new).toList(),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({required this.points});
  final List<double> points;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.chartGrid
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - 38),
      Offset(size.width, size.height - 38),
      grid,
    );
    if (points.isEmpty) return;
    final line = Paint()
      ..color = AppColors.badgeText
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (var index = 0; index < points.length; index++) {
      final point = Offset(
        size.width * index / (points.length - 1),
        (size.height - 48) * (1 - points[index]),
      );
      if (index == 0)
        path.moveTo(point.dx, point.dy);
      else
        path.lineTo(point.dx, point.dy);
      canvas.drawCircle(
        point,
        3,
        Paint()
          ..color = AppColors.white
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        point,
        3,
        Paint()
          ..color = AppColors.badgeText
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DepartmentCard extends StatelessWidget {
  const _DepartmentCard({required this.issues});
  final List<IssueModel> issues;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final issue in issues) {
      final assignee = issue.assigneeName?.trim();
      final key = assignee == null || assignee.isEmpty
          ? 'Unassigned'
          : assignee;
      counts.update(key, (count) => count + 1, ifAbsent: () => 1);
    }
    final entries = counts.entries.toList()
      ..sort((first, second) => second.value.compareTo(first.value));
    final visibleEntries = entries.take(5).toList();
    final total = issues.isEmpty ? 1 : issues.length;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Issues by Assignee',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          if (visibleEntries.isEmpty)
            const Text('No issue data available.')
          else
            Row(
              children: [
                SizedBox(
                  width: 130,
                  height: 120,
                  child: CustomPaint(
                    painter: _DonutPainter(
                      values: visibleEntries
                          .map((entry) => entry.value / total)
                          .toList(),
                      centerText: '${issues.length}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Legend(entries: visibleEntries, total: total),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.values, required this.centerText});
  final List<double> values;
  final String centerText;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(8, 4, 112, 112);
    final colors = [
      AppColors.managerTeal,
      AppColors.managerBlue,
      AppColors.managerPurple,
      AppColors.managerOrange,
      AppColors.managerGray,
    ];
    var start = -1.5708;
    for (var index = 0; index < values.length; index++) {
      final paint = Paint()
        ..color = colors[index]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18;
      final sweep = values[index] * 6.2832;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
    canvas.drawCircle(
      const Offset(64, 60),
      35,
      Paint()..color = AppColors.white,
    );
    final textPainter = TextPainter(
      text: TextSpan(
        text: centerText,
        style: const TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(53, 47));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Legend extends StatelessWidget {
  const _Legend({required this.entries, required this.total});
  final List<MapEntry<String, int>> entries;
  final int total;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: entries.asMap().entries.map((item) {
      final entry = item.value;
      return _LegendRow(
        entry.key,
        '${(entry.value * 100 / total).round()}%',
        [
          AppColors.managerTeal,
          AppColors.managerBlue,
          AppColors.managerPurple,
          AppColors.managerOrange,
          AppColors.managerGray,
        ][item.key],
      );
    }).toList(),
  );
}

class _LegendRow extends StatelessWidget {
  const _LegendRow(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ],
    ),
  );
}

class _ActivityOverviewCard extends StatelessWidget {
  const _ActivityOverviewCard({required this.issues});
  final List<IssueModel> issues;

  @override
  Widget build(BuildContext context) {
    final active = issues
        .where(
          (issue) =>
              ['assigned', 'in progress'].contains(issue.status.toLowerCase()),
        )
        .length;
    final participants = issues
        .map((issue) => issue.userId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .length;
    final resolved = issues
        .where((issue) => issue.status.toLowerCase() == 'resolved')
        .length;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sustainability Activity Overview',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ActivityBar(
                value: '$active',
                label: 'Active Issues',
                color: AppColors.badgeText,
                height: _barHeight(active, issues.length),
              ),
              _ActivityBar(
                value: '$participants',
                label: 'Reporters',
                color: AppColors.managerBlue,
                height: _barHeight(participants, issues.length),
              ),
              _ActivityBar(
                value: '$resolved',
                label: 'Resolved',
                color: AppColors.badgeText,
                height: _barHeight(resolved, issues.length),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _barHeight(int value, int total) {
    if (value == 0 || total == 0) return 0;
    return (value / total * 100).clamp(12, 100).toDouble();
  }
}

class _ActivityBar extends StatelessWidget {
  const _ActivityBar({
    required this.value,
    required this.label,
    required this.color,
    required this.height,
  });
  final String value;
  final String label;
  final Color color;
  final double height;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 100,
        width: 32,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 100,
            width: 32,
            decoration: BoxDecoration(
              color: AppColors.chartTrack,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: height,
                width: 32,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        value,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
        ),
      ),
      Text(
        label,
        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
      ),
    ],
  );
}
