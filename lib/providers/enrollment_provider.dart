import 'package:flutter/foundation.dart';
import '../core/network/api_exceptions.dart';
import '../models/enrollment_model.dart';
import '../services/enrollment_service.dart';
import 'course_provider.dart';

/// Holds the current user's enrollments ("My Learning") and the enroll action.
class EnrollmentProvider extends ChangeNotifier {
  final EnrollmentService _service = EnrollmentService();

  final List<EnrollmentModel> _enrollments = [];
  List<EnrollmentModel> get enrollments => List.unmodifiable(_enrollments);

  LoadState _state = LoadState.idle;
  LoadState get state => _state;

  String? _error;
  String? get error => _error;

  final Set<String> _enrolling = {}; // courseIds currently being enrolled

  bool get isLoading => _state == LoadState.loading;
  bool get isEmpty => _state == LoadState.loaded && _enrollments.isEmpty;

  /// Enrollments that are started but not finished.
  List<EnrollmentModel> get inProgress => _enrollments
      .where((e) => e.course != null && !e.isCompleted)
      .toList();

  List<EnrollmentModel> get completed =>
      _enrollments.where((e) => e.course != null && e.isCompleted).toList();

  bool isEnrolled(String courseId) =>
      _enrollments.any((e) => e.course?.id == courseId);

  bool isEnrolling(String courseId) => _enrolling.contains(courseId);

  Future<void> loadEnrollments({bool refresh = false}) async {
    if (_state == LoadState.loading) return;
    _state = LoadState.loading;
    _error = null;
    if (refresh) _enrollments.clear();
    notifyListeners();

    try {
      final result = await _service.getMyEnrollments();
      _enrollments
        ..clear()
        ..addAll(result.where((e) => e.course != null));
      _state = LoadState.loaded;
    } on ApiException catch (e) {
      _error = e.message;
      _state = LoadState.error;
    } catch (_) {
      _error = 'Unable to load your courses. Please try again.';
      _state = LoadState.error;
    }
    notifyListeners();
  }

  /// Enrolls in a course. Returns null on success, or an error message.
  Future<String?> enroll(String courseId) async {
    if (_enrolling.contains(courseId)) return null;
    _enrolling.add(courseId);
    notifyListeners();

    try {
      await _service.enroll(courseId);
      // Refresh to pull the populated course into My Learning.
      await loadEnrollments();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Enrollment failed. Please try again.';
    } finally {
      _enrolling.remove(courseId);
      notifyListeners();
    }
  }

  void clear() {
    _enrollments.clear();
    _state = LoadState.idle;
    notifyListeners();
  }
}
