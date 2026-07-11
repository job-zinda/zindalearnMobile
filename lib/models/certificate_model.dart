// Mapped to the backend `Certificate` schema
// (see zinda-learn-backend/server/models/Certificate.js).

class CertificateStats {
  final int certificatesEarned;
  final int coursesCompleted;
  final int skillsAcquired;

  CertificateStats({
    this.certificatesEarned = 0,
    this.coursesCompleted = 0,
    this.skillsAcquired = 0,
  });

  factory CertificateStats.fromJson(Map<String, dynamic> json) {
    int i(dynamic v) => (v is num) ? v.toInt() : 0;
    return CertificateStats(
      certificatesEarned: i(json['certificatesEarned']),
      coursesCompleted: i(json['coursesCompleted']),
      skillsAcquired: i(json['skillsAcquired']),
    );
  }
}

class CertificateModel {
  final String id;
  final String certificateId;
  final String courseTitle;
  final String? courseThumbnail;
  final String instructorName;
  final DateTime issueDate;
  final List<String> skills;

  CertificateModel({
    required this.id,
    required this.certificateId,
    required this.courseTitle,
    this.courseThumbnail,
    required this.instructorName,
    required this.issueDate,
    this.skills = const [],
  });

  factory CertificateModel.fromJson(Map<String, dynamic> json) {
    final course = json['course'];
    final instructor = course is Map ? course['instructor'] : null;
    final rawSkills = json['skills'];
    return CertificateModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      certificateId: (json['certificateId'] ?? '').toString(),
      courseTitle: course is Map ? (course['title'] ?? 'Course').toString() : 'Course',
      courseThumbnail: course is Map ? course['thumbnail']?.toString() : null,
      instructorName: instructor is Map ? (instructor['name'] ?? 'Instructor').toString() : 'Instructor',
      issueDate: DateTime.tryParse(json['issueDate']?.toString() ?? '') ?? DateTime.now(),
      skills: rawSkills is List ? rawSkills.map((e) => e.toString()).toList() : const [],
    );
  }
}
