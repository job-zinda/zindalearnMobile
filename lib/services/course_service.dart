import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/course_model.dart';

/// Result of a paginated course fetch.
class CoursePage {
  final List<CourseModel> courses;
  final int page;
  final int pages;
  final int total;

  CoursePage({
    required this.courses,
    required this.page,
    required this.pages,
    required this.total,
  });

  bool get hasMore => page < pages;
}

class CourseService {
  final _client = ApiClient.instance;

  /// GET /api/courses — public list of published courses with filters.
  Future<CoursePage> getCourses({
    String? category,
    String? level,
    String? search,
    String? sort,
    int page = 1,
    int limit = 12,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (level != null && level.isNotEmpty) query['level'] = level;
    if (search != null && search.trim().isNotEmpty) query['search'] = search.trim();
    if (sort != null && sort.isNotEmpty) query['sort'] = sort;

    final response = await _client.get(
      ApiConstants.courses,
      queryParameters: query,
    );

    final data = response.data as Map<String, dynamic>;
    final rawCourses = (data['courses'] as List?) ?? const [];
    final pagination = (data['pagination'] as Map?) ?? const {};

    return CoursePage(
      courses: rawCourses
          .whereType<Map>()
          .map((c) => CourseModel.fromJson(Map<String, dynamic>.from(c)))
          .toList(),
      page: _toInt(pagination['page'], page),
      pages: _toInt(pagination['pages'], 1),
      total: _toInt(pagination['total'], rawCourses.length),
    );
  }

  /// GET /api/courses/:id — single course with full curriculum.
  Future<CourseModel> getCourse(String id) async {
    final response = await _client.get(ApiConstants.course(id));
    final data = response.data as Map<String, dynamic>;
    return CourseModel.fromJson(
      Map<String, dynamic>.from(data['course'] as Map),
    );
  }
}

int _toInt(dynamic v, int fallback) {
  if (v is int) return v;
  if (v is num) return v.round();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}
