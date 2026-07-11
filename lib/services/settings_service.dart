import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

class NotificationPreferences {
  final bool emailNotifications;
  final bool liveClassReminders;
  final bool chatMessages;
  final bool courseUpdates;

  NotificationPreferences({
    this.emailNotifications = true,
    this.liveClassReminders = true,
    this.chatMessages = true,
    this.courseUpdates = true,
  });

  factory NotificationPreferences.fromJson(dynamic json) {
    if (json is! Map) return NotificationPreferences();
    bool b(dynamic v, bool fallback) => v is bool ? v : fallback;
    return NotificationPreferences(
      emailNotifications: b(json['emailNotifications'], true),
      liveClassReminders: b(json['liveClassReminders'], true),
      chatMessages: b(json['chatMessages'], true),
      courseUpdates: b(json['courseUpdates'], true),
    );
  }

  NotificationPreferences copyWith({
    bool? emailNotifications,
    bool? liveClassReminders,
    bool? chatMessages,
    bool? courseUpdates,
  }) {
    return NotificationPreferences(
      emailNotifications: emailNotifications ?? this.emailNotifications,
      liveClassReminders: liveClassReminders ?? this.liveClassReminders,
      chatMessages: chatMessages ?? this.chatMessages,
      courseUpdates: courseUpdates ?? this.courseUpdates,
    );
  }
}

class SettingsService {
  final _client = ApiClient.instance;

  /// GET /api/student/settings — full user doc, used here for
  /// notificationPreferences.
  Future<NotificationPreferences> getNotificationPreferences() async {
    final response = await _client.get(ApiConstants.settings);
    final data = response.data as Map<String, dynamic>;
    final user = data['data'] as Map<String, dynamic>?;
    return NotificationPreferences.fromJson(user?['notificationPreferences']);
  }

  /// PUT /api/student/settings/notifications
  Future<void> updateNotificationPreferences(NotificationPreferences prefs) async {
    await _client.put(
      ApiConstants.updateNotifications,
      data: {
        'emailNotifications': prefs.emailNotifications,
        'liveClassReminders': prefs.liveClassReminders,
        'chatMessages': prefs.chatMessages,
        'courseUpdates': prefs.courseUpdates,
      },
    );
  }
}
