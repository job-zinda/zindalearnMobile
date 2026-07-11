import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/course_provider.dart';
import '../providers/enrollment_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/enrolled_course_card.dart';
import '../widgets/menu_button.dart';
import '../widgets/shimmer.dart';
import 'course_detail_screen.dart';

class MyLearningScreen extends StatefulWidget {
  final ValueChanged<int>? onNavTap;
  final int currentIndex;
  const MyLearningScreen({
    super.key,
    this.onNavTap,
    this.currentIndex = 2,
  });

  @override
  State<MyLearningScreen> createState() => _MyLearningScreenState();
}

class _MyLearningScreenState extends State<MyLearningScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EnrollmentProvider>();
      if (provider.state == LoadState.idle) {
        provider.loadEnrollments(refresh: true);
      }
    });
  }

  void _goBrowse() => widget.onNavTap?.call(1);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EnrollmentProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: const AppDrawer(),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.brand,
          onRefresh: () => provider.loadEnrollments(refresh: true),
          child: CustomScrollView(
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

  Widget _header(EnrollmentProvider provider) {
    final inProgress = provider.inProgress.length;
    final completed = provider.completed.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ZLMenuButton(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Learning',
                      style: GoogleFonts.dmSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your learning journey continues here',
                      style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (provider.state == LoadState.loaded &&
              provider.enrollments.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _StatChip(
                  emoji: '📚',
                  value: '${provider.enrollments.length}',
                  label: 'Enrolled',
                ),
                const SizedBox(width: 10),
                _StatChip(
                  emoji: '🔥',
                  value: '$inProgress',
                  label: 'In progress',
                ),
                const SizedBox(width: 10),
                _StatChip(
                  emoji: '🎓',
                  value: '$completed',
                  label: 'Completed',
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _body(EnrollmentProvider provider) {
    if (provider.state == LoadState.loading && provider.enrollments.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        sliver: SliverList.separated(
          itemCount: 3,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (_, _) => const _EnrolledSkeleton(),
        ),
      );
    }

    if (provider.state == LoadState.error && provider.enrollments.isEmpty) {
      return SliverToBoxAdapter(
        child: _ErrorState(
          message: provider.error ?? 'Please try again.',
          onRetry: () => provider.loadEnrollments(refresh: true),
        ),
      );
    }

    if (provider.isEmpty) {
      return SliverToBoxAdapter(child: _EmptyState(onBrowse: _goBrowse));
    }

    final items = provider.enrollments;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      sliver: SliverList.separated(
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          final e = items[i];
          return EnrolledCourseCard(
            enrollment: e,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CourseDetailScreen(
                  courseId: e.course!.id,
                  initialCourse: e.course,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _StatChip({
    required this.emoji,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onBrowse;
  const _EmptyState({required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandFaint,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  size: 44, color: AppColors.brand),
            ),
            const SizedBox(height: 20),
            Text(
              'Your learning journey begins here',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Discover new skills and enroll in courses to '
              'start building your future.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                height: 1.5,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: onBrowse,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Browse Courses',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 18, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 60, 32, 40),
      child: Column(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 46)),
          const SizedBox(height: 14),
          Text(
            'Couldn’t load your courses',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
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
    );
  }
}

class _EnrolledSkeleton extends StatelessWidget {
  const _EnrolledSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              ShimmerBox(
                width: 90,
                height: 62,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 80, height: 10),
                    SizedBox(height: 8),
                    ShimmerBox(height: 15),
                    SizedBox(height: 6),
                    ShimmerBox(width: 120, height: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const ShimmerBox(height: 6),
          const SizedBox(height: 12),
          const ShimmerBox(
            height: 40,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ],
      ),
    );
  }
}
