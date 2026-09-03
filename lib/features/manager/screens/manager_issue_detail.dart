import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:greenoffice360/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../features/issues/providers/issue_provider.dart';
import '../../../models/issue_model.dart';
import '../../../models/user_model.dart';

class ManagerIssueDetailScreen extends StatefulWidget {
  const ManagerIssueDetailScreen({super.key, required this.issue});

  final IssueModel issue;

  @override
  State<ManagerIssueDetailScreen> createState() =>
      _ManagerIssueDetailScreenState();
}

class _ManagerIssueDetailScreenState extends State<ManagerIssueDetailScreen> {
  String _currentStatus = '';

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.issue.status;
  }

  Future<UserModel?> _loadReporter() {
    return context.read<IssueProvider>().getReporter(widget.issue.userId);
  }

  Future<void> _updateIssueStatus(String status) async {
    if (widget.issue.id == null || widget.issue.id!.isEmpty) {
      return;
    }

    try {
      await context.read<IssueProvider>().updateIssueStatus(
        issueId: widget.issue.id!,
        status: status,
      );

      if (!mounted) return;

      setState(() => _currentStatus = status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Issue status updated to $status'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to update status'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showStatusSheet() async {
    final statusProvider = context.read<IssueProvider>();
    final currentIssue = statusProvider.issues.firstWhere(
      (issue) => issue.id == widget.issue.id,
      orElse: () => widget.issue,
    );
    final statuses = ['Pending', 'Assigned', 'In Progress', 'Resolved'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Update Status',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                ...statuses.map(
                  (status) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    title: Text(
                      status,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    trailing: currentIssue.status == status
                        ? const Icon(
                            Icons.check_circle,
                            color: Color(0xFF2FBA59),
                          )
                        : null,
                    onTap: () => Navigator.of(context).pop(status),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && selected != currentIssue.status) {
      await _updateIssueStatus(selected);
    }
  }

  Future<String> _loadAddress() async {
    if ((widget.issue.address ?? '').trim().isNotEmpty) {
      return widget.issue.address!.trim();
    }

    final latitude = widget.issue.latitude;
    final longitude = widget.issue.longitude;

    if (latitude == 0 && longitude == 0) {
      return 'Location not available';
    }

    try {
      // Create Geocoding instance
      final geocoding = Geocoding();

      // Convert latitude and longitude to address
      final List<Placemark> placemarks = await geocoding
          .placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) {
        return 'Location not available';
      }

      final place = placemarks.first;

      final parts =
          [
                place.street,
                place.subLocality,
                place.locality,
                place.administrativeArea,
                place.country,
              ]
              .where((value) => value != null && value.trim().isNotEmpty)
              .map((value) => value!.trim())
              .toList();

      if (parts.isEmpty) {
        return 'Location not available';
      }

      return parts.join(', ');
    } catch (e) {
      debugPrint('Error loading address: $e');
      return 'Location not available';
    }
  }

  @override
  Widget build(BuildContext context) {
    final issueProvider = context.watch<IssueProvider>();
    final issue = issueProvider.issues.firstWhere(
      (item) => item.id == widget.issue.id,
      orElse: () => widget.issue,
    );
    final currentStatus = issue.status;
    final categoryColor = _categoryBadgeColor(issue.category);
    final priorityColor = _priorityBadgeColor(issue.priority);
    final statusColor = _statusBadgeColor(currentStatus);
    final assigneeName = (issue.assigneeName ?? '').trim().isNotEmpty
        ? issue.assigneeName!
        : 'Unassigned';

    if (_currentStatus != currentStatus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _currentStatus = currentStatus);
        }
      });
    }

    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final isManager = user?.role.toLowerCase() == 'manager';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textDark,
                        size: 28,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Issue Details',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 42),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: SizedBox(
                          width: double.infinity,
                          height: 200,
                          child:
                              widget.issue.imageUrl != null &&
                                  widget.issue.imageUrl!.trim().isNotEmpty
                              ? Image.network(
                                  widget.issue.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _issuePlaceholder();
                                  },
                                )
                              : _issuePlaceholder(),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        issue.title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _InfoBadge(
                            text: issue.category.toUpperCase(),
                            background: categoryColor.$1,
                            textColor: categoryColor.$2,
                          ),
                          const SizedBox(width: 10),
                          _InfoBadge(
                            text: '${issue.priority.toUpperCase()} PRIORITY',
                            background: priorityColor.$1,
                            textColor: priorityColor.$2,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      FutureBuilder<String>(
                        future: _loadAddress(),
                        builder: (context, snapshot) {
                          return _DetailRow(
                            icon: Icons.location_on_rounded,
                            label: 'LOCATION',
                            value: snapshot.data ?? 'Location not available',
                          );
                        },
                      ),
                      FutureBuilder<UserModel?>(
                        future: _loadReporter(),
                        builder: (context, snapshot) {
                          final reporterName =
                              snapshot.data?.name ??
                              (widget.issue.userId.isNotEmpty
                                  ? widget.issue.userId
                                  : 'Unknown reporter');
                          return _DetailRow(
                            icon: Icons.person_outline_rounded,
                            label: 'REPORTER',
                            value: reporterName,
                          );
                        },
                      ),
                      _DetailRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'DATE REPORTED',
                        value: _formatDate(widget.issue.createdAt),
                      ),
                      _DetailRow(
                        icon: Icons.timeline_rounded,
                        label: 'CURRENT STATUS',
                        value: currentStatus,
                        valueColor: statusColor.$2,
                        valueBackground: statusColor.$1,
                        inlineBadge: true,
                      ),
                      _DetailRow(
                        icon: Icons.assignment_ind_outlined,
                        label: 'ASSIGNED TO',
                        value: assigneeName,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'DESCRIPTION',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        issue.description,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (isManager) ...[
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'Reassign',
                        textColor: AppColors.primary,
                        borderColor: AppColors.primary,
                        background: AppColors.white,
                        icon: Icons.person_add_alt_1_rounded,
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.managerAssignIssue,
                            arguments: issue,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        label: 'Update Status',
                        textColor: AppColors.white,
                        borderColor: AppColors.primary,
                        background: AppColors.primary,
                        icon: Icons.sync_rounded,
                        onTap: _showStatusSheet,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _issuePlaceholder() {
    return Container(
      color: const Color(0xFF2A2A2A),
      child: const Center(
        child: Icon(
          Icons.image_not_supported_rounded,
          color: AppColors.white,
          size: 40,
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final month = <String>[
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
    ][value.month - 1];
    return '$month ${value.day}, ${value.year}';
  }

  (Color, Color) _categoryBadgeColor(String category) {
    final normalized = category.toLowerCase();
    if (normalized.contains('water') || normalized.contains('plumbing')) {
      return (const Color(0xFFFFEAEA), const Color(0xFFE15B5B));
    }
    if (normalized.contains('electrical')) {
      return (const Color(0xFFEAF3FF), const Color(0xFF2A6FEA));
    }
    if (normalized.contains('safety')) {
      return (const Color(0xFFF8F1D8), const Color(0xFFB77A00));
    }
    return (const Color(0xFFEAF7F1), const Color(0xFF2F8F5B));
  }

  (Color, Color) _priorityBadgeColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return (const Color(0xFFFFEAEA), const Color(0xFFE15B5B));
      case 'medium':
        return (const Color(0xFFFFF2C9), const Color(0xFFC28200));
      default:
        return (const Color(0xFFEAF7F1), const Color(0xFF2F8F5B));
    }
  }

  (Color, Color) _statusBadgeColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return (const Color(0xFFF8F3D9), const Color(0xFFB58410));
      case 'resolved':
        return (const Color(0xFFEAECEF), const Color(0xFF6B7280));
      case 'in progress':
        return (const Color(0xFFEAF7F1), const Color(0xFF2F8F5B));
      default:
        return (const Color(0xFFEAF7F1), const Color(0xFF2F8F5B));
    }
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.text,
    required this.background,
    required this.textColor,
  });

  final String text;
  final Color background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueBackground,
    this.inlineBadge = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Color? valueBackground;
  final bool inlineBadge;

  @override
  Widget build(BuildContext context) {
    final content = inlineBadge
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: valueBackground ?? AppColors.softGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        : Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(icon, size: 22, color: AppColors.textDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                content,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.textColor,
    required this.borderColor,
    required this.background,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Color textColor;
  final Color borderColor;
  final Color background;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: textColor),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
