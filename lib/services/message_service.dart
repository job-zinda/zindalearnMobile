import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/chat_contact_model.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class SentMessageResult {
  final MessageModel message;
  final String conversationId;
  SentMessageResult({required this.message, required this.conversationId});
}

class MessageService {
  final _client = ApiClient.instance;

  /// GET /api/messages/conversations
  Future<List<ConversationModel>> getConversations() async {
    final response = await _client.get(ApiConstants.conversations);
    final data = response.data as Map<String, dynamic>;
    final raw = (data['conversations'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((c) => ConversationModel.fromJson(Map<String, dynamic>.from(c)))
        .toList();
  }

  /// GET /api/messages/eligible-contacts
  Future<List<ChatContactModel>> getEligibleContacts() async {
    final response = await _client.get(ApiConstants.eligibleContacts);
    final data = response.data as Map<String, dynamic>;
    final raw = (data['contacts'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((c) => ChatContactModel.fromJson(Map<String, dynamic>.from(c)))
        .toList();
  }

  /// GET /api/messages/:conversationId
  Future<List<MessageModel>> getMessages(String conversationId) async {
    final response = await _client.get(
      ApiConstants.conversationMessages(conversationId),
    );
    final data = response.data as Map<String, dynamic>;
    final raw = (data['messages'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((m) => MessageModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  /// POST /api/messages — sends a text message, creating the conversation
  /// on the backend if this is the first message between the pair.
  Future<SentMessageResult> sendMessage({
    required String receiverId,
    required String courseId,
    required String text,
  }) async {
    final response = await _client.post(
      ApiConstants.sendMessage,
      data: {
        'receiverId': receiverId,
        'courseId': courseId,
        'text': text,
        'messageType': 'text',
      },
    );
    final data = response.data as Map<String, dynamic>;
    return SentMessageResult(
      message: MessageModel.fromJson(Map<String, dynamic>.from(data['message'])),
      conversationId: data['conversationId'].toString(),
    );
  }

  /// PUT /api/messages/:conversationId/read
  Future<void> markAsRead(String conversationId) async {
    await _client.put(ApiConstants.markConversationRead(conversationId));
  }
}
