import 'package:flutter/material.dart';

class IssueCategory {
  final String name;
  final String subtitle;
  final IconData icon;

  const IssueCategory({
    required this.name,
    required this.subtitle,
    required this.icon,
  });
}

class AppConstants {
  static const List<IssueCategory> issueCategories = [
    IssueCategory(
      name: 'Waste',
      subtitle: 'Litter, dumping',
      icon: Icons.delete_outline_rounded,
    ),
    IssueCategory(
      name: 'Water',
      subtitle: 'Leaks, pollution',
      icon: Icons.water_drop_outlined,
    ),
    IssueCategory(
      name: 'Energy',
      subtitle: 'Wasted power',
      icon: Icons.bolt_outlined,
    ),
    IssueCategory(
      name: 'Recycling',
      subtitle: 'Improper sorting',
      icon: Icons.recycling_outlined,
    ),
    IssueCategory(
      name: 'Air Quality',
      subtitle: 'Smoke, odors',
      icon: Icons.air_rounded,
    ),
    IssueCategory(
      name: 'Other',
      subtitle: 'Different issue',
      icon: Icons.more_horiz_rounded,
    ),
  ];
}