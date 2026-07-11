// Mapped to zinda-learn-backend/server/controllers/studentProgress.controller.js
// responses (GET /api/student/progress/overview and /analytics).

class ProgressOverview {
  final int totalEnrolled;
  final int completedCourses;
  final int inProgressCourses;
  final int overallCompletion; // 0-100
  final int totalWatchTime; // minutes
  final int points;
  final int certificates;
  final int liveAttendanceCount;

  ProgressOverview({
    this.totalEnrolled = 0,
    this.completedCourses = 0,
    this.inProgressCourses = 0,
    this.overallCompletion = 0,
    this.totalWatchTime = 0,
    this.points = 0,
    this.certificates = 0,
    this.liveAttendanceCount = 0,
  });

  factory ProgressOverview.fromJson(Map<String, dynamic> json) {
    int i(dynamic v) => (v is num) ? v.toInt() : 0;
    return ProgressOverview(
      totalEnrolled: i(json['totalEnrolled']),
      completedCourses: i(json['completedCourses']),
      inProgressCourses: i(json['inProgressCourses']),
      overallCompletion: i(json['overallCompletion']),
      totalWatchTime: i(json['totalWatchTime']),
      points: i(json['points']),
      certificates: i(json['certificates']),
      liveAttendanceCount: i(json['liveAttendanceCount']),
    );
  }

  /// "3h 20m" / "45m" from totalWatchTime minutes.
  String get watchTimeLabel {
    if (totalWatchTime <= 0) return '0m';
    final h = totalWatchTime ~/ 60;
    final m = totalWatchTime % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }
}

class DailyActivity {
  final String day; // "Mon"
  final int minutes;

  DailyActivity({required this.day, required this.minutes});

  factory DailyActivity.fromJson(Map<String, dynamic> json) {
    return DailyActivity(
      day: (json['day'] ?? '').toString(),
      minutes: (json['minutes'] is num) ? (json['minutes'] as num).toInt() : 0,
    );
  }
}
