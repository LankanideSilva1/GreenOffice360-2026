enum LeaderboardScope { departments, individuals }

enum LeaderboardPeriod { week, month, allTime }

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.points,
    required this.progress,
    this.userId,
    this.department,
    this.isCurrentUser = false,
    this.previousRank,
  });

  final int rank;
  final String name;
  final int points;
  final double progress;
  final String? userId;
  final String? department;
  final bool isCurrentUser;
  final int? previousRank;

  String get avatarLabel {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      final value = parts.first;
      return value.substring(0, value.length.clamp(0, 2)).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class LeaderboardData {
  const LeaderboardData({
    required this.entries,
    required this.currentUser,
    required this.nextEntry,
  });

  final List<LeaderboardEntry> entries;
  final LeaderboardEntry? currentUser;
  final LeaderboardEntry? nextEntry;
}
