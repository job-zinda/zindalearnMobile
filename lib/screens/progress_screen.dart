import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/network/api_exceptions.dart';
import '../models/progress_model.dart';
import '../services/progress_service.dart';
import '../theme/app_colors.dart';

/// Progress overview, backed by GET /api/student/progress/overview and
/// /analytics (see zinda-learn-backend/server/controllers/
/// studentProgress.controller.js).
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _service = ProgressService();
  ProgressOverview? _overview;
  List<DailyActivity> _activity = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.getOverview(),
        _service.getWeeklyActivity(),
      ]);
      if (!mounted) return;
      setState(() {
        _overview = results[0] as ProgressOverview;
        _activity = results[1] as List<DailyActivity>;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load your progress. Please try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.brand,
          onRefresh: _fetch,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            children: [
              _header(context),
              const SizedBox(height: 18),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator(color: AppColors.brand)),
                )
              else if (_error != null)
                _errorState()
              else ...[
                _statsGrid(_overview ?? ProgressOverview()),
                const SizedBox(height: 18),
                _activityCard(_activity),
                const SizedBox(height: 16),
                _pointsCard(_overview ?? ProgressOverview()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
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
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.ink),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Learning Progress',
                style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
              Text(
                'Track your growth across all courses.',
                style: GoogleFonts.dmSans(fontSize: 12.5, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _errorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 13.5, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _fetch,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(12)),
              child: Text('Retry',
                  style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsGrid(ProgressOverview overview) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          icon: Icons.check_circle_rounded,
          iconColor: const Color(0xFF059669),
          iconBg: const Color(0xFFD1FAE5),
          value: '${overview.completedCourses}',
          label: 'Completed',
        ),
        _StatCard(
          icon: Icons.play_circle_fill_rounded,
          iconColor: const Color(0xFF2563EB),
          iconBg: const Color(0xFFDBEAFE),
          value: '${overview.inProgressCourses}',
          label: 'In Progress',
        ),
        _StatCard(
          icon: Icons.access_time_filled_rounded,
          iconColor: AppColors.brand,
          iconBg: AppColors.brandFaint,
          value: overview.watchTimeLabel,
          label: 'Learning Time',
        ),
        _StatCard(
          icon: Icons.bolt_rounded,
          iconColor: const Color(0xFFD97706),
          iconBg: const Color(0xFFFEF3C7),
          value: '${overview.points}',
          label: 'Skill Points',
        ),
      ],
    );
  }

  Widget _activityCard(List<DailyActivity> activity) {
    final maxMinutes = activity.fold<int>(0, (a, d) => d.minutes > a ? d.minutes : a);
    final hasActivity = maxMinutes > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart_rounded, size: 18, color: AppColors.muted),
              const SizedBox(width: 8),
              Text(
                'Learning Activity',
                style: GoogleFonts.dmSans(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Minutes spent learning per day',
            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          if (!hasActivity)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No learning activity in the last 7 days yet.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.faint),
                ),
              ),
            )
          else
            SizedBox(
              height: 110,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: activity.map((d) {
                  final ratio = maxMinutes > 0 ? d.minutes / maxMinutes : 0.0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            d.minutes > 0 ? '${d.minutes}' : '',
                            style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.muted),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: (ratio * 70).clamp(3, 70).toDouble(),
                            decoration: BoxDecoration(
                              color: d.minutes > 0 ? AppColors.brand : const Color(0xFFF0EFEA),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            d.day,
                            style: GoogleFonts.dmSans(fontSize: 10.5, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pointsCard(ProgressOverview overview) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2A2A2A)),
            child: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF59E0B)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${overview.liveAttendanceCount} live classes attended',
                  style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  '${overview.certificates} certificates earned so far',
                  style: GoogleFonts.dmSans(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
        ],
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(shape: BoxShape.circle, color: iconBg),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          Text(
            label,
            style: GoogleFonts.dmSans(fontSize: 11.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
