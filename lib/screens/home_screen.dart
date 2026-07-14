import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/banner_model.dart';
import '../models/enrollment_model.dart';
import '../models/progress_model.dart';
import '../providers/auth_provider.dart';
import '../providers/course_provider.dart';
import '../providers/enrollment_provider.dart';
import '../services/banner_service.dart';
import '../services/progress_service.dart';
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

  final _bannerService = BannerService();
  final _progressService = ProgressService();
  List<BannerModel> _banners = [];
  ProgressOverview? _overview;

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
    _loadDashboardExtras();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardExtras() async {
    // Banner and stats are supplementary decoration for the dashboard — a
    // failure to load either shouldn't block or error out the rest of Home.
    try {
      final banners = await _bannerService.getActiveBanners();
      if (mounted) setState(() => _banners = banners);
    } catch (_) {}
    try {
      final overview = await _progressService.getOverview();
      if (mounted) setState(() => _overview = overview);
    } catch (_) {}
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
                  _banner(),
                  _statsRow(),
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

  // ---------------- Promo banner ----------------

  Widget _banner() {
    if (_banners.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: _BannerCarousel(banners: _banners),
    );
  }

  // ---------------- Stats ----------------

  Widget _statsRow() {
    final overview = _overview;
    if (overview == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: [
          _StatCard(
            icon: Icons.menu_book_rounded,
            iconColor: const Color(0xFF2563EB),
            iconBg: const Color(0xFFDBEAFE),
            value: '${overview.totalEnrolled}',
            label: 'Courses Enrolled',
          ),
          _StatCard(
            icon: Icons.access_time_filled_rounded,
            iconColor: AppColors.brand,
            iconBg: AppColors.brandFaint,
            value: overview.watchTimeLabel,
            label: 'Hours Learned',
          ),
          _StatCard(
            icon: Icons.emoji_events_rounded,
            iconColor: const Color(0xFFD97706),
            iconBg: const Color(0xFFFEF3C7),
            value: '${overview.certificates}',
            label: 'Certificates',
          ),
          _StatCard(
            icon: Icons.trending_up_rounded,
            iconColor: const Color(0xFF059669),
            iconBg: const Color(0xFFD1FAE5),
            value: '${overview.points}',
            label: 'Skill Points',
          ),
        ],
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
                SizedBox(
                  width: 48,
                  child: CourseThumbnail(
                    imageUrl: course.thumbnail,
                    category: course.category,
                    height: 48,
                    borderRadius: BorderRadius.circular(10),
                  ),
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            width: 30,
            height: 30,
            decoration:
                BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.dmSans(
                fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.faint,
              letterSpacing: 0.3,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

/// Auto-advancing carousel for admin-configured promo banners — mirrors the
/// web dashboard's BannerCarousel (see zindalearnFEWeb/src/components/
/// BannerCarousel.jsx), 6s autoplay with dot indicators.
class _BannerCarousel extends StatefulWidget {
  final List<BannerModel> banners;
  const _BannerCarousel({required this.banners});

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  late final PageController _pageCtrl;
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    if (widget.banners.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 6), (_) {
        if (!mounted || !_pageCtrl.hasClients) return;
        final next = (_page + 1) % widget.banners.length;
        _pageCtrl.animateToPage(
          next,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _fallbackBg() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandMid, AppColors.brandDark],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 8,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.banners.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) {
              final banner = widget.banners[i];
              return GestureDetector(
                onTap: banner.linkUrl.isNotEmpty ? () => _openLink(banner.linkUrl) : null,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (banner.imageUrl.isNotEmpty)
                        Image.network(
                          banner.imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) =>
                              progress == null ? child : _fallbackBg(),
                          errorBuilder: (context, _, _) => _fallbackBg(),
                        )
                      else
                        _fallbackBg(),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0),
                              Colors.black.withValues(alpha: 0.65),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              banner.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            if (banner.description.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                banner.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12.5,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.banners.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.banners.length, (i) {
              final active = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? AppColors.brand : AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
