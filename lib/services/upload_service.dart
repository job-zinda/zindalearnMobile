import 'dart:io';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exceptions.dart';

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

  /// POST /api/videos/upload (multipart) — uploads a course promo video to
  /// Cloudinary. Server-side limits: 200MB, .mp4/.webm/.mov only.
  Future<({String url, String publicId})> uploadVideo(
    File file, {
    String? courseId,
  }) async {
    final formData = FormData.fromMap({
      if (courseId != null && courseId.isNotEmpty) 'courseId': courseId,
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
    return (url: url, publicId: (json['publicId'] ?? '').toString());
  }
}
