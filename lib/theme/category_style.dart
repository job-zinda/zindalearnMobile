import 'package:flutter/material.dart';

/// Visual identity (accent color, soft gradient, emoji) for each course
/// category. Backend categories are lowercase:
/// development | business | design | marketing | it | finance.
class CategoryStyle {
  final String label;
  final String emoji;
  final Color accent;
  final List<Color> gradient;

  const CategoryStyle({
    required this.label,
    required this.emoji,
    required this.accent,
    required this.gradient,
  });

  static const _fallback = CategoryStyle(
    label: 'Course',
    emoji: '📘',
    accent: Color(0xFF6D28D9),
    gradient: [Color(0xFFEDE9FE), Color(0xFFF5F3FF)],
  );

  static const Map<String, CategoryStyle> _map = {
    'development': CategoryStyle(
      label: 'Development',
      emoji: '💻',
      accent: Color(0xFF6D28D9),
      gradient: [Color(0xFFEDE9FE), Color(0xFFF5F3FF)],
    ),
    'business': CategoryStyle(
      label: 'Business',
      emoji: '📈',
      accent: Color(0xFF0891B2),
      gradient: [Color(0xFFCFFAFE), Color(0xFFECFEFF)],
    ),
    'design': CategoryStyle(
      label: 'Design',
      emoji: '🎨',
      accent: Color(0xFFDB2777),
      gradient: [Color(0xFFFCE7F3), Color(0xFFFDF2F8)],
    ),
    'marketing': CategoryStyle(
      label: 'Marketing',
      emoji: '📣',
      accent: Color(0xFFEA580C),
      gradient: [Color(0xFFFFEDD5), Color(0xFFFFF7ED)],
    ),
    'it': CategoryStyle(
      label: 'IT & Software',
      emoji: '🖥️',
      accent: Color(0xFF2563EB),
      gradient: [Color(0xFFDBEAFE), Color(0xFFEFF6FF)],
    ),
    'finance': CategoryStyle(
      label: 'Finance',
      emoji: '💰',
      accent: Color(0xFF059669),
      gradient: [Color(0xFFD1FAE5), Color(0xFFECFDF5)],
    ),
  };

  static CategoryStyle of(String? category) {
    if (category == null) return _fallback;
    return _map[category.toLowerCase().trim()] ?? _fallback;
  }
}
