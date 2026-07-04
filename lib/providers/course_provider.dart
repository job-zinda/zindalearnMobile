import 'package:flutter/foundation.dart';
import '../core/network/api_exceptions.dart';
import '../models/course_model.dart';
import '../services/course_service.dart';

enum LoadState { idle, loading, loaded, error }

/// Holds the Browse Courses catalog: the filtered list, active filters,
/// pagination and load state.
class CourseProvider extends ChangeNotifier {
  final CourseService _service = CourseService();

  final List<CourseModel> _courses = [];
  List<CourseModel> get courses => List.unmodifiable(_courses);

  LoadState _state = LoadState.idle;
  LoadState get state => _state;

  bool _loadingMore = false;
  bool get loadingMore => _loadingMore;

  String? _error;
  String? get error => _error;

  int _page = 1;
  int _pages = 1;
  int _total = 0;
  int get total => _total;
  bool get hasMore => _page < _pages;

  // Active filters
  String? _category; // null => All
  String? _level; // null => All
  String _search = '';

  String? get category => _category;
  String? get level => _level;
  String get search => _search;

  bool get isLoading => _state == LoadState.loading;
  bool get isEmpty => _state == LoadState.loaded && _courses.isEmpty;

  /// First load / refresh with the current filters.
  Future<void> loadCourses({bool refresh = false}) async {
    if (_state == LoadState.loading) return;
    _state = LoadState.loading;
    _error = null;
    if (refresh) {
      _courses.clear();
    }
    notifyListeners();

    try {
      final result = await _service.getCourses(
        category: _category,
        level: _level,
        search: _search,
        page: 1,
      );
      _courses
        ..clear()
        ..addAll(result.courses);
      _page = result.page;
      _pages = result.pages;
      _total = result.total;
      _state = LoadState.loaded;
    } on ApiException catch (e) {
      _error = e.message;
      _state = LoadState.error;
    } catch (_) {
      _error = 'Unable to load courses. Please try again.';
      _state = LoadState.error;
    }
    notifyListeners();
  }

  /// Load the next page (infinite scroll).
  Future<void> loadMore() async {
    if (_loadingMore || !hasMore || _state == LoadState.loading) return;
    _loadingMore = true;
    notifyListeners();

    try {
      final result = await _service.getCourses(
        category: _category,
        level: _level,
        search: _search,
        page: _page + 1,
      );
      _courses.addAll(result.courses);
      _page = result.page;
      _pages = result.pages;
      _total = result.total;
    } catch (_) {
      // Keep existing list on pagination failure.
    }
    _loadingMore = false;
    notifyListeners();
  }

  void setCategory(String? category) {
    if (_category == category) return;
    _category = category;
    loadCourses(refresh: true);
  }

  void setLevel(String? level) {
    if (_level == level) return;
    _level = level;
    loadCourses(refresh: true);
  }

  void setSearch(String value) {
    final trimmed = value.trim();
    if (_search == trimmed) return;
    _search = trimmed;
    loadCourses(refresh: true);
  }

  void clearFilters() {
    _category = null;
    _level = null;
    _search = '';
    loadCourses(refresh: true);
  }
}
