import 'dart:io';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exceptions.dart';

/// Result of a video upload. Works for both Bunny.net and Cloudinary uploads.
class VideoUploadResult {
  final String url;
  final String source; // 'bunny' | 'upload' (cloudinary)
  final String? publicId; // Cloudinary public_id
  final String? bunnyVideoId; // Bunny.net video GUID
  final String? hlsUrl; // HLS manifest URL (Bunny only)
  final String? thumbnailUrl; // Auto-generated thumbnail (Bunny only)
  final String? status; // 'processing' for Bunny (transcoding in progress)
  final int duration;

  VideoUploadResult({
    required this.url,
    required this.source,
    this.publicId,
    this.bunnyVideoId,
    this.hlsUrl,
    this.thumbnailUrl,
    this.status,
    this.duration = 0,
  });

  /// Whether this video is hosted on Bunny.net Stream.
  bool get isBunny => source == 'bunny';

  /// Whether the video is still being transcoded (Bunny only).
  bool get isProcessing => status == 'processing';
}

class UploadService {
  final _client = ApiClient.instance;

  /// POST /api/upload (multipart) — uploads a local file to Cloudinary and
  /// returns its hosted URL.
  Future<String> uploadImage(
    File file, {
    String folder = 'zinda-learn/avatars',
  }) async {
    final formData = FormData.fromMap({
      'folder': folder,
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split(Platform.pathSeparator).last,
      ),
    });

    final response = await _client.post(ApiConstants.upload, data: formData);
    final json = response.data as Map<String, dynamic>;
    final url = json['url'] as String?;
    if (url == null) {
      throw ApiException(message: 'Upload succeeded but no URL was returned');
    }
    return url;
  }

  /// POST /api/videos/upload (multipart) — uploads a video to Bunny.net Stream
  /// (preferred) or Cloudinary (fallback). The backend decides which to use
  /// based on server configuration.
  ///
  /// Returns a [VideoUploadResult] with full metadata about where the video
  /// was stored and its streaming URLs.
  Future<VideoUploadResult> uploadVideo(
    File file, {
    String? courseId,
    String? title,
  }) async {
    final formData = FormData.fromMap({
      if (courseId != null && courseId.isNotEmpty) 'courseId': courseId,
      if (title != null && title.isNotEmpty) 'title': title,
      'video': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split(Platform.pathSeparator).last,
      ),
    });

    final response = await _client.post(ApiConstants.uploadVideo, data: formData);
    final json = response.data as Map<String, dynamic>;
    final url = json['url'] as String?;
    if (url == null) {
      throw ApiException(message: 'Upload succeeded but no URL was returned');
    }

    final source = (json['source'] ?? 'upload').toString();

    return VideoUploadResult(
      url: url,
      source: source,
      publicId: json['publicId']?.toString(),
      bunnyVideoId: json['bunnyVideoId']?.toString(),
      hlsUrl: json['hlsUrl']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      status: json['status']?.toString(),
      duration: (json['duration'] is num) ? (json['duration'] as num).round() : 0,
    );
  }

  /// GET /api/videos/playback/:courseId/:sectionId/:lessonId
  /// Fetches a secure, time-limited playback URL for a lesson video.
  ///
  /// For Bunny.net videos: returns a token-signed HLS URL (expires in 6 hours).
  /// For other sources: returns the direct URL.
  Future<PlaybackUrlResult> getPlaybackUrl(
    String courseId,
    String sectionId,
    String lessonId,
  ) async {
    final response = await _client.get(
      ApiConstants.videoPlaybackUrl(courseId, sectionId, lessonId),
    );
    final json = response.data as Map<String, dynamic>;

    return PlaybackUrlResult(
      playbackUrl: (json['playbackUrl'] ?? '').toString(),
      source: (json['source'] ?? 'upload').toString(),
      isHls: json['isHls'] == true,
      expiresAt: json['expiresAt']?.toString(),
    );
  }
}

/// Result of a playback URL request.
class PlaybackUrlResult {
  final String playbackUrl;
  final String source; // 'bunny' | 'upload' | 'youtube'
  final bool isHls; // true for HLS streams (Bunny)
  final String? expiresAt; // ISO timestamp when URL expires

  PlaybackUrlResult({
    required this.playbackUrl,
    required this.source,
    required this.isHls,
    this.expiresAt,
  });

  bool get isBunny => source == 'bunny';
}
