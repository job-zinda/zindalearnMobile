import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/enrollment_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/enrollment_provider.dart';
import '../theme/app_colors.dart';
import '../theme/category_style.dart';
import '../widgets/bottom_nav_bar.dart';
import 'course_detail_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ValueChanged<int>? onNavTap;
  const ProfileScreen({super.key, this.onNavTap});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late AnimationController _bodyCtrl;
  late Animation<double> _bodyFade;
  late Animation<Offset> _bodySlide;

  @override
  void initState() {
    super.initState();

    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _headerFade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic),
    );

    _bodyCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _bodyFade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _bodyCtrl, curve: Curves.easeOut));
    _bodySlide =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _bodyCtrl, curve: Curves.easeOutCubic),
    );

    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _bodyCtrl.forward();
    });
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await Future.wait([
      context.read<AuthProvider>().checkAuthStatus(),
      context.read<EnrollmentProvider>().loadEnrollments(refresh: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final enrollment = context.watch<EnrollmentProvider>();
    final user = auth.user;
    final displayName = user?.name ?? 'Guest';
    final initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final roleLabel = (user?.role ?? 'student').replaceFirst(
      (user?.role ?? 'student')[0],
      (user?.role ?? 'student')[0].toUpperCase(),
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          // Purple gradient header
          FadeTransition(
            opacity: _headerFade,
            child: SlideTransition(
              position: _headerSlide,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                    transform: GradientRotation(160 * 3.14159 / 180),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      const SizedBox(height: 14),
                      // Avatar
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          image: (user?.avatar != null && user!.avatar!.isNotEmpty)
                              ? DecorationImage(
                                  image: NetworkImage(user.avatar!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 2.5,
                          ),
                        ),
                        child: (user?.avatar == null || user!.avatar!.isEmpty)
                            ? Center(
                                child: Text(
                                  initials,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.brand,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        displayName,
                        style: GoogleFonts.dmSans(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          roleLabel,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Stats grid
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            _StatCell(
                                value: '${enrollment.enrollments.length}',
                                label: 'Enrolled'),
                            Container(
                                width: 1,
                                height: 48,
                                color: Colors.white.withValues(alpha: 0.2)),
                            _StatCell(
                                value: '${enrollment.inProgress.length}',
                                label: 'In progress'),
                            Container(
                                width: 1,
                                height: 48,
                                color: Colors.white.withValues(alpha: 0.2)),
                            _StatCell(
                                value: '${enrollment.completed.length}',
                                label: 'Completed'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Scrollable body
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: AppColors.brand,
              child: FadeTransition(
                opacity: _bodyFade,
                child: SlideTransition(
                  position: _bodySlide,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // About (bio + contact info)
                        if (user != null) ...[
                          _AboutCard(user: user),
                          const SizedBox(height: 20),
                        ],

                        // My Courses
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'My Courses',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            if (enrollment.enrollments.isNotEmpty)
                              GestureDetector(
                                onTap: () => widget.onNavTap?.call(2),
                                child: Text(
                                  'View all ›',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.brand,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _myCourses(enrollment),
                        const SizedBox(height: 20),

                        // Account settings
                        Text(
                          'Account',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppColors.border, width: 1.5),
                          ),
                          child: Column(
                            children: [
                              _SettingsRow(
                                label: 'Edit Profile',
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const EditProfileScreen(),
                                  ),
                                ),
                              ),
                              _Divider(),
                              _SettingsRow(label: 'Certificates', onTap: () {}),
                              _Divider(),
                              _SettingsRow(label: 'Help Center', onTap: () {}),
                              _Divider(),
                              _SignOutRow(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          ZLBottomNav(
            currentIndex: 3,
            onTap: (i) => widget.onNavTap?.call(i),
          ),
        ],
      ),
    );
  }

  Widget _myCourses(EnrollmentProvider enrollment) {
    if (enrollment.isLoading && enrollment.enrollments.isEmpty) {
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

    if (enrollment.enrollments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          children: [
            Text(
              'You haven’t enrolled in any courses yet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => widget.onNavTap?.call(1),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  'Browse Courses',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
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

    final items = enrollment.enrollments.take(3).toList();
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _CourseProgress(
            enrollment: items[i],
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CourseDetailScreen(
                  courseId: items[i].course!.id,
                  initialCourse: items[i].course,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  const _StatCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.68),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseProgress extends StatelessWidget {
  final EnrollmentModel enrollment;
  final VoidCallback onTap;
  const _CourseProgress({required this.enrollment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final course = enrollment.course!;
    final style = CategoryStyle.of(course.category);
    final progress = (enrollment.progress.clamp(0, 100)) / 100.0;
    final color = enrollment.isCompleted ? const Color(0xFF059669) : style.accent;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: style.gradient,
              ),
            ),
            alignment: Alignment.center,
            child: Text(style.emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${enrollment.progress}%',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SettingsRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.ink),
            ),
            const Text('›',
                style: TextStyle(fontSize: 18, color: AppColors.faint)),
          ],
        ),
      ),
    );
  }
}

class _SignOutRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await context.read<AuthProvider>().logout();
        if (!context.mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Text(
          'Sign Out',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.red,
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
        height: 1, thickness: 1, color: Color(0xFFF5F3F0), indent: 14);
  }
}

class _AboutCard extends StatelessWidget {
  final UserModel user;
  const _AboutCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final bio = user.bio ?? '';
    final username = user.username ?? '';
    final phone = user.phone ?? '';
    final language = user.language ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bio.isNotEmpty) ...[
            Text(
              bio,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                height: 1.5,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 14),
            _Divider(),
            const SizedBox(height: 14),
          ],
          _InfoRow(
            icon: Icons.email_outlined,
            label: user.email,
            trailing: user.emailVerified ? const _VerifiedTag() : null,
          ),
          if (username.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoRow(icon: Icons.alternate_email_rounded, label: '@$username'),
          ],
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoRow(icon: Icons.phone_outlined, label: phone),
          ],
          if (language.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoRow(icon: Icons.language_rounded, label: language),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  const _InfoRow({required this.icon, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.faint),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(fontSize: 13.5, color: AppColors.muted),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _VerifiedTag extends StatelessWidget {
  const _VerifiedTag();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF059669)),
        const SizedBox(width: 3),
        Text(
          'Verified',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF059669),
          ),
        ),
      ],
    );
  }
}
