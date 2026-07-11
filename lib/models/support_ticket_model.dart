// Mapped to the backend `SupportTicket` schema
// (see zinda-learn-backend/server/models/SupportTicket.js).

class SupportTicketModel {
  final String id;
  final String subject;
  final String category;
  final String message;
  final String status; // open | pending | resolved | closed
  final String priority; // low | medium | high
  final DateTime createdAt;
  final int replyCount;

  SupportTicketModel({
    required this.id,
    required this.subject,
    required this.category,
    required this.message,
    this.status = 'open',
    this.priority = 'medium',
    required this.createdAt,
    this.replyCount = 0,
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    final replies = json['replies'];
    return SupportTicketModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      subject: (json['subject'] ?? '').toString(),
      category: (json['category'] ?? 'Other').toString(),
      message: (json['message'] ?? '').toString(),
      status: (json['status'] ?? 'open').toString(),
      priority: (json['priority'] ?? 'medium').toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      replyCount: replies is List ? replies.length : 0,
    );
  }
}
