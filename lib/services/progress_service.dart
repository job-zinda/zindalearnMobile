import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/progress_model.dart';

class ProgressService {
  final _client = ApiClient.instance;

  /// GET /api/student/progress/overview
  Future<ProgressOverview> getOverview() async {
    final response = await _client.get(ApiConstants.progressOverview);
    final data = response.data as Map<String, dynamic>;
    return ProgressOverview.fromJson(Map<String, dynamic>.from(data['data']));
  }

  /// GET /api/student/progress/analytics — weekly activity in minutes/day.
  Future<List<DailyActivity>> getWeeklyActivity() async {
    final response = await _client.get(ApiConstants.progressAnalytics);
    final data = response.data as Map<String, dynamic>;
    final analytics = data['data'] as Map<String, dynamic>?;
    final raw = (analytics?['weeklyActivity'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((d) => DailyActivity.fromJson(Map<String, dynamic>.from(d)))
        .toList();
  }
}
