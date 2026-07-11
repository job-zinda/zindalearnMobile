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
    final response = await _client.post(ApiConstants.joinLiveClass(liveClassId));
    final data = response.data as Map<String, dynamic>;
    final result = data['data'] as Map<String, dynamic>?;
    return (result?['meetingLink'] ?? '').toString();
  }
}
