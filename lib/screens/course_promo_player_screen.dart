import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../theme/app_colors.dart';

/// Full-screen player for a course's promo/preview video (the instructor
/// upload from Media & Branding, i.e. `CourseModel.previewVideo`).
///
/// Uses media_kit for HLS adaptive streaming support when the promo video
/// is hosted on Bunny.net, and direct MP4 playback for Cloudinary URLs.
class CoursePromoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;

  const CoursePromoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  State<CoursePromoPlayerScreen> createState() =>
      _CoursePromoPlayerScreenState();
}

class _CoursePromoPlayerScreenState extends State<CoursePromoPlayerScreen> {
  late final Player _player;
  late final VideoController _videoController;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);

    _player.open(Media(widget.videoUrl)).then((_) {
      if (!mounted) return;
      _player.play();
      setState(() => _ready = true);
    }).catchError((_) {
      if (mounted) setState(() => _failed = true);
    });

    // Listen for errors
    _player.stream.error.listen((error) {
      debugPrint('Promo player error: $error');
      if (mounted && !_ready) {
        setState(() => _failed = true);
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _togglePlay() {
    _player.playOrPause();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: _failed
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Couldn't load the video. Please try again.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _failed = false;
                              _ready = false;
                            });
                            _player.open(Media(widget.videoUrl)).then((_) {
                              if (!mounted) return;
                              _player.play();
                              setState(() => _ready = true);
                            }).catchError((_) {
                              if (mounted) setState(() => _failed = true);
                            });
                          },
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
                    )
                  : _ready
                      ? GestureDetector(
                          onTap: _togglePlay,
                          child: Video(
                            controller: _videoController,
                            controls: NoVideoControls,
                          ),
                        )
                      : const CircularProgressIndicator(
                          color: AppColors.brand,
                        ),
            ),
            // Play icon overlay
            if (_ready)
              StreamBuilder<bool>(
                stream: _player.stream.playing,
                builder: (_, snap) {
                  final playing = snap.data ?? false;
                  if (playing) return const SizedBox.shrink();
                  return const Center(
                    child: Icon(
                      Icons.play_circle_fill_rounded,
                      size: 64,
                      color: Colors.white70,
                    ),
                  );
                },
              ),
            // Close button
            Positioned(
              left: 8,
              top: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
            // Progress bar
            if (_ready)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: StreamBuilder<Duration>(
                  stream: _player.stream.position,
                  builder: (_, posSnap) {
                    return StreamBuilder<Duration>(
                      stream: _player.stream.duration,
                      builder: (_, durSnap) {
                        final pos = posSnap.data ?? Duration.zero;
                        final dur = durSnap.data ?? Duration.zero;
                        if (dur == Duration.zero) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 5,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 10,
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
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
