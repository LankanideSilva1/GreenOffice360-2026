import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../features/issues/providers/issue_provider.dart';
import '../../../models/issue_model.dart';
import '../../../models/user_model.dart';

class ManagerAssignIssueScreen extends StatefulWidget {
  const ManagerAssignIssueScreen({
    super.key,
    required this.issue,
  });

  final IssueModel issue;

  @override
  State<ManagerAssignIssueScreen> createState() => _ManagerAssignIssueScreenState();
}

class _ManagerAssignIssueScreenState extends State<ManagerAssignIssueScreen> {
  final TextEditingController _instructionsController = TextEditingController();
  List<UserModel> _employees = [];
  UserModel? _selectedEmployee;
  String _selectedPriority = 'High';
  DateTime _deadline = DateTime(2026, 8, 25);
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedPriority = widget.issue.priority;
    _deadline = widget.issue.deadline ?? DateTime(2026, 8, 25);
    _instructionsController.text = widget.issue.specialInstructions ?? widget.issue.description;
    _loadEmployees();
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    try {
      final provider = context.read<IssueProvider>();
      final employees = await provider.getAvailableEmployees(widget.issue.userId);

      UserModel? preselected;
      for (final user in employees) {
        if ((widget.issue.assigneeName ?? '').trim().isNotEmpty &&
            user.name.trim().toLowerCase() == widget.issue.assigneeName!.trim().toLowerCase()) {
          preselected = user;
          break;
        }
      }

      if (preselected == null && employees.isNotEmpty) {
        preselected = employees.first;
      }

      if (!mounted) return;
      setState(() {
        _employees = employees;
        _selectedEmployee = preselected;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _chooseEmployee() async {
    if (_employees.isEmpty) {
      return;
    }

    final selected = await showModalBottomSheet<UserModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
                  'Select employee',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _employees.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final employee = _employees[index];
                      final isSelected = _selectedEmployee?.uid == employee.uid;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        tileColor: isSelected ? AppColors.softGreen : AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.fieldBorder,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF47C970),
                          child: Text(
                            _initials(employee.name),
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        title: Text(
                          employee.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        subtitle: Text(
                          employee.department.isNotEmpty ? employee.department : 'Operations Team',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF2FBA59)) : null,
                        onTap: () => Navigator.of(context).pop(employee),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() => _selectedEmployee = selected);
    }
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  Future<void> _assignIssue() async {
    if (_selectedEmployee == null || widget.issue.id == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await context.read<IssueProvider>().assignIssue(
        issueId: widget.issue.id!,
        assigneeName: _selectedEmployee!.name,
        priority: _selectedPriority,
        status: 'Assigned',
        deadline: _deadline,
        specialInstructions: _instructionsController.text.trim().isEmpty
            ? null
            : _instructionsController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Issue assigned successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to assign issue: $error'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = isLandscape ? constraints.maxWidth * 0.72 : constraints.maxWidth;
            return Center(
              child: SizedBox(
                width: contentWidth,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLandscape ? 16 : 14,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: isLandscape ? 44 : 52,
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 38,
                                height: 38,
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
                                'Assign Issue',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 38),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.fieldBorder),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.issue.title,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _Badge(
                                          label: widget.issue.category,
                                          background: const Color(0xFFE8F3FF),
                                          textColor: const Color(0xFF3D7AE8),
                                        ),
                                        _Badge(
                                          label: widget.issue.priority,
                                          background: const Color(0xFFFFE8E5),
                                          textColor: const Color(0xFFE15B5B),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              const _SectionLabel('SELECT EMPLOYEE'),
                              const SizedBox(height: 10),
                              _isLoading
                                  ? const SizedBox(
                                      height: 56,
                                      child: Center(
                                        child: SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                    )
                                  : DropdownButtonFormField<UserModel>(
                                      value: _selectedEmployee,
                                      isExpanded: true,
                                      isDense: true,
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: AppColors.fieldDropdownIcon,
                                        size: 24,
                                      ),
                                      dropdownColor: AppColors.white,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: AppColors.white,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: _selectedEmployee != null ? const Color(0xFF45C96A) : AppColors.fieldBorder,
                                            width: 2,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                        ),
                                      ),
                                      hint: const Text('Select employee'),
                                      selectedItemBuilder: (context) {
                                        return _employees.map((employee) {
                                          return Align(
                                            alignment: Alignment.centerLeft,
                                            child: SizedBox(
                                              height: 22,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  CircleAvatar(
                                                    radius: 10,
                                                    backgroundColor: const Color(0xFF47C970),
                                                    child: Text(
                                                      _initials(employee.name),
                                                      style: const TextStyle(
                                                        color: AppColors.white,
                                                        fontWeight: FontWeight.w800,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Flexible(
                                                    child: Text(
                                                      employee.name,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w700,
                                                        color: AppColors.textDark,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList();
                                      },
                                      items: _employees.map((employee) {
                                        return DropdownMenuItem<UserModel>(
                                          value: employee,
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: _EmployeeDropdownSelection(employee: employee),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (UserModel? value) {
                                        setState(() => _selectedEmployee = value);
                                      },
                                    ),
                              const SizedBox(height: 22),
                              const _SectionLabel('SET PRIORITY'),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _PriorityOption(
                                      label: 'Low',
                                      selected: _selectedPriority == 'Low',
                                      color: const Color(0xFF17B26A),
                                      onTap: () => setState(() => _selectedPriority = 'Low'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _PriorityOption(
                                      label: 'Medium',
                                      selected: _selectedPriority == 'Medium',
                                      color: const Color(0xFFF7B82C),
                                      onTap: () => setState(() => _selectedPriority = 'Medium'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _PriorityOption(
                                      label: 'High',
                                      selected: _selectedPriority == 'High',
                                      color: const Color(0xFFE15B5B),
                                      onTap: () => setState(() => _selectedPriority = 'High'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),
                              const _SectionLabel('SET DEADLINE'),
                              const SizedBox(height: 10),
                              InkWell(
                                onTap: _pickDeadline,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: double.infinity,
                                  height: 54,
                                  padding: const EdgeInsets.symmetric(horizontal: 18),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.fieldBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined, color: AppColors.fieldDropdownIcon, size: 22),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          '${_deadline.day.toString().padLeft(2, '0')} ${_monthName(_deadline.month)} ${_deadline.year}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              const _SectionLabel('SPECIAL INSTRUCTIONS'),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _instructionsController,
                                maxLines: 4,
                                minLines: 3,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppColors.fieldBorder),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppColors.fieldBorder),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving || _selectedEmployee == null ? null : _assignIssue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: AppColors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Assign Issue',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _monthName(int month) {
    const months = [
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
    ];
    return months[month - 1];
  }
}

class _EmployeeDropdownSelection extends StatelessWidget {
  const _EmployeeDropdownSelection({required this.employee});

  final UserModel employee;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFF47C970),
          child: Text(
            _initials(employee.name),
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                employee.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                employee.department.isNotEmpty ? employee.department : 'Operations Team',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.background,
    required this.textColor,
  });

  final String label;
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
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }
}

class _PriorityOption extends StatelessWidget {
  const _PriorityOption({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : AppColors.fieldBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: selected ? color : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
