import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class LessonPlayerScreen extends StatefulWidget {
  const LessonPlayerScreen({super.key});

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen>
    with TickerProviderStateMixin {
  bool _isPlaying = false;
  double _progress = 0.57;

  late AnimationController _panelCtrl;
  late Animation<Offset> _panelSlide;
  late AnimationController _controlsCtrl;
  late Animation<double> _controlsFade;

  final List<_Lesson> _lessons = [
    _Lesson(title: 'Intro Video', duration: '5:00', done: true, locked: false),
    _Lesson(
        title: 'Setting Up React',
        duration: '8:30',
        done: false,
        locked: false),
    _Lesson(
        title: 'Components Deep Dive',
        duration: '12:00',
        done: false,
        locked: true),
  ];
  int _currentLesson = 1;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _panelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _panelSlide =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _panelCtrl, curve: Curves.easeOutCubic),
    );

    _controlsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _controlsFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controlsCtrl, curve: Curves.easeOut),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _panelCtrl.forward();
        _controlsCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _panelCtrl.dispose();
    _controlsCtrl.dispose();
    super.dispose();
  }

  void _seek(double delta) {
    setState(() {
      _progress = (_progress + delta).clamp(0.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // App bar (dark)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Text('‹',
                        style:
                            TextStyle(fontSize: 24, color: Colors.white)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ReactJS',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    '⋮',
                    style: TextStyle(
                        fontSize: 20,
                        color: Colors.white.withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ),

            // Video player area
            GestureDetector(
              onDoubleTapDown: (details) {
                final half = MediaQuery.of(context).size.width / 2;
                _seek(details.localPosition.dx < half ? -0.05 : 0.05);
              },
              child: Container(
                width: double.infinity,
                height: 190,
                color: const Color(0xFF0D091E),
                child: Stack(
                  children: [
                    // Background texture
                    Positioned.fill(
                      child: CustomPaint(painter: _StripePainter()),
                    ),

                    // Play/Pause button
                    Center(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _isPlaying = !_isPlaying),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.brand.withValues(alpha: 0.92),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.brand.withValues(alpha: 0.5),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _isPlaying ? '⏸' : '▶',
                              style: const TextStyle(
                                  fontSize: 22, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Timecode
                    Positioned(
                      bottom: 14,
                      right: 14,
                      child: Text(
                        '8:30 / 15:00',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                    ),

                    // Seek bar
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: GestureDetector(
                        onHorizontalDragUpdate: (d) {
                          final w = context.size?.width ?? 375;
                          setState(() {
                            _progress =
                                (_progress + d.delta.dx / w).clamp(0.0, 1.0);
                          });
                        },
                        child: Container(
                          height: 3,
                          color: Colors.white.withValues(alpha: 0.18),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: AnimatedFractionallySizedBox(
                              duration: const Duration(milliseconds: 100),
                              widthFactor: _progress,
                              child: Container(color: AppColors.brand),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Playback controls
            FadeTransition(
              opacity: _controlsFade,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CtrlBtn(
                      icon: '⏮',
                      size: 20,
                      onTap: () {
                        if (_currentLesson > 0) {
                          setState(() => _currentLesson--);
                        }
                      },
                    ),
                    const SizedBox(width: 18),
                    _CtrlBtn(
                      icon: '−10s',
                      size: 13,
                      onTap: () => _seek(-0.1),
                      isText: true,
                    ),
                    const SizedBox(width: 18),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _isPlaying = !_isPlaying),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.brand,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brand.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _isPlaying ? '⏸' : '▶',
                            style: const TextStyle(
                                fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    _CtrlBtn(
                      icon: '+10s',
                      size: 13,
                      onTap: () => _seek(0.1),
                      isText: true,
                    ),
                    const SizedBox(width: 18),
                    _CtrlBtn(
                      icon: '⏭',
                      size: 20,
                      onTap: () {
                        if (_currentLesson < _lessons.length - 1) {
                          setState(() => _currentLesson++);
                        }
                      },
                    ),
                    const SizedBox(width: 18),
                    _CtrlBtn(icon: '⤢', size: 18, onTap: () {}),
                  ],
                ),
              ),
            ),

            // White lesson panel
            Expanded(
              child: SlideTransition(
                position: _panelSlide,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(26)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current lesson header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _lessons[_currentLesson].title,
                              style: GoogleFonts.dmSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Section 1 · Lesson ${_currentLesson + 1} of ${_lessons.length}',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Section label
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                        child: Text(
                          'SECTION 1 — BASICS',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.faint,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      // Lesson list
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18),
                          itemCount: _lessons.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 6),
                          itemBuilder: (_, i) {
                            final lesson = _lessons[i];
                            final isCurrent = i == _currentLesson;
                            final isDone = lesson.done;
                            final isLocked = lesson.locked;

                            return GestureDetector(
                              onTap: isLocked
                                  ? null
                                  : () => setState(
                                      () => _currentLesson = i),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  color: isCurrent
                                      ? AppColors.brandFaint
                                      : isDone
                                          ? AppColors.brandFainter
                                          : Colors.transparent,
                                  border: isCurrent
                                      ? Border.all(
                                          color: AppColors.brand,
                                          width: 1.5)
                                      : null,
                                ),
                                child: Opacity(
                                  opacity: isLocked ? 0.45 : 1.0,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isDone || isCurrent
                                              ? AppColors.brand
                                              : const Color(0xFFD6D3CD),
                                        ),
                                        child: Center(
                                          child: Text(
                                            isDone
                                                ? '✓'
                                                : isLocked
                                                    ? '🔒'
                                                    : '▶',
                                            style: TextStyle(
                                              fontSize:
                                                  isLocked ? 11 : 13,
                                              color: isDone || isCurrent
                                                  ? Colors.white
                                                  : AppColors.muted,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              lesson.title,
                                              style: GoogleFonts.dmSans(
                                                fontSize: 13,
                                                fontWeight: isCurrent
                                                    ? FontWeight.w700
                                                    : FontWeight.w400,
                                                color: isCurrent
                                                    ? AppColors.brand
                                                    : isDone
                                                        ? AppColors.muted
                                                        : AppColors.ink,
                                                decoration: isDone
                                                    ? TextDecoration
                                                        .lineThrough
                                                    : null,
                                              ),
                                            ),
                                            Text(
                                              isCurrent
                                                  ? '${lesson.duration} · Playing now'
                                                  : lesson.duration,
                                              style: GoogleFonts.dmSans(
                                                fontSize: 11,
                                                color: isCurrent
                                                    ? AppColors.brand
                                                        .withValues(
                                                            alpha: 0.7)
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
                          },
                        ),
                      ),

                      // Next lesson button
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(18, 10, 18, 16),
                          child: GestureDetector(
                            onTap: () {
                              if (_currentLesson < _lessons.length - 1 &&
                                  !_lessons[_currentLesson + 1].locked) {
                                setState(() => _currentLesson++);
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.brand,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                'Next Lesson →',
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Lesson {
  final String title;
  final String duration;
  final bool done;
  final bool locked;
  const _Lesson(
      {required this.title,
      required this.duration,
      required this.done,
      required this.locked});
}

class _CtrlBtn extends StatelessWidget {
  final String icon;
  final double size;
  final VoidCallback onTap;
  final bool isText;
  const _CtrlBtn(
      {required this.icon,
      required this.size,
      required this.onTap,
      this.isText = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        icon,
        style: isText
            ? GoogleFonts.dmSans(
                fontSize: size,
                color: Colors.white.withValues(alpha: 0.55),
                fontWeight: FontWeight.w500,
              )
            : TextStyle(
                fontSize: size,
                color: Colors.white.withValues(alpha: 0.65),
              ),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF14102E)
      ..strokeWidth = 1;
    for (double i = -size.height; i < size.width + size.height; i += 16) {
      canvas.drawLine(
          Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_StripePainter old) => false;
}
