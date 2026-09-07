import 'package:flutter/material.dart';
import 'package:greenoffice360/core/constants/app_colors.dart';
import 'package:greenoffice360/features/auth/providers/auth_provider.dart';
import 'package:greenoffice360/features/gamification/screens/challenge_detail_screen.dart';
import 'package:greenoffice360/features/gamification/providers/challenge_provider.dart';
import 'package:greenoffice360/models/challenge_model.dart';
import 'package:provider/provider.dart';

class ChallengeListScreen extends StatefulWidget {
  const ChallengeListScreen({super.key});

  @override
  State<ChallengeListScreen> createState() => _ChallengeListScreenState();
}

class _ChallengeListScreenState extends State<ChallengeListScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ChallengeProvider>().loadChallenges();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final challengeProvider = context.watch<ChallengeProvider>();
    final query = _searchController.text.trim().toLowerCase();
    final visibleChallenges = challengeProvider.challenges.where((challenge) {
      final matchesSearch =
          query.isEmpty ||
          challenge.title.toLowerCase().contains(query) ||
          challenge.description.toLowerCase().contains(query);
      final matchesFilter =
          _selectedFilter == 'All' ||
          challenge.statusLabel == _selectedFilter.toUpperCase();
      return matchesSearch && matchesFilter;
    }).toList();

    final user = context.watch<AuthProvider?>()?.user;

    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 18),
        _buildSummary(challengeProvider.challenges.length, user?.points ?? 0),
        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search challenges...',
            prefixIcon: const Icon(Icons.search_rounded, size: 22),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD9E1E8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD9E1E8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildFilters(),
        const SizedBox(height: 16),
        Expanded(
          child:
              challengeProvider.isLoading &&
                  challengeProvider.challenges.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : challengeProvider.status == ChallengeStatus.error
              ? Center(
                  child: Text(
                    challengeProvider.errorMessage ??
                        'Unable to load challenges',
                  ),
                )
              : visibleChallenges.isEmpty
              ? const Center(child: Text('No challenges found'))
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: visibleChallenges.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final challenge = visibleChallenges[index];
                    return _ChallengeCard(
                      challenge: challenge,
                      onTap: () => _openChallenge(context, challenge),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _openChallenge(
    BuildContext context,
    ChallengeModel challenge,
  ) async {
    try {
      final challengeProvider = context.read<ChallengeProvider>();
      final joined = await challengeProvider.joinChallenge(challenge.id);
      if (!joined) {
        throw StateError(
          challengeProvider.errorMessage ?? 'Unable to join challenge.',
        );
      }
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChallengeDetailScreen(
            challengeId: challenge.id,
            title: challenge.title,
            description: challenge.description,
            icon: Icons.recycling_rounded,
            iconBackground: const Color(0xFFE0F4FF),
            duration: challenge.durationLabel,
            joined: challenge.joinedLabel,
            points: challenge.pointsLabel,
            progress: challenge.progress,
            status: challenge.statusLabel,
            joinedByUser: true,
            substeps: challenge.substeps,
            completedSubstepIds: challenge.completedSubstepIds,
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to join challenge: $error')),
      );
    }
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFE3F5E9),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(Icons.eco_rounded, color: AppColors.darkGreen),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Challenges',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Challenge settings',
          onPressed: () {},
          icon: const Icon(Icons.tune_rounded),
          style: IconButton.styleFrom(
            foregroundColor: AppColors.textDark,
            backgroundColor: AppColors.white,
            side: const BorderSide(color: Color(0xFFD9E1E8)),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(int challengeCount, int userPoints) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF13A451),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Active Challenges: $challengeCount', style: _summaryStyle),
          Text('Your Points: $userPoints', style: _summaryStyle),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: ['All', 'Active', 'Upcoming'].map((filter) {
        final selected = _selectedFilter == filter;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(filter),
            selected: selected,
            onSelected: (_) => setState(() => _selectedFilter = filter),
            labelStyle: TextStyle(
              color: selected ? AppColors.white : const Color(0xFF60718A),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: AppColors.white,
            selectedColor: const Color(0xFF13A451),
            side: const BorderSide(color: Color(0xFFD9E1E8)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 6),
          ),
        );
      }).toList(),
    );
  }
}

const _summaryStyle = TextStyle(
  color: AppColors.white,
  fontSize: 13,
  fontWeight: FontWeight.w700,
);

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.challenge, required this.onTap});

  final ChallengeModel challenge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progressPercent = (challenge.progress * 100).round();
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
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
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F4FF),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.recycling_rounded,
                      color: Color(0xFF119447),
                    ),
                  ),
                  const Spacer(),
                  if (challenge.joinedByUser) ...[
                    const _StatusBadge(label: 'JOINED', joined: true),
                    const SizedBox(width: 6),
                  ],
                  _StatusBadge(
                    label: challenge.statusLabel,
                    joined: challenge.statusLabel == 'UPCOMING',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                challenge.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                challenge.description,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF526987),
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _MetaBadge(
                    icon: Icons.calendar_month_rounded,
                    label: challenge.durationLabel,
                  ),
                  _MetaBadge(
                    icon: Icons.person_rounded,
                    label: challenge.joinedLabel,
                  ),
                  _MetaBadge(
                    icon: Icons.star_rounded,
                    label: challenge.pointsLabel,
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: Color(0xFFDCE4EB)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progress',
                    style: TextStyle(
                      color: Color(0xFF526176),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$progressPercent%',
                    style: const TextStyle(
                      color: Color(0xFF0D9B49),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: challenge.progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFEDF1F4),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF10A64F)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.joined});

  final String label;
  final bool joined;

  @override
  Widget build(BuildContext context) {
    final isUpcoming = label == 'UPCOMING';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isUpcoming
            ? const Color(0xFFFFF0BF)
            : joined
            ? const Color(0xFFDCE8FF)
            : const Color(0xFFD9F8E5),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isUpcoming
              ? const Color(0xFFA45A00)
              : joined
              ? const Color(0xFF2E5AA8)
              : const Color(0xFF147541),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF526176)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF526176),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
