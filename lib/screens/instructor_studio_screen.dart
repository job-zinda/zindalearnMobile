import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants/feature_flags.dart';
import '../core/network/api_exceptions.dart';
import '../core/utils/formatters.dart';
import '../models/course_model.dart';
import '../providers/course_provider.dart' show LoadState;
import '../providers/instructor_provider.dart';
import '../theme/app_colors.dart';
import '../theme/course_status_style.dart';
import '../widgets/course_thumbnail.dart';
import 'instructor/create_edit_course_screen.dart';
import 'instructor/instructor_course_detail_screen.dart';
import 'instructor/instructor_live_classes_screen.dart';

/// The one extra screen instructors get on top of the regular student app —
/// reachable from the side drawer. Lets an instructor see their course
/// stats, create a course, and manage/submit existing ones for review, the
/// same way the web app's instructor portal does. No client-side eligibility
/// gating: the backend is the source of truth for what an account can do.
class InstructorStudioScreen extends StatefulWidget {
  const InstructorStudioScreen({super.key});

  @override
  State<InstructorStudioScreen> createState() => _InstructorStudioScreenState();
}

class _InstructorStudioScreenState extends State<InstructorStudioScreen> {
  static const _filters = ['All', 'Draft', 'Pending', 'Published', 'Declined'];
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<InstructorProvider>();
      provider.loadStats();
      if (provider.myCoursesState == LoadState.idle) {
        provider.loadMyCourses(refresh: true);
      }
    });
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >
          _scrollCtrl.position.maxScrollExtent - 200) {
        context.read<InstructorProvider>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.red : AppColors.brand,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _createCourse() async {
    final created = await Navigator.of(context).push<CourseModel>(
      MaterialPageRoute(builder: (_) => const CreateEditCourseScreen()),
    );
    if (created != null && mounted) {
      _showSnack('Course created successfully!');
    }
  }

  Future<void> _delete(CourseModel course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete course?'),
        content: Text('Delete "${course.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await context.read<InstructorProvider>().deleteCourse(course.id);
      if (!mounted) return;
      _showSnack('Course deleted');
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final instructor = context.watch<InstructorProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.brand,
          onRefresh: () => Future.wait([
            context.read<InstructorProvider>().loadStats(),
            context.read<InstructorProvider>().loadMyCourses(refresh: true),
          ]),
          child: CustomScrollView(
            controller: _scrollCtrl,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: _header(context)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                  child: _StatsGrid(stats: instructor.stats),
                ),
              ),
              SliverToBoxAdapter(child: _createButton()),
              SliverToBoxAdapter(child: _filterChips(instructor)),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              ..._courseSlivers(instructor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instructor Studio',
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  'Create and manage your courses.',
                  style: GoogleFonts.dmSans(
                    fontSize: 12.5,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _createButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _createCourse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_circle_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Create Course',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Tooltip(
            message: 'Live Classes',
            child: SizedBox(
              height: 50,
              width: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const InstructorLiveClassesScreen(),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  side: const BorderSide(color: AppColors.border, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Icon(
                  Icons.videocam_outlined,
                  color: AppColors.brand,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChips(InstructorProvider instructor) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final filter = _filters[i];
          final active = instructor.statusFilter == filter;
          return GestureDetector(
            onTap: () =>
                context.read<InstructorProvider>().setStatusFilter(filter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active ? AppColors.brand : Colors.white,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: active ? AppColors.brand : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: Text(
                filter,
                style: GoogleFonts.dmSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppColors.muted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _courseSlivers(InstructorProvider instructor) {
    if (instructor.myCoursesState == LoadState.loading &&
        instructor.myCourses.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.brand),
            ),
          ),
        ),
      ];
    }

    if (instructor.myCoursesState == LoadState.error &&
        instructor.myCourses.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  instructor.myCoursesError ?? 'Something went wrong.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => context
                      .read<InstructorProvider>()
                      .loadMyCourses(refresh: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    if (instructor.myCourses.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No courses found. Create your first course to get started.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 13.5, color: AppColors.muted),
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
        sliver: SliverList.separated(
          itemCount: instructor.myCourses.length + (instructor.hasMore ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            if (i >= instructor.myCourses.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.brand,
                    ),
                  ),
                ),
              );
            }
            final course = instructor.myCourses[i];
            return _CourseCard(
              course: course,
              onManage: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      InstructorCourseDetailScreen(courseId: course.id),
                ),
              ),
              onDelete: () => _delete(course),
            );
          },
        ),
      ),
    ];
  }
}

class _StatsGrid extends StatelessWidget {
  final dynamic stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        icon: Icons.menu_book_rounded,
        color: AppColors.brand,
        bg: AppColors.brandFaint,
        label: 'Total Courses',
        value: '${stats.totalCourses}',
      ),
      (
        icon: Icons.people_alt_rounded,
        color: const Color(0xFFEA580C),
        bg: const Color(0xFFFFEDD5),
        label: 'Total Students',
        value: '${stats.totalStudents}',
      ),
      (
        icon: Icons.currency_rupee_rounded,
        color: const Color(0xFF059669),
        bg: const Color(0xFFD1FAE5),
        label: 'Total Revenue',
        value: '₹${Formatters.rupees(stats.totalRevenue)}',
      ),
      (
        icon: Icons.trending_up_rounded,
        color: const Color(0xFF2563EB),
        bg: const Color(0xFFDBEAFE),
        label: 'Monthly Earnings',
        value: '₹${Formatters.rupees(stats.monthlyEarnings)}',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: items.map((it) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: it.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(it.icon, size: 17, color: it.color),
              ),
              const SizedBox(height: 8),
              Text(
                it.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                it.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onManage;
  final VoidCallback onDelete;
  const _CourseCard({
    required this.course,
    required this.onManage,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final status = CourseStatusStyle.of(course.status);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CourseThumbnail(
                imageUrl: course.thumbnail,
                category: course.category,
                height: 120,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: status.background,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (status.icon != null) ...[
                        Icon(status.icon, size: 12, color: status.color),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        status.label,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: status.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (FeatureFlags.showCoursePricing) ...[
                      Text(
                        course.isFree
                            ? 'Free'
                            : Formatters.price(course.effectivePrice),
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brand,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    const Icon(
                      Icons.people_outline_rounded,
                      size: 14,
                      color: AppColors.faint,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${course.totalStudents} Students',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onManage,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.brand,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      'Manage Course →',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brand,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
