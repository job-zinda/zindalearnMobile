/// Instructor dashboard totals from GET /api/instructor/stats.
class InstructorStats {
  final int totalCourses;
  final int totalStudents;
  final double totalRevenue;
  final double monthlyEarnings;

  InstructorStats({
    this.totalCourses = 0,
    this.totalStudents = 0,
    this.totalRevenue = 0,
    this.monthlyEarnings = 0,
  });

  factory InstructorStats.fromJson(Map<String, dynamic> json) {
    return InstructorStats(
      totalCourses: _toInt(json['totalCourses']),
      totalStudents: _toInt(json['totalStudents']),
      totalRevenue: _toDouble(json['totalRevenue']),
      monthlyEarnings: _toDouble(json['monthlyEarnings']),
    );
  }
}

int _toInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.round();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}
