// Enrollment model mapped to the backend `Enrollment` schema
// (see zinda-learn-backend/server/models/Enrollment.js). Each enrollment
// embeds the populated course.

import 'course_model.dart';

class CurrentLesson {
  final int moduleIndex;
  final int lessonIndex;
  final String lessonId;

  CurrentLesson({
    this.moduleIndex = 0,
    this.lessonIndex = 0,
    this.lessonId = '',
  });

  factory CurrentLesson.fromJson(dynamic json) {
    if (json is! Map) return CurrentLesson();
    return CurrentLesson(
      moduleIndex: (json['moduleIndex'] is num)
          ? (json['moduleIndex'] as num).toInt()
          : 0,
      lessonIndex: (json['lessonIndex'] is num)
          ? (json['lessonIndex'] as num).toInt()
          : 0,
      lessonId: (json['lessonId'] ?? '').toString(),
    );
  }
}

class EnrollmentModel {
  final String id;
  final CourseModel? course;
  final int progress; // 0-100
  final List<String> completedLessons;
  final CurrentLesson currentLesson;
  final bool isCompleted;
  final DateTime? lastWatchedAt;

  EnrollmentModel({
    required this.id,
    this.course,
    this.progress = 0,
    this.completedLessons = const [],
    CurrentLesson? currentLesson,
    this.isCompleted = false,
    this.lastWatchedAt,
  }) : currentLesson = currentLesson ?? CurrentLesson();

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    final rawCourse = json['course'];
    final completed = json['completedLessons'];
    return EnrollmentModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      course: rawCourse is Map
          ? CourseModel.fromJson(Map<String, dynamic>.from(rawCourse))
          : null,
      progress: (json['progress'] is num)
          ? (json['progress'] as num).round()
          : 0,
      completedLessons:
          completed is List ? completed.map((e) => e.toString()).toList() : const [],
      currentLesson: CurrentLesson.fromJson(json['currentLesson']),
      isCompleted: json['isCompleted'] == true,
      lastWatchedAt: json['lastWatchedAt'] != null
          ? DateTime.tryParse(json['lastWatchedAt'].toString())
          : null,
    );
  }

  bool get notStarted => progress <= 0;
}
