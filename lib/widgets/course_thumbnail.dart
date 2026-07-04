import 'package:flutter/material.dart';
import '../theme/category_style.dart';

/// Renders a course thumbnail: the network image when available, otherwise a
/// tasteful category-tinted gradient with the category emoji. Used across the
/// catalog so every course looks intentional even without artwork.
class CourseThumbnail extends StatelessWidget {
  final String? imageUrl;
  final String category;
  final double height;
  final BorderRadius borderRadius;
  final BoxFit fit;

  const CourseThumbnail({
    super.key,
    required this.imageUrl,
    required this.category,
    this.height = 150,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(18)),
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(category);

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: (imageUrl != null && imageUrl!.startsWith('http'))
            ? Image.network(
                imageUrl!,
                fit: fit,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _fallback(style);
                },
                errorBuilder: (context, _, _) => _fallback(style),
              )
            : _fallback(style),
      ),
    );
  }

  Widget _fallback(CategoryStyle style) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: style.gradient,
        ),
      ),
      child: Center(
        child: Opacity(
          opacity: 0.55,
          child: Text(style.emoji, style: const TextStyle(fontSize: 40)),
        ),
      ),
    );
  }
}
