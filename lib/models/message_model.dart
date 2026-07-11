// Models for direct messaging, mapped to the backend `Message` schema
// (see zinda-learn-backend/server/models/Message.js).

/// A participant in a conversation, or a message sender. Populated
/// selections from the backend vary by endpoint (sometimes just
/// `_id`/`name`/`avatar`), so every field beyond `id` is optional.
class ChatUser {
  final String id;
  final String name;
  final String? avatar;
  final String? role;

  ChatUser({
    required this.id,
    required this.name,
    this.avatar,
    this.role,
  });

  factory ChatUser.fromJson(dynamic json) {
    if (json is! Map) {
      return ChatUser(id: json?.toString() ?? '', name: 'User');
    }
    return ChatUser(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: (json['name'] ?? 'User').toString(),
      avatar: json['avatar']?.toString(),
      role: json['role']?.toString(),
    );
  }

  String get initial => name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
}

class MessageAttachment {
  final String url;
  final String? name;
  final String? type;

  MessageAttachment({required this.url, this.name, this.type});

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      url: (json['url'] ?? '').toString(),
      name: json['name']?.toString(),
      type: json['type']?.toString(),
    );
  }
}

class MessageModel {
  final String id;
  final String conversationId;
  final ChatUser sender;
  final String? text;
  final String messageType; // text | image | audio | file
  final List<MessageAttachment> attachments;
  final List<String> readBy;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.sender,
    this.text,
    this.messageType = 'text',
    this.attachments = const [],
    this.readBy = const [],
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final rawAttachments = json['attachments'];
    final rawReadBy = json['readBy'];
    final rawConversation = json['conversation'];
    return MessageModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      conversationId: rawConversation is Map
          ? (rawConversation['_id']?.toString() ?? '')
          : (rawConversation?.toString() ?? ''),
      sender: ChatUser.fromJson(json['sender']),
      text: json['text']?.toString(),
      messageType: (json['messageType'] ?? 'text').toString(),
      attachments: rawAttachments is List
          ? rawAttachments
              .whereType<Map>()
              .map((a) => MessageAttachment.fromJson(Map<String, dynamic>.from(a)))
              .toList()
          : const [],
      readBy: rawReadBy is List ? rawReadBy.map((e) => e.toString()).toList() : const [],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// A short, human label for the bubble when there's no plain text
  /// (voice notes / images / files), matching the backend's fallback text.
  String get previewText {
    if (text != null && text!.isNotEmpty) return text!;
    switch (messageType) {
      case 'audio':
        return '🎵 Voice message';
      case 'image':
        return '🖼️ Image';
      case 'file':
        return '📎 Attachment';
      default:
        return '';
    }
  }

  bool isReadBy(String userId) => readBy.contains(userId);
}
