import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../employee/screens/employee_profile_screen.dart';
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

class ManagerDashboardContent extends StatelessWidget {
  const ManagerDashboardContent({super.key, required this.managerName});

  final String managerName;

  @override
  Widget build(BuildContext context) {
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
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textDark),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.badgeText, borderRadius: BorderRadius.circular(5)),
                child: const Text('MANAGER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.white)),
              ),
              const SizedBox(width: 14),
              _HeaderIcon(icon: Icons.notifications_none_rounded, badge: true),
            ],
          ),
          const SizedBox(height: 20),
          _MonthSelector(),
          const SizedBox(height: 20),
          const _SectionLabel('ISSUE STATISTICS'),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(child: _MetricCard(value: '47', label: 'Total Issues', color: AppColors.textDark)),
              SizedBox(width: 8),
              Expanded(child: _MetricCard(value: '8', label: 'Pending', color: AppColors.managerOrange)),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Expanded(child: _MetricCard(value: '12', label: 'Assigned', color: AppColors.managerBlue)),
              SizedBox(width: 8),
              Expanded(child: _MetricCard(value: '15', label: 'In Progress', color: AppColors.managerPurple)),
              SizedBox(width: 8),
              Expanded(child: _MetricCard(value: '12', label: 'Resolved', color: AppColors.badgeText)),
            ],
          ),
          const SizedBox(height: 26),
          const Text('Sustainability Metrics', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const Divider(height: 12, color: AppColors.chartGrid),
          const SizedBox(height: 10),
          const _CategoryCard(),
          const SizedBox(height: 20),
          const _ResolutionCard(),
          const SizedBox(height: 20),
          const _DepartmentCard(),
          const SizedBox(height: 20),
          const _ActivityOverviewCard(),
          const SizedBox(height: 30),
        ],
      ),
    );
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
            decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.chartGrid)),
            child: Icon(icon, color: AppColors.textDark, size: 23),
          ),
          if (badge) Positioned(right: 7, top: 6, child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.logout, shape: BoxShape.circle))),
        ],
      );
}

class _MonthSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 38,
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.chartGrid)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Icon(Icons.chevron_left_rounded, size: 22, color: AppColors.textDark)),
            Text('August 2026', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.textDark)),
          ],
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary));
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 10),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.chartGrid)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 3),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ]),
      );
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard();
  static const data = [('Plumbing', 14), ('Electrical', 11), ('Safety', 9), ('Structural', 7), ('Environmental', 6)];
  @override
  Widget build(BuildContext context) => _Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Issues by Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 12),
          ...data.map((item) => _BarRow(label: item.$1, value: item.$2, max: 14)),
        ]),
      );
}

class _BarRow extends StatelessWidget {
  const _BarRow({required this.label, required this.value, required this.max});
  final String label;
  final int value;
  final int max;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          SizedBox(width: 102, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: value / max, minHeight: 9, backgroundColor: AppColors.chartTrack, valueColor: const AlwaysStoppedAnimation(AppColors.badgeText)))),
          SizedBox(width: 28, child: Text('$value', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark))),
        ]),
      );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.chartGrid)), child: child);
}

class _ResolutionCard extends StatelessWidget {
  const _ResolutionCard();
  @override
  Widget build(BuildContext context) => _Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Expanded(child: Text('Monthly Resolution Rate', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark))), Text('88% Avg', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.badgeText))]),
        const SizedBox(height: 12),
        SizedBox(height: 125, child: CustomPaint(painter: _LineChartPainter())),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Text('Mar'), Text('Apr'), Text('May'), Text('Jun'), Text('Jul'), Text('Aug')]),
      ]));
}

class _LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = AppColors.chartGrid..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height - 38), Offset(size.width, size.height - 38), grid);
    final points = [0.72, 0.77, 0.79, 0.86, 0.9, 0.97];
    final line = Paint()..color = AppColors.badgeText..strokeWidth = 2.5..style = PaintingStyle.stroke;
    final path = Path();
    for (var index = 0; index < points.length; index++) {
      final point = Offset(size.width * index / (points.length - 1), (size.height - 48) * (1 - points[index]));
      if (index == 0) path.moveTo(point.dx, point.dy); else path.lineTo(point.dx, point.dy);
      canvas.drawCircle(point, 3, Paint()..color = AppColors.white..style = PaintingStyle.fill);
      canvas.drawCircle(point, 3, Paint()..color = AppColors.badgeText..style = PaintingStyle.stroke..strokeWidth = 2);
    }
    canvas.drawPath(path, line);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DepartmentCard extends StatelessWidget {
  const _DepartmentCard();
  @override
  Widget build(BuildContext context) => _Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Issues by Department', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        const SizedBox(height: 10),
        Row(children: [SizedBox(width: 130, height: 120, child: CustomPaint(painter: _DonutPainter())), const SizedBox(width: 8), const Expanded(child: _Legend())]),
      ]));
}

class _DonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(8, 4, 112, 112);
    final values = [0.30, 0.25, 0.20, 0.15, 0.10];
    final colors = [AppColors.managerTeal, AppColors.managerBlue, AppColors.managerPurple, AppColors.managerOrange, AppColors.managerGray];
    var start = -1.5708;
    for (var index = 0; index < values.length; index++) { final paint = Paint()..color = colors[index]..style = PaintingStyle.stroke..strokeWidth = 18; final sweep = values[index] * 6.2832; canvas.drawArc(rect, start, sweep, false, paint); start += sweep; }
    canvas.drawCircle(const Offset(64, 60), 35, Paint()..color = AppColors.white);
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '47',
        style: TextStyle(
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
  const _Legend();
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [_LegendRow('IT', '30%', AppColors.managerTeal), _LegendRow('Operations', '25%', AppColors.managerBlue), _LegendRow('HR', '20%', AppColors.managerPurple), _LegendRow('Finance', '15%', AppColors.managerOrange), _LegendRow('Other', '10%', AppColors.managerGray)]);
}

class _LegendRow extends StatelessWidget {
  const _LegendRow(this.label, this.value, this.color);
  final String label; final String value; final Color color;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 5), child: Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 8), Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))), Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textDark))]));
}

class _ActivityOverviewCard extends StatelessWidget {
  const _ActivityOverviewCard();
  @override
  Widget build(BuildContext context) => _Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Sustainability Activity Overview', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: const [_ActivityBar(value: '4', label: 'Active Ch.', color: AppColors.badgeText, height: 40), _ActivityBar(value: '156', label: 'Partic.', color: AppColors.managerBlue, height: 85), _ActivityBar(value: '720', label: 'Score Avg', color: AppColors.badgeText, height: 72)]),
      ]));
}

class _ActivityBar extends StatelessWidget {
  const _ActivityBar({required this.value, required this.label, required this.color, required this.height});
  final String value; final String label; final Color color; final double height;
  @override
  Widget build(BuildContext context) => Column(children: [SizedBox(height: 100, width: 32, child: Align(alignment: Alignment.bottomCenter, child: Container(height: 100, width: 32, decoration: BoxDecoration(color: AppColors.chartTrack, borderRadius: BorderRadius.circular(8)), child: Align(alignment: Alignment.bottomCenter, child: Container(height: height, width: 32, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8))))))), const SizedBox(height: 6), Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark)), Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary))]);
}