import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/course_model.dart';
import '../models/instructor_stats_model.dart';

/// Result of a paginated GET /api/instructor/my-courses fetch.
class InstructorCoursePage {
  final List<CourseModel> courses;
  final int page;
  final int pages;
  final int total;

  InstructorCoursePage({
    required this.courses,
    required this.page,
    required this.pages,
    required this.total,
  });

  bool get hasMore => page < pages;
}

/// Instructor-only actions: dashboard stats, own course list, course
/// create/update/delete/submit-for-review, and basic curriculum edits.
/// Endpoint choices mirror what the web app actually calls (see
/// instructorService.js / courseService.js on the web frontend) since both
/// apps share the same backend and some endpoints have server-side quirks
/// (e.g. POST /instructor/course isn't gated by instructor approval while
/// POST /courses is).
class InstructorService {
  final _client = ApiClient.instance;

  Future<InstructorStats> getDashboardStats() async {
    final response = await _client.get(ApiConstants.instructorStats);
    final data = response.data as Map<String, dynamic>;
    return InstructorStats.fromJson(
      Map<String, dynamic>.from(data['data'] as Map),
    );
  }

  Future<InstructorCoursePage> getMyCourses({
    int page = 1,
    int limit = 6,
    String? status,
    String? search,
    String sort = '-createdAt',
  }) async {
    final query = <String, dynamic>{'page': page, 'limit': limit, 'sort': sort};
    if (status != null && status.isNotEmpty && status != 'All') {
      query['status'] = status;
    }
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    final response = await _client.get(
      ApiConstants.instructorMyCourses,
      queryParameters: query,
    );
    final data = response.data as Map<String, dynamic>;
    final rawCourses = (data['courses'] as List?) ?? const [];

    return InstructorCoursePage(
      courses: rawCourses
          .whereType<Map>()
          .map((c) => CourseModel.fromJson(Map<String, dynamic>.from(c)))
          .toList(),
      page: _toInt(data['currentPage'], page),
      pages: _toInt(data['totalPages'], 1),
      total: _toInt(data['totalCourses'], rawCourses.length),
    );
  }

  Future<CourseModel> createCourse({
    required String title,
    required String description,
    String shortDescription = '',
    String category = 'development',
    String level = 'Beginner',
    num price = 0,
    num discountPrice = 0,
    bool isFree = false,
    String thumbnail = '',
  }) async {
    final response = await _client.post(
      ApiConstants.instructorCourse,
      data: {
        'title': title,
        'description': description,
        'shortDescription': shortDescription,
        'category': category.toLowerCase(),
        'level': level,
        'price': isFree ? 0 : price,
        'discountPrice': isFree ? 0 : discountPrice,
        'isFree': isFree,
        'currency': 'INR',
        'thumbnail': thumbnail,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return CourseModel.fromJson(Map<String, dynamic>.from(data['course'] as Map));
  }

  Future<CourseModel> updateCourse(
    String id, {
    required String title,
    required String description,
    String shortDescription = '',
    String category = 'development',
    String level = 'Beginner',
    num price = 0,
    num discountPrice = 0,
    bool isFree = false,
    String? thumbnail,
  }) async {
    final response = await _client.put(
      ApiConstants.course(id),
      data: {
        'title': title,
        'description': description,
        'shortDescription': shortDescription,
        'category': category.toLowerCase(),
        'level': level,
        'price': isFree ? 0 : price,
        'discountPrice': isFree ? 0 : discountPrice,
        'isFree': isFree,
        'thumbnail': ?thumbnail,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return CourseModel.fromJson(Map<String, dynamic>.from(data['course'] as Map));
  }

  Future<void> deleteCourse(String id) async {
    await _client.delete(ApiConstants.instructorCourseId(id));
  }

  Future<CourseModel> submitForReview(String id) async {
    final response = await _client.patch(ApiConstants.submitCourse(id));
    final data = response.data as Map<String, dynamic>;
    return CourseModel.fromJson(Map<String, dynamic>.from(data['course'] as Map));
  }

  Future<CourseModel> addSection(
    String courseId, {
    required String title,
    String description = '',
  }) async {
    final response = await _client.post(
      ApiConstants.courseSections(courseId),
      data: {'title': title, 'description': description},
    );
    final data = response.data as Map<String, dynamic>;
    return CourseModel.fromJson(Map<String, dynamic>.from(data['course'] as Map));
  }

  Future<CourseModel> deleteSection(String courseId, String sectionId) async {
    final response =
        await _client.delete(ApiConstants.courseSection(courseId, sectionId));
    final data = response.data as Map<String, dynamic>;
    return CourseModel.fromJson(Map<String, dynamic>.from(data['course'] as Map));
  }

  Future<CourseModel> addLesson(
    String courseId,
    String sectionId, {
    required String title,
    String description = '',
    String videoUrl = '',
    String source = '',
    int duration = 0,
    bool isFree = false,
  }) async {
    final response = await _client.post(
      ApiConstants.courseLessons(courseId, sectionId),
      data: {
        'title': title,
        'description': description,
        'videoUrl': videoUrl,
        'source': source,
        'duration': duration,
        'isFree': isFree,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return CourseModel.fromJson(Map<String, dynamic>.from(data['course'] as Map));
  }

  Future<CourseModel> deleteLesson(
    String courseId,
    String sectionId,
    String lessonId,
  ) async {
    final response = await _client
        .delete(ApiConstants.courseLesson(courseId, sectionId, lessonId));
    final data = response.data as Map<String, dynamic>;
    return CourseModel.fromJson(Map<String, dynamic>.from(data['course'] as Map));
  }
}

int _toInt(dynamic v, int fallback) {
  if (v is int) return v;
  if (v is num) return v.round();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}
