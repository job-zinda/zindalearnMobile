import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_colors.dart';

/// Full-screen player for a course's promo/preview video (the instructor
/// upload from Media & Branding, i.e. `CourseModel.previewVideo`) — not the
/// per-lesson curriculum player, which isn't built yet.
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
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
        _controller.play();
      }).catchError((_) {
        if (mounted) setState(() => _failed = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
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
                  ? Text(
                      "Couldn't load the video. Please try again.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                    )
                  : _ready
                      ? GestureDetector(
                          onTap: _togglePlay,
                          child: AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          ),
                        )
                      : const CircularProgressIndicator(color: AppColors.brand),
            ),
            if (_ready && !_controller.value.isPlaying)
              const Center(
                child: Icon(Icons.play_circle_fill_rounded,
                    size: 64, color: Colors.white70),
              ),
            Positioned(
              left: 8,
              top: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
            if (_ready)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  colors: const VideoProgressColors(
                    playedColor: AppColors.brand,
                    bufferedColor: Colors.white30,
                    backgroundColor: Colors.white12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
