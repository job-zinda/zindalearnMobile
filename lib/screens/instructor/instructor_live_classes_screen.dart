import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/network/api_exceptions.dart';
import '../../models/live_class_model.dart';
import '../../services/live_class_service.dart';
import '../../theme/app_colors.dart';
import 'schedule_live_class_screen.dart';

/// Instructor-side Live Classes management — mirrors the web app's
/// /instructor/live-classes page: schedule sessions, start/end them, edit
/// upcoming ones, and delete. Backed by GET /api/live-classes/instructor/all
/// (see zinda-learn-backend/server/modules/liveClasses).
class InstructorLiveClassesScreen extends StatefulWidget {
  const InstructorLiveClassesScreen({super.key});

  @override
  State<InstructorLiveClassesScreen> createState() =>
      _InstructorLiveClassesScreenState();
}

class _InstructorLiveClassesScreenState
    extends State<InstructorLiveClassesScreen> {
  final _service = LiveClassService();
  List<LiveClassModel> _classes = [];
  bool _loading = true;
  String? _error;
  String? _busyId;
  int _tab = 0;
  static const _tabs = ['All', 'Upcoming', 'Live', 'Completed'];

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
      final classes = await _service.getInstructorLiveClasses();
      classes.sort((a, b) => b.startTime.compareTo(a.startTime));
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

  Future<void> _schedule() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ScheduleLiveClassScreen()),
    );
    if (created == true) {
      _showSnack('Session scheduled');
      _fetch();
    }
  }

  Future<void> _edit(LiveClassModel liveClass) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ScheduleLiveClassScreen(liveClass: liveClass),
      ),
    );
    if (updated == true) {
      _showSnack('Session updated');
      _fetch();
    }
  }

  Future<void> _start(LiveClassModel liveClass) async {
    setState(() => _busyId = liveClass.id);
    try {
      await _service.startLiveClass(liveClass.id);
      _showSnack('Class started');
      await _fetch();
    } on ApiException catch (e) {
      _showSnack(e.message, error: true);
    } catch (_) {
      _showSnack('Failed to start class.', error: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _end(LiveClassModel liveClass) async {
    setState(() => _busyId = liveClass.id);
    try {
      await _service.endLiveClass(liveClass.id);
      _showSnack('Class ended');
      await _fetch();
    } on ApiException catch (e) {
      _showSnack(e.message, error: true);
    } catch (_) {
      _showSnack('Failed to end class.', error: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _openMeeting(LiveClassModel liveClass) async {
    final uri = Uri.tryParse(liveClass.meetingLink);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      _showSnack('Couldn’t open the meeting link.', error: true);
    }
  }

  Future<void> _delete(LiveClassModel liveClass) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this class?'),
        content: Text('Delete "${liveClass.title}"? This cannot be undone.'),
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
    if (confirmed != true) return;

    setState(() => _busyId = liveClass.id);
    try {
      await _service.deleteLiveClass(liveClass.id);
      if (!mounted) return;
      setState(() => _classes.removeWhere((c) => c.id == liveClass.id));
      _showSnack('Deleted');
    } on ApiException catch (e) {
      _showSnack(e.message, error: true);
    } catch (_) {
      _showSnack('Failed to delete.', error: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  List<LiveClassModel> get _filtered {
    switch (_tab) {
      case 1:
        return _classes.where((c) => c.isUpcoming).toList();
      case 2:
        return _classes.where((c) => c.isLive).toList();
      case 3:
        return _classes.where((c) => c.status == 'ended').toList();
      default:
        return _classes;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final stats = (
      upcoming: _classes.where((c) => c.isUpcoming).length,
      live: _classes.where((c) => c.isLive).length,
      completed: _classes.where((c) => c.status == 'ended').length,
      total: _classes.length,
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.brand,
          onRefresh: _fetch,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            children: [
              _header(),
              const SizedBox(height: 16),
              _scheduleButton(),
              const SizedBox(height: 16),
              if (!_loading && _error == null) ...[
                _statsBar(stats),
                const SizedBox(height: 16),
                _tabBar(),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${filtered.length} session${filtered.length == 1 ? '' : 's'}',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.faint,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.brand),
                  ),
                )
              else if (_error != null)
                _errorState()
              else if (filtered.isEmpty)
                _emptyState()
              else
                ...filtered.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _LiveClassManageCard(
                      liveClass: c,
                      busy: _busyId == c.id,
                      onStart: () => _start(c),
                      onEnd: () => _end(c),
                      onOpenMeeting: () => _openMeeting(c),
                      onEdit: () => _edit(c),
                      onDelete: () => _delete(c),
                    ),
                  ),
                ),
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
                'Live Classes',
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              Text(
                'Manage and schedule sessions with your students.',
                style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _scheduleButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _schedule,
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
              'Schedule Session',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsBar(({int upcoming, int live, int completed, int total}) stats) {
    final items = [
      ('Upcoming', stats.upcoming, AppColors.amber),
      ('Live now', stats.live, const Color(0xFFDC2626)),
      ('Completed', stats.completed, const Color(0xFF059669)),
      ('Total', stats.total, AppColors.ink),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                decoration: i == 0
                    ? null
                    : const BoxDecoration(
                        border: Border(
                          left: BorderSide(color: AppColors.border, width: 1.5),
                        ),
                      ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${items[i].$2}',
                      style: GoogleFonts.dmSans(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: items[i].$3,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      items[i].$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.faint,
                      ),
                    ),
                  ],
                ),
              ),
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
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: active ? AppColors.brand : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  _tabs[i],
                  style: GoogleFonts.dmSans(
                    fontSize: 12.5,
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
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bg,
            ),
            child: const Icon(
              Icons.videocam_outlined,
              size: 28,
              color: AppColors.faint,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No sessions yet',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Schedule your first live class and start teaching interactively.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              height: 1.5,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _schedule,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, size: 16, color: AppColors.brand),
                const SizedBox(width: 4),
                Text(
                  'Schedule a session',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brand,
                  ),
                ),
              ],
            ),
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

class _LiveClassManageCard extends StatelessWidget {
  final LiveClassModel liveClass;
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onEnd;
  final VoidCallback onOpenMeeting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LiveClassManageCard({
    required this.liveClass,
    required this.busy,
    required this.onStart,
    required this.onEnd,
    required this.onOpenMeeting,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final (badgeColor, badgeBg, badgeLabel) = switch (liveClass.status) {
      'live' => (const Color(0xFFDC2626), const Color(0xFFFEE2E2), 'LIVE'),
      'upcoming' => (AppColors.amber, AppColors.amberFaint, 'UPCOMING'),
      'cancelled' => (AppColors.faint, const Color(0xFFF0EFEA), 'CANCELLED'),
      _ => (const Color(0xFF059669), const Color(0xFFD1FAE5), 'COMPLETED'),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: liveClass.isLive ? const Color(0xFFFECACA) : AppColors.border,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeLabel,
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: badgeColor,
                            ),
                          ),
                        ),
                        Text(
                          liveClass.courseTitle,
                          style: GoogleFonts.dmSans(
                            fontSize: 11.5,
                            color: AppColors.faint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      liveClass.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              if (liveClass.isUpcoming)
                _iconBtn(Icons.edit_outlined, onEdit, AppColors.muted),
              _iconBtn(Icons.delete_outline_rounded, onDelete, AppColors.red),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 12,
                color: AppColors.faint,
              ),
              const SizedBox(width: 5),
              Text(
                liveClass.scheduledDateStr.isNotEmpty
                    ? liveClass.scheduledDateStr
                    : '${liveClass.startTime.year}-${liveClass.startTime.month.toString().padLeft(2, '0')}-${liveClass.startTime.day.toString().padLeft(2, '0')}',
                style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.access_time_rounded,
                size: 12,
                color: AppColors.faint,
              ),
              const SizedBox(width: 5),
              Text(
                liveClass.startTimeStr.isNotEmpty
                    ? '${liveClass.startTimeStr} · ${liveClass.duration} min'
                    : '${liveClass.duration} min',
                style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (busy)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.brand,
                ),
              ),
            )
          else
            Row(
              children: [
                if (liveClass.isUpcoming)
                  _actionBtn(
                    'Start class',
                    Icons.play_arrow_rounded,
                    onStart,
                    filled: true,
                  ),
                if (liveClass.isLive) ...[
                  _actionBtn(
                    'Open meeting',
                    Icons.open_in_new_rounded,
                    onOpenMeeting,
                    filled: true,
                  ),
                  const SizedBox(width: 8),
                  _actionBtn(
                    'End session',
                    Icons.stop_circle_outlined,
                    onEnd,
                    filled: false,
                  ),
                ],
                if (liveClass.status == 'ended')
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 15,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Session completed',
                        style: GoogleFonts.dmSans(
                          fontSize: 12.5,
                          color: AppColors.faint,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _actionBtn(
    String label,
    IconData icon,
    VoidCallback onTap, {
    required bool filled,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: filled ? AppColors.brand : AppColors.bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: filled ? Colors.white : AppColors.placeholder,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: filled ? Colors.white : AppColors.placeholder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
