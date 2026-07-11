// Models for conversation threads, mapped to the backend `Conversation`
// schema (see zinda-learn-backend/server/models/Conversation.js).

import 'message_model.dart';

class ConversationCourse {
  final String id;
  final String title;
  final String? thumbnail;

  ConversationCourse({required this.id, required this.title, this.thumbnail});

  factory ConversationCourse.fromJson(dynamic json) {
    if (json is! Map) {
      return ConversationCourse(id: json?.toString() ?? '', title: 'Course');
    }
    return ConversationCourse(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: (json['title'] ?? 'Course').toString(),
      thumbnail: json['thumbnail']?.toString(),
    );
  }
}

class LastMessagePreview {
  final String text;
  final String? senderId;
  final DateTime? createdAt;

  LastMessagePreview({required this.text, this.senderId, this.createdAt});

  factory LastMessagePreview.fromJson(dynamic json) {
    if (json is! Map) return LastMessagePreview(text: '');
    final rawSender = json['sender'];
    return LastMessagePreview(
      text: (json['text'] ?? '').toString(),
      senderId: rawSender is Map
          ? rawSender['_id']?.toString()
          : rawSender?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class ConversationModel {
  final String id;
  final List<ChatUser> participants;
  final ConversationCourse? course;
  final String type; // direct | broadcast
  final LastMessagePreview? lastMessage;
  final DateTime updatedAt;

  ConversationModel({
    required this.id,
    required this.participants,
    this.course,
    this.type = 'direct',
    this.lastMessage,
    required this.updatedAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final rawParticipants = json['participants'];
    return ConversationModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      participants: rawParticipants is List
          ? rawParticipants.map(ChatUser.fromJson).toList()
          : const [],
      course: json['course'] != null
          ? ConversationCourse.fromJson(json['course'])
          : null,
      type: (json['type'] ?? 'direct').toString(),
      lastMessage: json['lastMessage'] != null
          ? LastMessagePreview.fromJson(json['lastMessage'])
          : null,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// The other side of a direct conversation, relative to the current user.
  ChatUser otherParticipant(String myUserId) {
    return participants.firstWhere(
      (p) => p.id != myUserId,
      orElse: () => participants.isNotEmpty
          ? participants.first
          : ChatUser(id: '', name: 'Unknown'),
    );
  }
}
