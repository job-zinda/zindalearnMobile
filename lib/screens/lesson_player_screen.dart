import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../models/course_model.dart';
import '../theme/app_colors.dart';

/// Real per-lesson curriculum player. Streams `Lesson.videoUrl` with
/// `video_player` (same package as [CoursePromoPlayerScreen]) and lets the
/// learner move between lessons via the bottom panel or prev/next controls,
/// respecting per-lesson free-preview / enrollment locks.
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
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

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

  void _loadCurrent() {
    _controller?.dispose();
    _controller = null;
    _ready = false;
    _failed = false;

    final url = _flat[_current].lesson.videoUrl;
    if (url.isEmpty) {
      setState(() => _failed = true);
      return;
    }

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _controller = controller;
    controller
        .initialize()
        .then((_) {
          if (!mounted || _controller != controller) return;
          setState(() => _ready = true);
          controller.play();
        })
        .catchError((_) {
          if (mounted && _controller == controller) {
            setState(() => _failed = true);
          }
        });
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null || !_ready) return;
    c.value.isPlaying ? c.pause() : c.play();
  }

  void _seek(Duration delta) {
    final c = _controller;
    if (c == null || !_ready) return;
    final target = c.value.position + delta;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > c.value.duration ? c.value.duration : target);
    c.seekTo(clamped);
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
        ],
      ),
    );
  }

  Widget _videoArea(_FlatLesson current) {
    final c = _controller;
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
                  child: Text(
                    current.lesson.videoUrl.isEmpty
                        ? 'No video for this lesson yet.'
                        : "Couldn't load the video.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              )
            : (_ready && c != null)
            ? ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: c,
                builder: (_, value, _) => Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: AspectRatio(
                        aspectRatio: value.aspectRatio,
                        child: VideoPlayer(c),
                      ),
                    ),
                    if (!value.isPlaying)
                      const Icon(
                        Icons.play_circle_fill_rounded,
                        size: 52,
                        color: Colors.white70,
                      ),
                    Positioned(
                      bottom: 8,
                      right: 10,
                      child: Text(
                        '${_fmt(value.position)} / ${_fmt(value.duration)}',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: VideoProgressIndicator(
                        c,
                        allowScrubbing: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        colors: const VideoProgressColors(
                          playedColor: AppColors.brand,
                          bufferedColor: Colors.white30,
                          backgroundColor: Colors.white12,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const Center(
                child: CircularProgressIndicator(color: AppColors.brand),
              ),
      ),
    );
  }

  Widget _controls() {
    final c = _controller;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      child: (_ready && c != null)
          ? ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: c,
              builder: (_, value, _) => _controlsRow(value.isPlaying),
            )
          : _controlsRow(false),
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
