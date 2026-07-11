// An eligible messaging contact (GET /api/messages/eligible-contacts):
// for a student, their enrolled courses' instructors; for an instructor,
// students enrolled in their courses.

import 'conversation_model.dart';
import 'message_model.dart';

class ChatContactModel {
  final ChatUser user;
  final ConversationCourse course;

  ChatContactModel({required this.user, required this.course});

  factory ChatContactModel.fromJson(Map<String, dynamic> json) {
    return ChatContactModel(
      user: ChatUser.fromJson(json['user']),
      course: ConversationCourse.fromJson(json['course']),
    );
  }
}
