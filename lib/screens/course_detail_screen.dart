import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants/feature_flags.dart';
import '../core/network/api_exceptions.dart';
import '../core/utils/formatters.dart';
import '../models/course_model.dart';
import '../providers/enrollment_provider.dart';
import '../services/course_service.dart';
import '../theme/app_colors.dart';
import 'course_promo_player_screen.dart';
import 'lesson_player_screen.dart';
import 'payment_coming_soon_screen.dart';
import '../theme/category_style.dart';
import '../widgets/course_thumbnail.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;

  /// Optional lightweight course used for an instant first paint while the
  /// full course (with curriculum) loads.
  final CourseModel? initialCourse;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
    this.initialCourse,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final _service = CourseService();
  CourseModel? _course;
  String? _error;
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _course = widget.initialCourse;
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final course = await _service.getCourse(widget.courseId);
      if (!mounted) return;
      setState(() {
        _course = course;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Unable to load this course.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final course = _course;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _appBar(),
          Expanded(
            child: course == null
                ? (_error != null
                      ? _errorView()
                      : const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.brand,
                          ),
                        ))
                : _content(course),
          ),
          if (course != null) _stickyCta(course),
        ],
      ),
    );
  }

  Widget _appBar() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Course Detail',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 15, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                setState(() => _error = null);
                _fetch();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(CourseModel course) {
    final style = CategoryStyle.of(course.category);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: Stack(
              children: [
                CourseThumbnail(
                  imageUrl: course.thumbnail,
                  category: course.category,
                  height: 190,
                  borderRadius: BorderRadius.circular(20),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      style.label,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: style.accent,
                      ),
                    ),
                  ),
                ),
                if (course.previewVideo != null &&
                    course.previewVideo!.isNotEmpty)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.18),
                        child: InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CoursePromoPlayerScreen(
                                videoUrl: course.previewVideo!,
                                title: course.title,
                              ),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.play_circle_fill_rounded,
                              size: 56,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Title + instructor + meta + price
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: GoogleFonts.dmSans(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: style.accent,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        course.instructor.initial,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      course.instructor.name,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppColors.placeholder,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    _meta(
                      '⭐',
                      Formatters.rating(course.rating, course.totalRatings),
                    ),
                    _meta('📖', Formatters.lessons(course.totalLessons)),
                    _meta('⏱', Formatters.duration(course.totalDuration)),
                    _meta('🎯', course.level),
                  ],
                ),
                if (FeatureFlags.showCoursePricing) ...[
                  const SizedBox(height: 14),
                  _priceRow(course),
                ],
              ],
            ),
          ),

          // Tabs
          _tabBar(),
          const SizedBox(height: 16),
          if (_activeTab == 0) _overview(course),
          if (_activeTab == 1) _curriculum(course),
          if (_activeTab == 2) _reviews(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _meta(String icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 5),
        Text(
          text,
          style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _priceRow(CourseModel course) {
    if (course.isFree) {
      return Text(
        'Free',
        style: GoogleFonts.dmSans(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: AppColors.brand,
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          Formatters.price(course.effectivePrice),
          style: GoogleFonts.dmSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        if (course.hasDiscount) ...[
          const SizedBox(width: 10),
          Text(
            Formatters.price(course.price),
            style: GoogleFonts.dmSans(
              fontSize: 15,
              color: AppColors.faint,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.yellow,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              '${course.discountPercent}% OFF',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.yellowText,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _tabBar() {
    const labels = ['Overview', 'Curriculum', 'Reviews'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          Row(
            children: List.generate(labels.length, (i) {
              final active = _activeTab == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activeTab = i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: active ? AppColors.brand : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? AppColors.brand : AppColors.faint,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const Divider(height: 1, color: AppColors.border),
        ],
      ),
    );
  }

  Widget _overview(CourseModel course) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (course.description.isNotEmpty)
            Text(
              course.description,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                height: 1.55,
                color: AppColors.placeholder,
              ),
            ),
          if (course.whatYouWillLearn.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              "What you'll learn",
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            ...course.whatYouWillLearn.map(_bullet),
          ],
          if (course.requirements.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Requirements',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            ...course.requirements.map((r) => _bullet(r, dot: true)),
          ],
        ],
      ),
    );
  }

  Widget _bullet(String text, {bool dot = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          dot
              ? const Padding(
                  padding: EdgeInsets.only(top: 6, right: 10),
                  child: Icon(Icons.circle, size: 6, color: AppColors.brand),
                )
              : const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.check_rounded,
                    size: 17,
                    color: AppColors.brand,
                  ),
                ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                height: 1.45,
                color: AppColors.placeholder,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _curriculum(CourseModel course) {
    if (course.modules.isEmpty) {
      return _emptyTab('Curriculum coming soon');
    }
    final enrolled = context.read<EnrollmentProvider>().isEnrolled(course.id);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var m = 0; m < course.modules.length; m++)
            _ModuleTile(
              index: m + 1,
              module: course.modules[m],
              enrolled: enrolled,
              onLessonTap: (lessonIndex) => _openLesson(course, m, lessonIndex),
            ),
        ],
      ),
    );
  }

  void _openLesson(CourseModel course, int moduleIndex, int lessonIndex) {
    final enrolled = context.read<EnrollmentProvider>().isEnrolled(course.id);
    final lesson = course.modules[moduleIndex].lessons[lessonIndex];
    if (!enrolled && !lesson.isFree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enroll in this course to unlock this lesson.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LessonPlayerScreen(
          course: course,
          enrolled: enrolled,
          initialModuleIndex: moduleIndex,
          initialLessonIndex: lessonIndex,
        ),
      ),
    );
  }

  Widget _reviews() => _emptyTab('No reviews yet');

  Widget _emptyTab(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.faint),
        ),
      ),
    );
  }

  // ---------------- Sticky CTA ----------------

  Widget _stickyCta(CourseModel course) {
    final enrollment = context.watch<EnrollmentProvider>();
    final enrolled = enrollment.isEnrolled(course.id);
    final enrolling = enrollment.isEnrolling(course.id);
    final showPriceBlock = !enrolled && FeatureFlags.showCoursePricing;
    final wideButton = enrolled || !FeatureFlags.showCoursePricing;

    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        12,
        18,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Row(
        children: [
          if (showPriceBlock) ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    course.isFree
                        ? 'Free'
                        : Formatters.price(course.effectivePrice),
                    style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  if (course.hasDiscount)
                    Text(
                      '${course.discountPercent}% off',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF059669),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: wideButton ? 1 : 0,
            child: _CtaButton(
              enrolled: enrolled,
              loading: enrolling,
              wide: wideButton,
              label: enrolled ? 'Continue learning' : 'Enroll Now',
              onTap: enrolling
                  ? null
                  : () => enrolled
                        ? _openLearning(course)
                        : course.isFree
                        ? _confirmEnroll(course)
                        : _showPaymentComingSoon(course),
            ),
          ),
        ],
      ),
    );
  }

  void _openLearning(CourseModel course) {
    for (var m = 0; m < course.modules.length; m++) {
      if (course.modules[m].lessons.isNotEmpty) {
        _openLesson(course, m, 0);
        return;
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No lessons have been added to this course yet.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPaymentComingSoon(CourseModel course) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentComingSoonScreen(course: course),
      ),
    );
  }

  Future<void> _confirmEnroll(CourseModel course) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _EnrollSheet(course: course),
    );
    if (confirmed != true || !mounted) return;

    final error = await context.read<EnrollmentProvider>().enroll(course.id);
    if (!mounted) return;

    if (error == null) {
      // Refresh to reflect the `enrolled` flag on the course.
      _fetch();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enrolled in "${course.title}" 🎉'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.brand,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
      );
    }
  }
}

class _ModuleTile extends StatelessWidget {
  final int index;
  final Module module;
  final bool enrolled;
  final ValueChanged<int> onLessonTap;
  const _ModuleTile({
    required this.index,
    required this.module,
    required this.enrolled,
    required this.onLessonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(
            'Section $index · ${module.title}',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              Formatters.lessons(module.lessons.length),
              style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted),
            ),
          ),
          children: [
            for (var l = 0; l < module.lessons.length; l++)
              _LessonRow(
                lesson: module.lessons[l],
                enrolled: enrolled,
                onTap: () => onLessonTap(l),
              ),
          ],
        ),
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  final Lesson lesson;
  final bool enrolled;
  final VoidCallback onTap;
  const _LessonRow({
    required this.lesson,
    required this.enrolled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locked = !enrolled && !lesson.isFree;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: locked ? AppColors.border : AppColors.brandFaint,
              ),
              child: Icon(
                locked ? Icons.lock_outline_rounded : Icons.play_arrow_rounded,
                size: 15,
                color: locked ? AppColors.faint : AppColors.brand,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                lesson.title,
                style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.ink),
              ),
            ),
            if (lesson.isFree && !enrolled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppColors.brandFaint,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'Free',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brand,
                  ),
                ),
              ),
            Text(
              lesson.duration > 0 ? Formatters.duration(lesson.duration) : '',
              style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.faint),
            ),
          ],
        ),
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  final bool enrolled;
  final bool loading;
  final bool wide;
  final String label;
  final VoidCallback? onTap;

  const _CtaButton({
    required this.enrolled,
    required this.loading,
    required this.wide,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: wide ? double.infinity : null,
      padding: EdgeInsets.symmetric(horizontal: wide ? 20 : 34, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Text(
              enrolled ? label : '$label  →',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
    );
    return GestureDetector(onTap: onTap, child: child);
  }
}

class _EnrollSheet extends StatelessWidget {
  final CourseModel course;
  const _EnrollSheet({required this.course});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Enroll in this course',
              style: GoogleFonts.dmSans(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              course.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.muted),
            ),
            if (FeatureFlags.showCoursePricing) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    course.isFree
                        ? 'Free'
                        : Formatters.price(course.effectivePrice),
                    style: GoogleFonts.dmSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brand,
                    ),
                  ),
                  if (course.hasDiscount) ...[
                    const SizedBox(width: 10),
                    Text(
                      Formatters.price(course.price),
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: AppColors.faint,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.placeholder,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.brand,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Confirm',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
