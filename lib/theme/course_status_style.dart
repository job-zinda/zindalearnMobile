import 'package:flutter/material.dart';

/// Visual identity for a course's instructor workflow status, mirroring the
/// web app's status pills (draft | pending | published | declined).
class CourseStatusStyle {
  final String label;
  final Color color;
  final Color background;
  final IconData? icon;

  const CourseStatusStyle({
    required this.label,
    required this.color,
    required this.background,
    this.icon,
  });

  static const _map = {
    'draft': CourseStatusStyle(
      label: 'Draft',
      color: Color(0xFF1A1208),
      background: Color(0xFFEDEBE5),
    ),
    'pending': CourseStatusStyle(
      label: 'Pending',
      color: Color(0xFF92400E),
      background: Color(0xFFFEF3C7),
      icon: Icons.access_time_rounded,
    ),
    'published': CourseStatusStyle(
      label: 'Published',
      color: Color(0xFF047857),
      background: Color(0xFFD1FAE5),
      icon: Icons.check_circle_rounded,
    ),
    'declined': CourseStatusStyle(
      label: 'Declined',
      color: Color(0xFFBE123C),
      background: Color(0xFFFFE4E6),
      icon: Icons.error_rounded,
    ),
  };

  static CourseStatusStyle of(String? status) {
    return _map[(status ?? 'draft').toLowerCase().trim()] ?? _map['draft']!;
  }

  static const List<String> workflowOrder = [
    'draft',
    'pending',
    'published',
    'declined',
  ];
}
