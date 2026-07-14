import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/enrollment_model.dart';
import '../theme/app_colors.dart';
import '../theme/category_style.dart';
import 'course_thumbnail.dart';

/// A horizontal progress card for the "My Learning" list.
class EnrolledCourseCard extends StatelessWidget {
  final EnrollmentModel enrollment;
  final VoidCallback onTap;

  const EnrolledCourseCard({
    super.key,
    required this.enrollment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final course = enrollment.course!;
    final style = CategoryStyle.of(course.category);
    final progress = (enrollment.progress.clamp(0, 100)) / 100.0;
    final completed = enrollment.isCompleted;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 62,
                  child: CourseThumbnail(
                    imageUrl: course.thumbnail,
                    category: course.category,
                    height: 62,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              style.label.toUpperCase(),
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: style.accent,
                              ),
                            ),
                          ),
                          if (completed)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🎓',
                                    style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 3),
                                Text(
                                  'Completed',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        course.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        course.instructor.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        completed ? const Color(0xFF059669) : AppColors.brand,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${enrollment.progress}%',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // CTA
            SizedBox(
              width: double.infinity,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: completed ? AppColors.brandFaint : AppColors.brand,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  completed
                      ? 'Review course'
                      : enrollment.notStarted
                          ? 'Start learning'
                          : 'Continue learning',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: completed ? AppColors.brand : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
