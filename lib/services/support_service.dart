import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/support_ticket_model.dart';

class SupportService {
  final _client = ApiClient.instance;

  /// GET /api/support/tickets — the current user's tickets.
  Future<List<SupportTicketModel>> getMyTickets() async {
    final response = await _client.get(ApiConstants.supportTickets);
    final data = response.data as Map<String, dynamic>;
    final raw = (data['tickets'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((t) => SupportTicketModel.fromJson(Map<String, dynamic>.from(t)))
        .toList();
  }

  /// POST /api/support/tickets
  Future<SupportTicketModel> createTicket({
    required String subject,
    required String category,
    required String message,
  }) async {
    final response = await _client.post(
      ApiConstants.supportTickets,
      data: {'subject': subject, 'category': category, 'message': message},
    );
    final data = response.data as Map<String, dynamic>;
    return SupportTicketModel.fromJson(Map<String, dynamic>.from(data['ticket']));
  }
}
