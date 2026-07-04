import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/enrollment_model.dart';

class EnrollmentService {
  final _client = ApiClient.instance;

  /// GET /api/enrollments — the current user's enrolled courses.
  Future<List<EnrollmentModel>> getMyEnrollments() async {
    final response = await _client.get(ApiConstants.enrollments);
    final data = response.data as Map<String, dynamic>;
    final raw = (data['enrollments'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((e) => EnrollmentModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// POST /api/enrollments/enroll — enroll in a (free) course.
  Future<EnrollmentModel?> enroll(String courseId) async {
    final response = await _client.post(
      ApiConstants.enroll,
      data: {'courseId': courseId},
    );
    final data = response.data as Map<String, dynamic>;
    final raw = data['enrollment'];
    if (raw is Map) {
      return EnrollmentModel.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }
}
