import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/live_class_model.dart';

class LiveClassService {
  final _client = ApiClient.instance;

  /// GET /api/live-classes/student — live classes for the current
  /// student's enrolled courses.
  Future<List<LiveClassModel>> getMyLiveClasses() async {
    final response = await _client.get(ApiConstants.studentLiveClasses);
    final data = response.data as Map<String, dynamic>;
    final raw = (data['data'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((c) => LiveClassModel.fromJson(Map<String, dynamic>.from(c)))
        .toList();
  }

  /// POST /api/live-classes/:id/join — returns the meeting link and marks
  /// attendance.
  Future<String> join(String liveClassId) async {
    final response = await _client.post(
      ApiConstants.joinLiveClass(liveClassId),
    );
    final data = response.data as Map<String, dynamic>;
    final result = data['data'] as Map<String, dynamic>?;
    return (result?['meetingLink'] ?? '').toString();
  }

  /// GET /api/live-classes/instructor/all — the instructor's own scheduled
  /// sessions across all their courses.
  Future<List<LiveClassModel>> getInstructorLiveClasses() async {
    final response = await _client.get(ApiConstants.instructorLiveClasses);
    final data = response.data as Map<String, dynamic>;
    final raw = (data['data'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((c) => LiveClassModel.fromJson(Map<String, dynamic>.from(c)))
        .toList();
  }

  /// POST /api/live-classes — `scheduledDate` is 'YYYY-MM-DD' and
  /// `startTime` is 'HH:mm'; the backend combines them with `duration` into
  /// the actual start/end timestamps.
  Future<LiveClassModel> createLiveClass({
    required String title,
    required String description,
    required String courseId,
    required String meetingLink,
    required String scheduledDate,
    required String startTime,
    required int duration,
    String thumbnail = '',
  }) async {
    final response = await _client.post(
      ApiConstants.liveClasses,
      data: {
        'title': title,
        'description': description,
        'courseId': courseId,
        'meetingLink': meetingLink,
        'scheduledDate': scheduledDate,
        'startTime': startTime,
        'duration': duration,
        'thumbnail': thumbnail,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return LiveClassModel.fromJson(
      Map<String, dynamic>.from(data['data'] as Map),
    );
  }

  /// PUT /api/live-classes/:id
  Future<LiveClassModel> updateLiveClass(
    String id, {
    required String title,
    required String description,
    required String courseId,
    required String meetingLink,
    required String scheduledDate,
    required String startTime,
    required int duration,
    String thumbnail = '',
  }) async {
    final response = await _client.put(
      ApiConstants.liveClass(id),
      data: {
        'title': title,
        'description': description,
        'courseId': courseId,
        'meetingLink': meetingLink,
        'scheduledDate': scheduledDate,
        'startTime': startTime,
        'duration': duration,
        'thumbnail': thumbnail,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return LiveClassModel.fromJson(
      Map<String, dynamic>.from(data['data'] as Map),
    );
  }

  /// DELETE /api/live-classes/:id
  Future<void> deleteLiveClass(String id) async {
    await _client.delete(ApiConstants.liveClass(id));
  }

  /// PATCH /api/live-classes/:id/start — forces startTime to now and flips
  /// status to `live`.
  Future<LiveClassModel> startLiveClass(String id) async {
    final response = await _client.patch(ApiConstants.startLiveClass(id));
    final data = response.data as Map<String, dynamic>;
    return LiveClassModel.fromJson(
      Map<String, dynamic>.from(data['data'] as Map),
    );
  }

  /// PATCH /api/live-classes/:id/end — forces endTime to now and flips
  /// status to `ended`.
  Future<LiveClassModel> endLiveClass(String id) async {
    final response = await _client.patch(ApiConstants.endLiveClass(id));
    final data = response.data as Map<String, dynamic>;
    return LiveClassModel.fromJson(
      Map<String, dynamic>.from(data['data'] as Map),
    );
  }
}
