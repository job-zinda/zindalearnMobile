import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/enrollment_model.dart';
import '../providers/auth_provider.dart';
import '../providers/course_provider.dart';
import '../providers/enrollment_provider.dart';
import '../theme/app_colors.dart';
import '../theme/category_style.dart';
import '../widgets/app_drawer.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/course_card.dart';
import '../widgets/course_thumbnail.dart';
import '../widgets/menu_button.dart';
import 'course_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int>? onNavTap;
  const HomeScreen({super.key, this.onNavTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;

  // (apiValue, label)
  static const _categories = <MapEntry<String, String>>[
    MapEntry('development', 'Development'),
    MapEntry('business', 'Business'),
    MapEntry('design', 'Design'),
    MapEntry('it', 'IT'),
    MapEntry('finance', 'Finance'),
    MapEntry('marketing', 'Marketing'),
  ];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entryFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut),
    );
    _entrySlide =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic),
    );
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  void _openCourseByCategory(String category) {
    context.read<CourseProvider>().setCategory(category);
    widget.onNavTap?.call(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: const AppDrawer(),
      body: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _entryFade,
          child: SlideTransition(
            position: _entrySlide,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _greeting(),
                  _searchBar(),
                  _continueLearning(),
                  _categoriesSection(),
                  _popularSection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: ZLBottomNav(
        currentIndex: 0,
        onTap: (i) => widget.onNavTap?.call(i),
      ),
    );
  }

  // ---------------- Greeting ----------------

  Widget _greeting() {
    final user = context.watch<AuthProvider>().user;
    final firstName = (user?.name ?? 'Learner').trim().split(' ').first;
    final initials =
        firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning,'
        : hour < 17
            ? 'Good afternoon,'
            : 'Good evening,';

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      child: Row(
        children: [
          const ZLMenuButton(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: GoogleFonts.dmSans(
                      fontSize: 13, color: AppColors.faint),
                ),
                Text(
                  '$firstName 👋',
                  style: GoogleFonts.dmSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration:
                const BoxDecoration(shape: BoxShape.circle, color: AppColors.brand),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: GestureDetector(
        onTap: () => widget.onNavTap?.call(1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded,
                  size: 20, color: AppColors.faint),
              const SizedBox(width: 10),
              Text(
                'Search courses, topics, skills…',
                style: GoogleFonts.dmSans(
                    fontSize: 14, color: AppColors.faint),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Continue learning ----------------

  Widget _continueLearning() {
    final enrollment = context.watch<EnrollmentProvider>();
    final inProgress = enrollment.inProgress;
    if (inProgress.isEmpty) return const SizedBox.shrink();

    // Most recent enrollment (list is already sorted newest-first by API).
    final current = inProgress.first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: _ContinueCard(
        enrollment: current,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CourseDetailScreen(
              courseId: current.course!.id,
              initialCourse: current.course,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Categories ----------------

  Widget _categoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
          child: Text(
            'Categories',
            style: GoogleFonts.dmSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: _categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final entry = _categories[i];
              final style = CategoryStyle.of(entry.key);
              return GestureDetector(
                onTap: () => _openCourseByCategory(entry.key),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Text(style.emoji,
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        entry.value,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.placeholder,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ---------------- Popular ----------------

  Widget _popularSection() {
    final provider = context.watch<CourseProvider>();
    final enrollment = context.watch<EnrollmentProvider>();
    final courses = provider.courses.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Popular Courses',
                style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              GestureDetector(
                onTap: () => widget.onNavTap?.call(1),
                child: Text(
                  'View all ›',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brand,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (provider.isLoading && courses.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.brand),
            ),
          )
        else if (courses.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
            child: Text(
              'No courses available yet.',
              style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.muted),
            ),
          )
        else
          SizedBox(
            height: 312,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              itemCount: courses.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (_, i) {
                final course = courses[i];
                return SizedBox(
                  width: 250,
                  child: CourseCard(
                    course: course,
                    isEnrolled: enrollment.isEnrolled(course.id),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CourseDetailScreen(
                          courseId: course.id,
                          initialCourse: course,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final EnrollmentModel enrollment;
  final VoidCallback onTap;
  const _ContinueCard({required this.enrollment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final course = enrollment.course!;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.brand,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.brand.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CONTINUE LEARNING',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                CourseThumbnail(
                  imageUrl: course.thumbnail,
                  category: course.category,
                  height: 48,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        course.instructor.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    'Resume',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brand,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (enrollment.progress.clamp(0, 100)) / 100.0,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${enrollment.progress}% complete',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
