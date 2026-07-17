// Mapped to the backend `LiveClass` schema
// (see zinda-learn-backend/server/modules/liveClasses/models/LiveClass.js).

class LiveClassModel {
  final String id;
  final String title;
  final String description;
  final String instructorName;
  final String? instructorAvatar;
  final String courseId;
  final String courseTitle;
  final String? courseThumbnail;
  final String meetingLink;
  final String? thumbnail;
  final DateTime startTime;
  final DateTime endTime;
  final int duration; // minutes
  final String status; // upcoming | live | ended | cancelled
  // Backend-computed HH:mm / YYYY-MM-DD strings — same fields the web
  // instructor UI uses to prefill the edit form, avoiding any local
  // timezone conversion of `startTime`.
  final String scheduledDateStr;
  final String startTimeStr;

  LiveClassModel({
    required this.id,
    required this.title,
    required this.description,
    required this.instructorName,
    this.instructorAvatar,
    required this.courseId,
    required this.courseTitle,
    this.courseThumbnail,
    required this.meetingLink,
    this.thumbnail,
    required this.startTime,
    required this.endTime,
    this.duration = 0,
    this.status = 'upcoming',
    this.scheduledDateStr = '',
    this.startTimeStr = '',
  });

  factory LiveClassModel.fromJson(Map<String, dynamic> json) {
    final instructor = json['instructor'];
    final course = json['course'];
    return LiveClassModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: (json['title'] ?? 'Live Class').toString(),
      description: (json['description'] ?? '').toString(),
      instructorName: instructor is Map
          ? (instructor['name'] ?? 'Instructor').toString()
          : 'Instructor',
      instructorAvatar: instructor is Map
          ? instructor['avatar']?.toString()
          : null,
      courseId: course is Map
          ? (course['_id']?.toString() ?? '')
          : (course?.toString() ?? ''),
      courseTitle: course is Map
          ? (course['title'] ?? 'Course').toString()
          : 'Course',
      courseThumbnail: course is Map ? course['thumbnail']?.toString() : null,
      meetingLink: (json['meetingLink'] ?? '').toString(),
      thumbnail: json['thumbnail']?.toString(),
      startTime:
          DateTime.tryParse(json['startTime']?.toString() ?? '') ??
          DateTime.now(),
      endTime:
          DateTime.tryParse(json['endTime']?.toString() ?? '') ??
          DateTime.now(),
      duration: (json['duration'] is num)
          ? (json['duration'] as num).toInt()
          : 0,
      status: (json['status'] ?? 'upcoming').toString(),
      scheduledDateStr: (json['scheduledDateStr'] ?? '').toString(),
      startTimeStr: (json['startTimeStr'] ?? '').toString(),
    );
  }

  bool get isLive => status == 'live';
  bool get isUpcoming => status == 'upcoming';
  bool get isCancelled => status == 'cancelled';
  bool get isEnded => status == 'ended' || status == 'cancelled';
}
