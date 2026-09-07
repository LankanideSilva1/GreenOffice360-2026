import 'package:flutter/material.dart';
import 'package:greenoffice360/core/constants/app_colors.dart';
import 'package:greenoffice360/models/challenge_model.dart';
import 'package:greenoffice360/features/gamification/providers/challenge_provider.dart';
import 'package:provider/provider.dart';

class ChallengeDetailScreen extends StatefulWidget {
  const ChallengeDetailScreen({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconBackground,
    required this.duration,
    required this.joined,
    required this.points,
    required this.progress,
    required this.status,
    required this.joinedByUser,
    this.challengeId,
    this.substeps = const [],
    this.completedSubstepIds = const [],
  });

  final String title;
  final String description;
  final IconData icon;
  final Color iconBackground;
  final String duration;
  final String joined;
  final String points;
  final double progress;
  final String status;
  final bool joinedByUser;
  final String? challengeId;
  final List<ChallengeSubstep> substeps;
  final List<String> completedSubstepIds;

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  late final List<bool> _completed;

  @override
  void initState() {
    super.initState();
    _completed = widget.substeps
        .map((substep) => widget.completedSubstepIds.contains(substep.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _completed.where((item) => item).length;
    final progress = _completed.isEmpty
        ? 0.0
        : completedCount / _completed.length;
    final earnedPoints = _earnedPoints;
    final joined = widget.joined.replaceFirst(' joined', '');

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          color: const Color(0xFF13A451),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                const SizedBox(width: 24),
                IconButton(
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.white,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0x2675D58D),
                    fixedSize: const Size(40, 40),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Challenge Details',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 64),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _ChallengeHero(
            title: widget.title,
            icon: widget.icon,
            iconBackground: widget.iconBackground,
            status: widget.status,
            joinedByUser: widget.joinedByUser,
            points: widget.points,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Card(
                    title: 'ABOUT',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.description,
                          style: TextStyle(
                            color: Color(0xFF24324A),
                            fontSize: 14,
                            height: 1.55,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(height: 1, color: Color(0xFFDCE4EB)),
                        ),
                        const _DateRow(
                          label: 'START DATE',
                          value: 'August 18, 2026',
                        ),
                        const SizedBox(height: 12),
                        const _DateRow(
                          label: 'END DATE',
                          value: 'August 25, 2026',
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const _CircleIcon(icon: Icons.person_rounded),
                            const SizedBox(width: 10),
                            Text(
                              '$joined people joined',
                              style: const TextStyle(
                                color: Color(0xFF24324A),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        const Padding(
                          padding: EdgeInsets.only(left: 42),
                          child: _ParticipantAvatars(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _Card(
                    title: 'REQUIRED ACTIONS',
                    child: Column(
                      children: List.generate(widget.substeps.length, (index) {
                        return _ActionRow(
                          label: widget.substeps[index].title,
                          completed: _completed[index],
                          onChanged: (value) => _toggleSubstep(index, value),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _Card(
                    title: 'YOUR PROGRESS',
                    child: _ProgressContent(
                      progress: progress,
                      completedCount: completedCount,
                      totalCount: _completed.length,
                      earnedPoints: earnedPoints,
                      points: widget.points.replaceFirst(' pts', ''),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: Color(0xFFDCE4EB))),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF13A451),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: const Text(
                    'View Leaderboard',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              TextButton(
                onPressed: widget.joinedByUser ? _leaveChallenge : null,
                child: const Text(
                  'Leave Challenge',
                  style: TextStyle(
                    color: Color(0xFF657895),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _leaveChallenge() async {
    final provider = context.read<ChallengeProvider>();
    final deleted = await provider.leaveChallenge(widget.challengeId ?? '');
    if (!mounted) return;
    if (deleted) {
      Navigator.of(context).pop();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(provider.errorMessage ?? 'Unable to leave challenge.'),
      ),
    );
  }

  int get _earnedPoints => widget.substeps.asMap().entries.fold(
    0,
    (total, entry) => total + (_completed[entry.key] ? entry.value.points : 0),
  );

  Future<void> _toggleSubstep(int index, bool value) async {
    final previousValue = _completed[index];
    setState(() => _completed[index] = value);

    final completedIds = [
      for (var stepIndex = 0; stepIndex < widget.substeps.length; stepIndex++)
        if (_completed[stepIndex]) widget.substeps[stepIndex].id,
    ];
    final saved = await context
        .read<ChallengeProvider>()
        .updateCompletedSubsteps(
          challengeId: widget.challengeId ?? '',
          completedSubstepIds: completedIds,
          pointsEarned: _earnedPoints,
          totalSubsteps: widget.substeps.length,
        );
    if (!saved && mounted) {
      setState(() => _completed[index] = previousValue);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<ChallengeProvider>().errorMessage ??
                'Unable to save substep progress.',
          ),
        ),
      );
    }
  }
}

class _ChallengeHero extends StatelessWidget {
  const _ChallengeHero({
    required this.title,
    required this.icon,
    required this.iconBackground,
    required this.status,
    required this.joinedByUser,
    required this.points,
  });

  final String title;
  final IconData icon;
  final Color iconBackground;
  final String status;
  final bool joinedByUser;
  final String points;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF13A451),
      padding: const EdgeInsets.fromLTRB(20, 20, 0, 10),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 32, color: const Color(0xFF119447)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 8,
                  children: [
                    _Badge(
                      label: status,
                      color: const Color(0xFFD9F8E5),
                      textColor: const Color(0xFF147541),
                    ),
                    if (joinedByUser)
                      _Badge(
                        label: 'JOINED',
                        color: const Color(0xFFDCE8FF),
                        textColor: const Color(0xFF2E5AA8),
                      ),
                    _Badge(
                      label: points.toUpperCase(),
                      color: const Color(0xFFD9F8E5),
                      textColor: const Color(0xFF147541),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(19, 20, 19, 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFDCE4EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1B3245),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF5B6F8B),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _CircleIcon(icon: Icons.calendar_month_rounded),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF5B6F8B),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF24324A),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: Color(0xFFF0F4F8),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 17, color: Color(0xFF526176)),
    );
  }
}

class _ParticipantAvatars extends StatelessWidget {
  const _ParticipantAvatars();

  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xFF6E8AA7),
      Color(0xFFDB9D73),
      Color(0xFF6C9B7A),
      Color(0xFF8A6F9E),
    ];
    return SizedBox(
      height: 26,
      width: 110,
      child: Stack(
        children: [
          for (var index = 0; index < colors.length; index++)
            Positioned(
              left: index * 18,
              child: CircleAvatar(
                radius: 13,
                backgroundColor: colors[index],
                child: const Icon(
                  Icons.person,
                  size: 15,
                  color: AppColors.white,
                ),
              ),
            ),
          const Positioned(
            left: 72,
            child: CircleAvatar(
              radius: 13,
              backgroundColor: Color(0xFFD9F2E2),
              child: Text(
                '+41',
                style: TextStyle(
                  color: Color(0xFF147541),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.label,
    required this.completed,
    required this.onChanged,
  });

  final String label;
  final bool completed;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!completed),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            SizedBox(
              width: 25,
              height: 25,
              child: Checkbox(
                value: completed,
                onChanged: (value) => onChanged(value ?? false),
                activeColor: const Color(0xFF13A451),
                side: const BorderSide(color: Color(0xFFD5DEE8), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: const Color(0xFF24324A),
                  fontSize: 14,
                  decoration: completed ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressContent extends StatelessWidget {
  const _ProgressContent({
    required this.progress,
    required this.completedCount,
    required this.totalCount,
    required this.earnedPoints,
    required this.points,
  });

  final double progress;
  final int completedCount;
  final int totalCount;
  final int earnedPoints;
  final String points;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progress',
              style: TextStyle(
                color: Color(0xFF526176),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '$percent%',
              style: const TextStyle(
                color: Color(0xFF0D9B49),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: const Color(0xFFEDF1F4),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF10A64F)),
          ),
        ),
        const SizedBox(height: 13),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$completedCount of $totalCount actions completed',
              style: const TextStyle(color: Color(0xFF5B6F8B), fontSize: 12),
            ),
            Text(
              '$earnedPoints / $points pts earned',
              style: const TextStyle(
                color: Color(0xFF0D9B49),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
