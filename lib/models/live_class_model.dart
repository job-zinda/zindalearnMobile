// Mapped to the backend `LiveClass` schema
// (see zinda-learn-backend/server/modules/liveClasses/models/LiveClass.js).

class LiveClassModel {
  final String id;
  final String title;
  final String description;
  final String instructorName;
  final String? instructorAvatar;
  final String courseTitle;
  final String? courseThumbnail;
  final String meetingLink;
  final DateTime startTime;
  final DateTime endTime;
  final int duration; // minutes
  final String status; // upcoming | live | ended | cancelled

  LiveClassModel({
    required this.id,
    required this.title,
    required this.description,
    required this.instructorName,
    this.instructorAvatar,
    required this.courseTitle,
    this.courseThumbnail,
    required this.meetingLink,
    required this.startTime,
    required this.endTime,
    this.duration = 0,
    this.status = 'upcoming',
  });

  factory LiveClassModel.fromJson(Map<String, dynamic> json) {
    final instructor = json['instructor'];
    final course = json['course'];
    return LiveClassModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: (json['title'] ?? 'Live Class').toString(),
      description: (json['description'] ?? '').toString(),
      instructorName: instructor is Map ? (instructor['name'] ?? 'Instructor').toString() : 'Instructor',
      instructorAvatar: instructor is Map ? instructor['avatar']?.toString() : null,
      courseTitle: course is Map ? (course['title'] ?? 'Course').toString() : 'Course',
      courseThumbnail: course is Map ? course['thumbnail']?.toString() : null,
      meetingLink: (json['meetingLink'] ?? '').toString(),
      startTime: DateTime.tryParse(json['startTime']?.toString() ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(json['endTime']?.toString() ?? '') ?? DateTime.now(),
      duration: (json['duration'] is num) ? (json['duration'] as num).toInt() : 0,
      status: (json['status'] ?? 'upcoming').toString(),
    );
  }

  bool get isLive => status == 'live';
  bool get isUpcoming => status == 'upcoming';
  bool get isEnded => status == 'ended' || status == 'cancelled';
}
