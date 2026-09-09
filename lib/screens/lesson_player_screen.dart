import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/course_model.dart';
import '../services/upload_service.dart';
import '../theme/app_colors.dart';

/// Real per-lesson curriculum player. Uses media_kit for HLS adaptive
/// streaming (Bunny.net) and direct MP4 playback (Cloudinary/YouTube).
///
/// For Bunny.net videos: fetches a secure, time-limited HLS URL from the
/// backend before playing. The HLS stream auto-switches quality (240p-1080p)
/// based on the student's internet speed.
///
/// For legacy Cloudinary videos: plays the direct MP4 URL (backward compat).
class LessonPlayerScreen extends StatefulWidget {
  final CourseModel course;
  final bool enrolled;
  final int initialModuleIndex;
  final int initialLessonIndex;

  const LessonPlayerScreen({
    super.key,
    required this.course,
    required this.enrolled,
    this.initialModuleIndex = 0,
    this.initialLessonIndex = 0,
  });

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _FlatLesson {
  final int moduleIndex;
  final int lessonIndex;
  final Module module;
  final Lesson lesson;
  const _FlatLesson({
    required this.moduleIndex,
    required this.lessonIndex,
    required this.module,
    required this.lesson,
  });
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> {
  late final List<_FlatLesson> _flat;
  late int _current;

  // media_kit player + controller
  late final Player _player;
  late final VideoController _videoController;
  final _uploadService = UploadService();

  bool _ready = false;
  bool _failed = false;
  bool _fetchingUrl = false; // true while fetching secure playback URL

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    // Initialize media_kit player
    _player = Player();
    _videoController = VideoController(_player);

    _flat = [
      for (var m = 0; m < widget.course.modules.length; m++)
        for (var l = 0; l < widget.course.modules[m].lessons.length; l++)
          _FlatLesson(
            moduleIndex: m,
            lessonIndex: l,
            module: widget.course.modules[m],
            lesson: widget.course.modules[m].lessons[l],
          ),
    ];

    if (_flat.isNotEmpty) {
      final wanted = _flat.indexWhere(
        (f) =>
            f.moduleIndex == widget.initialModuleIndex &&
            f.lessonIndex == widget.initialLessonIndex,
      );
      var start = wanted >= 0 ? wanted : 0;
      if (_isLocked(_flat[start])) {
        final firstUnlocked = _flat.indexWhere((f) => !_isLocked(f));
        start = firstUnlocked >= 0 ? firstUnlocked : start;
      }
      _current = start;
      _loadCurrent();
    } else {
      _current = 0;
    }
  }

  bool _isLocked(_FlatLesson f) => !widget.enrolled && !f.lesson.isFree;

  /// Load the current lesson's video. For Bunny.net videos, fetches a secure
  /// playback URL first. For others, plays the URL directly.
  Future<void> _loadCurrent() async {
    setState(() {
      _ready = false;
      _failed = false;
      _fetchingUrl = false;
    });

    final lesson = _flat[_current].lesson;

    // Determine the playback URL
    String playbackUrl = '';

    if (lesson.isBunny) {
      // Fetch secure, time-limited HLS URL from backend
      setState(() => _fetchingUrl = true);
      try {
        final section = widget.course.modules[_flat[_current].moduleIndex];
        final result = await _uploadService.getPlaybackUrl(
          widget.course.id,
          section.id,
          lesson.id,
        );
        playbackUrl = result.playbackUrl;
      } catch (e) {
        debugPrint('Failed to get playback URL: $e');
        if (mounted) setState(() => _failed = true);
        return;
      } finally {
        if (mounted) setState(() => _fetchingUrl = false);
      }
    } else {
      // Direct URL (Cloudinary, YouTube, etc.)
      playbackUrl = lesson.videoUrl;
    }

    if (playbackUrl.isEmpty) {
      if (mounted) setState(() => _failed = true);
      return;
    }

    // Open the media in the player
    try {
      debugPrint('[LessonPlayer] Opening URL: $playbackUrl');
      await _player.open(Media(playbackUrl));

      // Listen for errors
      _player.stream.error.listen((error) {
        debugPrint('[LessonPlayer] Player error: $error');
      });

      // Show the video widget immediately — media_kit will buffer and
      // display the first frame as soon as it's ready. No need to wait
      // for width > 0 before showing the widget; it handles buffering
      // states internally and will show frames once decoded.
      if (mounted) {
        setState(() => _ready = true);
      }

      debugPrint('[LessonPlayer] Player opened, widget displayed');
    } catch (e) {
      debugPrint('[LessonPlayer] Failed to open media: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _player.dispose();
    super.dispose();
  }

  void _togglePlay() {
    _player.playOrPause();
  }

  void _seek(Duration delta) async {
    final pos = await _player.stream.position.first;
    final dur = await _player.stream.duration.first;
    final target = pos + delta;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > dur ? dur : target);
    _player.seek(clamped);
  }

  bool get _hasPrev => _current > 0;
  bool get _hasNext =>
      _current < _flat.length - 1 && !_isLocked(_flat[_current + 1]);

  void _goTo(int index) {
    if (index < 0 || index >= _flat.length) return;
    if (_isLocked(_flat[index])) {
      _showLockedSnack();
      return;
    }
    setState(() => _current = index);
    _loadCurrent();
  }

  void _showLockedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Enroll in this course to unlock this lesson.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _fmt(Duration d) {
    if (d.isNegative || d == Duration.zero) return '0:00';
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_flat.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.ink,
        body: SafeArea(
          child: Column(
            children: [
              _appBar(),
              const Expanded(
                child: Center(
                  child: Text(
                    'No lessons available yet.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final current = _flat[_current];

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _appBar(),
            _videoArea(current),
            _controls(),
            Expanded(child: _panel(current)),
          ],
        ),
      ),
    );
  }

  Widget _appBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.course.title,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          // HLS quality indicator badge
          if (_ready && _flat[_current].lesson.isBunny)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.hd_rounded, size: 14, color: AppColors.brand),
                  const SizedBox(width: 3),
                  Text(
                    'HLS',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
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

  Widget _videoArea(_FlatLesson current) {
    return GestureDetector(
      onDoubleTapDown: (details) {
        final half = MediaQuery.of(context).size.width / 2;
        _seek(Duration(seconds: details.localPosition.dx < half ? -10 : 10));
      },
      onTap: _ready ? _togglePlay : null,
      child: Container(
        width: double.infinity,
        height: 220,
        color: Colors.black,
        child: _failed
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        current.lesson.videoUrl.isEmpty &&
                                !current.lesson.isBunny
                            ? 'No video for this lesson yet.'
                            : "Couldn't load the video.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _loadCurrent,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brand.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Retry',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brand,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : (_ready)
                ? Video(
                    controller: _videoController,
                    controls: NoVideoControls,
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppColors.brand),
                        if (_fetchingUrl) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Preparing secure stream...',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      child: StreamBuilder<Duration>(
        stream: _player.stream.position,
        builder: (_, posSnap) {
          return StreamBuilder<Duration>(
            stream: _player.stream.duration,
            builder: (_, durSnap) {
              final pos = posSnap.data ?? Duration.zero;
              final dur = durSnap.data ?? Duration.zero;
              return StreamBuilder<bool>(
                stream: _player.stream.playing,
                builder: (_, playSnap) {
                  final playing = playSnap.data ?? false;
                  return Column(
                    children: [
                      // Progress bar
                      if (_ready && dur > Duration.zero)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Text(
                                _fmt(pos),
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 6,
                                    ),
                                    overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 12,
                                    ),
                                    activeTrackColor: AppColors.brand,
                                    inactiveTrackColor: Colors.white24,
                                    thumbColor: AppColors.brand,
                                  ),
                                  child: Slider(
                                    value: pos.inMilliseconds
                                        .toDouble()
                                        .clamp(0, dur.inMilliseconds.toDouble()),
                                    max: dur.inMilliseconds.toDouble(),
                                    onChanged: (v) {
                                      _player.seek(
                                        Duration(milliseconds: v.round()),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _fmt(dur),
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      _controlsRow(playing),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _controlsRow(bool playing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CtrlBtn(
          icon: Icons.skip_previous_rounded,
          onTap: _hasPrev ? () => _goTo(_current - 1) : null,
        ),
        const SizedBox(width: 18),
        _CtrlBtn(
          label: '-10s',
          onTap: _ready ? () => _seek(const Duration(seconds: -10)) : null,
        ),
        const SizedBox(width: 18),
        GestureDetector(
          onTap: _ready ? _togglePlay : null,
          child: Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brand,
            ),
            child: Icon(
              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 18),
        _CtrlBtn(
          label: '+10s',
          onTap: _ready ? () => _seek(const Duration(seconds: 10)) : null,
        ),
        const SizedBox(width: 18),
        _CtrlBtn(
          icon: Icons.skip_next_rounded,
          onTap: _hasNext ? () => _goTo(_current + 1) : null,
        ),
      ],
    );
  }

  Widget _panel(_FlatLesson current) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  current.lesson.title,
                  style: GoogleFonts.dmSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Section ${current.moduleIndex + 1} · Lesson ${current.lessonIndex + 1} of ${current.module.lessons.length}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              children: [
                for (var m = 0; m < widget.course.modules.length; m++)
                  _panelSection(m),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
              child: GestureDetector(
                onTap: _hasNext ? () => _goTo(_current + 1) : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _hasNext ? AppColors.brand : AppColors.border,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _current == _flat.length - 1
                        ? 'Last lesson'
                        : 'Next Lesson →',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panelSection(int moduleIndex) {
    final module = widget.course.modules[moduleIndex];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'SECTION ${moduleIndex + 1} — ${module.title.toUpperCase()}',
              style: GoogleFonts.dmSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.faint,
                letterSpacing: 0.4,
              ),
            ),
          ),
          for (var l = 0; l < module.lessons.length; l++)
            _lessonTile(moduleIndex, l),
        ],
      ),
    );
  }

  Widget _lessonTile(int moduleIndex, int lessonIndex) {
    final flatIndex = _flat.indexWhere(
      (f) => f.moduleIndex == moduleIndex && f.lessonIndex == lessonIndex,
    );
    final f = _flat[flatIndex];
    final isCurrent = flatIndex == _current;
    final locked = _isLocked(f);

    return GestureDetector(
      onTap: () => locked ? _showLockedSnack() : _goTo(flatIndex),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isCurrent ? AppColors.brandFaint : Colors.transparent,
          border: isCurrent
              ? Border.all(color: AppColors.brand, width: 1.5)
              : null,
        ),
        child: Opacity(
          opacity: locked ? 0.45 : 1.0,
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent ? AppColors.brand : const Color(0xFFD6D3CD),
                ),
                child: Icon(
                  locked
                      ? Icons.lock_outline_rounded
                      : Icons.play_arrow_rounded,
                  size: 14,
                  color: isCurrent ? Colors.white : AppColors.muted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.lesson.title,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: isCurrent
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isCurrent ? AppColors.brand : AppColors.ink,
                      ),
                    ),
                    Text(
                      isCurrent
                          ? '${f.lesson.duration > 0 ? '${f.lesson.duration} min · ' : ''}Playing now'
                          : (f.lesson.duration > 0
                                ? '${f.lesson.duration} min'
                                : ''),
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: isCurrent
                            ? AppColors.brand.withValues(alpha: 0.7)
                            : AppColors.faint,
                      ),
                    ),
                  ],
                ),
              ),
              // Small HLS badge for Bunny lessons
              if (f.lesson.isBunny)
                Icon(
                  Icons.stream_rounded,
                  size: 14,
                  color: isCurrent
                      ? AppColors.brand.withValues(alpha: 0.6)
                      : AppColors.faint.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final VoidCallback? onTap;
  const _CtrlBtn({this.icon, this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.35 : 1,
        child: icon != null
            ? Icon(icon, size: 22, color: Colors.white.withValues(alpha: 0.75))
            : Text(
                label!,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }
}
