import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/network/api_exceptions.dart';
import '../core/utils/formatters.dart';
import '../models/live_class_model.dart';
import '../services/live_class_service.dart';
import '../theme/app_colors.dart';

/// Live Classes, mirroring the web app's schedule page. Backed by
/// GET /api/live-classes/student (see zinda-learn-backend/server/modules/
/// liveClasses).
class LiveClassesScreen extends StatefulWidget {
  const LiveClassesScreen({super.key});

  @override
  State<LiveClassesScreen> createState() => _LiveClassesScreenState();
}

class _LiveClassesScreenState extends State<LiveClassesScreen> {
  final _service = LiveClassService();
  List<LiveClassModel> _classes = [];
  bool _loading = true;
  String? _error;
  String? _joiningId;
  int _tab = 0;
  static const _tabs = ['All', 'Upcoming', 'Completed'];

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
      final classes = await _service.getMyLiveClasses();
      classes.sort((a, b) => a.startTime.compareTo(b.startTime));
      if (!mounted) return;
      setState(() {
        _classes = classes;
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
        _error = 'Unable to load live classes. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _join(LiveClassModel liveClass) async {
    setState(() => _joiningId = liveClass.id);
    try {
      final link = await _service.join(liveClass.id);
      final url = link.isNotEmpty ? link : liveClass.meetingLink;
      final uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Couldn’t open the meeting link.')));
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Failed to join. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _joiningId = null);
    }
  }

  List<LiveClassModel> get _filtered {
    switch (_tab) {
      case 1:
        return _classes.where((c) => c.isUpcoming || c.isLive).toList();
      case 2:
        return _classes.where((c) => c.isEnded).toList();
      default:
        return _classes;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _classes.where((c) => c.isLive).length;
    final upcomingCount = _classes.where((c) => c.isUpcoming).length;
    final filtered = _filtered;

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
              _header(),
              const SizedBox(height: 16),
              _banner(activeCount, upcomingCount),
              const SizedBox(height: 22),
              _tabBar(),
              const SizedBox(height: 18),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator(color: AppColors.brand)),
                )
              else if (_error != null)
                _errorState()
              else if (filtered.isEmpty)
                _emptyState()
              else
                ...filtered.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _LiveClassCard(
                        liveClass: c,
                        joining: _joiningId == c.id,
                        onJoin: () => _join(c),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
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
        Text(
          'Live Classes',
          style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
      ],
    );
  }

  Widget _banner(int active, int upcoming) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6D28D9), Color(0xFF4C1D95)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Join your instructor in real time — ask questions, get\nfeedback, and learn faster.',
            style: GoogleFonts.dmSans(fontSize: 13.5, height: 1.5, color: Colors.white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _BannerStat(value: '$active', label: 'ACTIVE'),
              const SizedBox(width: 20),
              Container(width: 1, height: 34, color: Colors.white.withValues(alpha: 0.25)),
              const SizedBox(width: 20),
              _BannerStat(value: '$upcoming', label: 'UPCOMING'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final active = _tab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? AppColors.brand : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  _tabs[i],
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : AppColors.muted,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.brandFaint),
            child: const Icon(Icons.calendar_month_rounded, size: 32, color: AppColors.brand),
          ),
          const SizedBox(height: 18),
          Text(
            'No sessions found',
            style: GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          Text(
            'There aren’t any live classes scheduled right now.\nCheck back soon.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 13.5, height: 1.5, color: AppColors.muted),
          ),
        ],
      ),
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
}

class _BannerStat extends StatelessWidget {
  final String value;
  final String label;
  const _BannerStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _LiveClassCard extends StatelessWidget {
  final LiveClassModel liveClass;
  final bool joining;
  final VoidCallback onJoin;

  const _LiveClassCard({required this.liveClass, required this.joining, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final (badgeColor, badgeBg, badgeLabel) = switch (liveClass.status) {
      'live' => (const Color(0xFFDC2626), const Color(0xFFFEE2E2), 'LIVE NOW'),
      'upcoming' => (AppColors.brand, AppColors.brandFaint, 'UPCOMING'),
      'cancelled' => (AppColors.faint, const Color(0xFFF0EFEA), 'CANCELLED'),
      _ => (const Color(0xFF059669), const Color(0xFFD1FAE5), 'COMPLETED'),
    };

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  badgeLabel,
                  style: GoogleFonts.dmSans(
                      fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.4, color: badgeColor),
                ),
              ),
              const Spacer(),
              Text(
                Formatters.chatTimestamp(liveClass.startTime),
                style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            liveClass.title,
            style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 3),
          Text(
            liveClass.courseTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(fontSize: 12.5, color: AppColors.brand),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 15, color: AppColors.faint),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        liveClass.instructorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(fontSize: 12.5, color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
              ),
              if (liveClass.isLive || liveClass.isUpcoming)
                GestureDetector(
                  onTap: joining ? null : onJoin,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: liveClass.isLive ? AppColors.brand : Colors.white,
                      border: liveClass.isLive ? null : Border.all(color: AppColors.border, width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: joining
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand),
                          )
                        : Text(
                            liveClass.isLive ? 'Join Now' : 'Details',
                            style: GoogleFonts.dmSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: liveClass.isLive ? Colors.white : AppColors.ink,
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
