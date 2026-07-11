import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/course_provider.dart';
import '../providers/enrollment_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/course_card.dart';
import '../widgets/menu_button.dart';
import '../widgets/shimmer.dart';
import 'course_detail_screen.dart';

class BrowseCoursesScreen extends StatefulWidget {
  final ValueChanged<int>? onNavTap;
  final int currentIndex;
  const BrowseCoursesScreen({
    super.key,
    this.onNavTap,
    this.currentIndex = 1,
  });

  @override
  State<BrowseCoursesScreen> createState() => _BrowseCoursesScreenState();
}

class _BrowseCoursesScreenState extends State<BrowseCoursesScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _debounce;

  // (value sent to API, display label)
  static const _categories = <MapEntry<String?, String>>[
    MapEntry(null, 'All'),
    MapEntry('development', 'Development'),
    MapEntry('business', 'Business'),
    MapEntry('design', 'Design'),
    MapEntry('marketing', 'Marketing'),
    MapEntry('it', 'IT'),
    MapEntry('finance', 'Finance'),
  ];

  static const _levels = <String?>[
    null,
    'Beginner',
    'Intermediate',
    'Advanced',
    'Expert',
  ];

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CourseProvider>();
      if (provider.state == LoadState.idle) {
        provider.loadCourses(refresh: true);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 400) {
      context.read<CourseProvider>().loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      context.read<CourseProvider>().setSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: const AppDrawer(),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.brand,
          onRefresh: () => provider.loadCourses(refresh: true),
          child: CustomScrollView(
            controller: _scrollCtrl,
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(child: _header(provider)),
              _body(provider),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ZLBottomNav(
        currentIndex: widget.currentIndex,
        onTap: (i) => widget.onNavTap?.call(i),
      ),
    );
  }

  // ---------------- Header (title, search, filters) ----------------

  Widget _header(CourseProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Row(
            children: [
              const ZLMenuButton(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Browse Courses',
                      style: GoogleFonts.dmSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Discover new skills from expert-led courses.',
                      style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.ink),
              decoration: InputDecoration(
                hintText: 'Search courses, topics, skills…',
                hintStyle:
                    GoogleFonts.dmSans(fontSize: 14, color: AppColors.faint),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.faint, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.faint, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          context.read<CourseProvider>().setSearch('');
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),

        // Category chips
        _chipRow(
          label: 'CATEGORY',
          children: _categories.map((c) {
            return _FilterChip(
              label: c.value,
              selected: provider.category == c.key,
              onTap: () => provider.setCategory(c.key),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),

        // Level chips
        _chipRow(
          label: 'LEVEL',
          children: _levels.map((lvl) {
            return _FilterChip(
              label: lvl ?? 'All',
              selected: provider.level == lvl,
              onTap: () => provider.setLevel(lvl),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Result count
        if (provider.state == LoadState.loaded)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
            child: Text(
              'Showing ${provider.total} '
              '${provider.total == 1 ? 'course' : 'courses'}',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
          ),
      ],
    );
  }

  Widget _chipRow({required String label, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.faint,
            ),
          ),
        ),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: children.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => children[i],
          ),
        ),
      ],
    );
  }

  // ---------------- Body (list / states) ----------------

  Widget _body(CourseProvider provider) {
    // Initial loading skeletons
    if (provider.state == LoadState.loading && provider.courses.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        sliver: SliverList.separated(
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (_, _) => const _CourseCardSkeleton(),
        ),
      );
    }

    if (provider.state == LoadState.error && provider.courses.isEmpty) {
      return SliverToBoxAdapter(
        child: _StateMessage(
          emoji: '⚠️',
          title: 'Something went wrong',
          subtitle: provider.error ?? 'Please try again.',
          actionLabel: 'Retry',
          onAction: () => provider.loadCourses(refresh: true),
        ),
      );
    }

    if (provider.isEmpty) {
      return SliverToBoxAdapter(
        child: _StateMessage(
          emoji: '🔍',
          title: 'No courses found',
          subtitle: 'Try adjusting your search or filters.',
          actionLabel: 'Clear filters',
          onAction: () {
            _searchCtrl.clear();
            provider.clearFilters();
            setState(() {});
          },
        ),
      );
    }

    final enrollment = context.watch<EnrollmentProvider>();
    final courses = provider.courses;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      sliver: SliverList.separated(
        itemCount: courses.length + (provider.loadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          if (i >= courses.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: AppColors.brand),
                ),
              ),
            );
          }
          final course = courses[i];
          return CourseCard(
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
          );
        },
      ),
    );
  }
}

// ---------------- Reusable pieces ----------------

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.brand : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : AppColors.placeholder,
          ),
        ),
      ),
    );
  }
}

class _CourseCardSkeleton extends StatelessWidget {
  const _CourseCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(
            height: 132,
            borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 120, height: 12),
                SizedBox(height: 10),
                ShimmerBox(height: 16),
                SizedBox(height: 8),
                ShimmerBox(width: 200, height: 16),
                SizedBox(height: 14),
                ShimmerBox(width: 100, height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _StateMessage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 60, 32, 40),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 46)),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                actionLabel,
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
    );
  }
}
