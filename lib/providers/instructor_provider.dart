import 'package:flutter/foundation.dart';
import '../core/network/api_exceptions.dart';
import '../models/course_model.dart';
import '../models/instructor_stats_model.dart';
import '../services/instructor_service.dart';
import 'course_provider.dart';

/// Instructor Studio state: dashboard totals and the instructor's own course
/// list (with status filter/pagination), plus the create/delete actions that
/// need to keep that list in sync. Per-course edits (curriculum, submit for
/// review, update info) are made directly against [InstructorService] from
/// the Manage Course screen — same pattern as the student
/// [CourseDetailScreen], which talks to CourseService directly rather than
/// funnelling single-course edits through a provider.
class InstructorProvider extends ChangeNotifier {
  final InstructorService _service = InstructorService();

  // ---- Stats ----
  InstructorStats _stats = InstructorStats();
  InstructorStats get stats => _stats;

  LoadState _statsState = LoadState.idle;
  LoadState get statsState => _statsState;

  Future<void> loadStats() async {
    _statsState = LoadState.loading;
    notifyListeners();
    try {
      _stats = await _service.getDashboardStats();
      _statsState = LoadState.loaded;
    } catch (_) {
      _statsState = LoadState.error;
    }
    notifyListeners();
  }

  // ---- My Courses ----
  final List<CourseModel> _myCourses = [];
  List<CourseModel> get myCourses => List.unmodifiable(_myCourses);

  LoadState _myCoursesState = LoadState.idle;
  LoadState get myCoursesState => _myCoursesState;

  String? _myCoursesError;
  String? get myCoursesError => _myCoursesError;

  bool _loadingMore = false;
  bool get loadingMore => _loadingMore;

  int _page = 1;
  int _pages = 1;
  int get total => _total;
  int _total = 0;
  bool get hasMore => _page < _pages;

  String _statusFilter = 'All';
  String get statusFilter => _statusFilter;

  Future<void> loadMyCourses({bool refresh = false}) async {
    if (_myCoursesState == LoadState.loading) return;
    _myCoursesState = LoadState.loading;
    _myCoursesError = null;
    if (refresh) _myCourses.clear();
    notifyListeners();

    try {
      final result = await _service.getMyCourses(
        page: 1,
        status: _statusFilter,
      );
      _myCourses
        ..clear()
        ..addAll(result.courses);
      _page = result.page;
      _pages = result.pages;
      _total = result.total;
      _myCoursesState = LoadState.loaded;
    } on ApiException catch (e) {
      _myCoursesError = e.message;
      _myCoursesState = LoadState.error;
    } catch (_) {
      _myCoursesError = 'Unable to load your courses. Please try again.';
      _myCoursesState = LoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_loadingMore || !hasMore || _myCoursesState == LoadState.loading) return;
    _loadingMore = true;
    notifyListeners();

    try {
      final result = await _service.getMyCourses(
        page: _page + 1,
        status: _statusFilter,
      );
      _myCourses.addAll(result.courses);
      _page = result.page;
      _pages = result.pages;
      _total = result.total;
    } catch (_) {
      // Keep existing list on pagination failure.
    }
    _loadingMore = false;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    if (_statusFilter == status) return;
    _statusFilter = status;
    loadMyCourses(refresh: true);
  }

  /// Creates a course and inserts it at the top of the My Courses list.
  /// No client-side eligibility checks — the backend is the source of truth
  /// for whether this account is allowed to create courses.
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
    String previewVideo = '',
    String previewVideoPublicId = '',
  }) async {
    final course = await _service.createCourse(
      title: title,
      description: description,
      shortDescription: shortDescription,
      category: category,
      level: level,
      price: price,
      discountPrice: discountPrice,
      isFree: isFree,
      thumbnail: thumbnail,
      previewVideo: previewVideo,
      previewVideoPublicId: previewVideoPublicId,
    );
    _myCourses.insert(0, course);
    _total += 1;
    notifyListeners();
    return course;
  }

  /// Deletes a course and removes it from the local list.
  Future<void> deleteCourse(String id) async {
    await _service.deleteCourse(id);
    _myCourses.removeWhere((c) => c.id == id);
    _total = _total > 0 ? _total - 1 : 0;
    notifyListeners();
  }

  /// Replaces a course in the list with fresh data (e.g. after an edit or a
  /// status change made on the Manage Course screen).
  void replaceCourse(CourseModel updated) {
    final index = _myCourses.indexWhere((c) => c.id == updated.id);
    if (index != -1) _myCourses[index] = updated;
    notifyListeners();
  }
}
