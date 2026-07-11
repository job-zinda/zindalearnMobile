import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/network/api_exceptions.dart';
import '../models/chat_contact_model.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';
import '../services/socket_service.dart';
import 'course_provider.dart';

/// Holds conversations, the open thread, eligible contacts, and the
/// real-time Socket.IO wiring behind the Messages screens.
class MessageProvider extends ChangeNotifier {
  final MessageService _service = MessageService();
  final SocketService _socket = SocketService.instance;
  bool _listenersRegistered = false;

  final List<ConversationModel> _conversations = [];
  List<ConversationModel> get conversations => List.unmodifiable(_conversations);
  LoadState _conversationsState = LoadState.idle;
  LoadState get conversationsState => _conversationsState;
  String? _conversationsError;
  String? get conversationsError => _conversationsError;

  final List<ChatContactModel> _contacts = [];
  List<ChatContactModel> get contacts => List.unmodifiable(_contacts);
  LoadState _contactsState = LoadState.idle;
  LoadState get contactsState => _contactsState;
  String? _contactsError;
  String? get contactsError => _contactsError;

  String? _activeConversationId;
  String? get activeConversationId => _activeConversationId;
  ConversationModel? get activeConversation => _findConversation(_activeConversationId);
  final List<MessageModel> _activeMessages = [];
  List<MessageModel> get activeMessages => List.unmodifiable(_activeMessages);
  LoadState _activeState = LoadState.idle;
  LoadState get activeState => _activeState;

  ChatContactModel? _draftContact;
  ChatContactModel? get draftContact => _draftContact;

  bool _sending = false;
  bool get sending => _sending;

  final Set<String> _conversationsWithActivity = {};
  bool hasUnread(String conversationId) => _conversationsWithActivity.contains(conversationId);
  int get unreadCount => _conversationsWithActivity.length;

  /// Connects the socket (if not already) and starts listening for
  /// real-time message events. Safe to call multiple times.
  Future<void> connect() async {
    await _socket.connect();
    if (!_listenersRegistered) {
      _socket.on('newMessage', _onNewMessage);
      _socket.on('newNotification', _onNewNotification);
      _listenersRegistered = true;
    }
  }

  /// Tears down the socket connection and clears in-memory state — call on
  /// logout so the next login doesn't reuse a stale connection or data.
  void disconnectAndReset() {
    _socket.off('newMessage', _onNewMessage);
    _socket.off('newNotification', _onNewNotification);
    _listenersRegistered = false;
    _socket.disconnect();

    _conversations.clear();
    _conversationsState = LoadState.idle;
    _contacts.clear();
    _contactsState = LoadState.idle;
    _activeMessages.clear();
    _activeConversationId = null;
    _draftContact = null;
    _conversationsWithActivity.clear();
    notifyListeners();
  }

  Future<void> loadConversations({bool refresh = false, bool silent = false}) async {
    if (_conversationsState == LoadState.loading) return;
    if (!silent) {
      _conversationsState = LoadState.loading;
      _conversationsError = null;
      if (refresh) _conversations.clear();
      notifyListeners();
    }

    try {
      final result = await _service.getConversations();
      result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _conversations
        ..clear()
        ..addAll(result);
      _conversationsState = LoadState.loaded;
    } on ApiException catch (e) {
      _conversationsError = e.message;
      _conversationsState = LoadState.error;
    } catch (_) {
      _conversationsError = 'Unable to load your messages. Please try again.';
      _conversationsState = LoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadContacts({bool refresh = false}) async {
    if (_contactsState == LoadState.loading) return;
    _contactsState = LoadState.loading;
    _contactsError = null;
    if (refresh) _contacts.clear();
    notifyListeners();

    try {
      final result = await _service.getEligibleContacts();
      _contacts
        ..clear()
        ..addAll(result);
      _contactsState = LoadState.loaded;
    } on ApiException catch (e) {
      _contactsError = e.message;
      _contactsState = LoadState.error;
    } catch (_) {
      _contactsError = 'Unable to load your contacts. Please try again.';
      _contactsState = LoadState.error;
    }
    notifyListeners();
  }

  /// Opens an existing conversation from the list.
  Future<void> openConversation(String conversationId) async {
    if (_activeConversationId != null && _activeConversationId != conversationId) {
      _socket.leaveConversation(_activeConversationId!);
    }
    _activeConversationId = conversationId;
    _draftContact = null;
    _activeMessages.clear();
    _activeState = LoadState.loading;
    _conversationsWithActivity.remove(conversationId);
    notifyListeners();

    _socket.joinConversation(conversationId);

    try {
      final messages = await _service.getMessages(conversationId);
      _activeMessages
        ..clear()
        ..addAll(messages);
      _activeState = LoadState.loaded;
    } catch (_) {
      _activeState = LoadState.error;
    }
    notifyListeners();

    try {
      await _service.markAsRead(conversationId);
    } catch (_) {
      // Non-critical — read state will settle on next load.
    }
  }

  /// Prepares a brand-new thread with a contact that has no conversation
  /// yet. If one already exists (same instructor + course), opens it instead.
  Future<void> startDraft(ChatContactModel contact) async {
    for (final c in _conversations) {
      final matchesCourse = c.course?.id == contact.course.id;
      final matchesUser = c.participants.any((p) => p.id == contact.user.id);
      if (matchesCourse && matchesUser) {
        await openConversation(c.id);
        return;
      }
    }

    if (_activeConversationId != null) {
      _socket.leaveConversation(_activeConversationId!);
    }
    _activeConversationId = null;
    _draftContact = contact;
    _activeMessages.clear();
    _activeState = LoadState.loaded;
    notifyListeners();
  }

  void closeConversation() {
    if (_activeConversationId != null) {
      _socket.leaveConversation(_activeConversationId!);
    }
    _activeConversationId = null;
    _draftContact = null;
    _activeMessages.clear();
    _activeState = LoadState.idle;
    notifyListeners();
  }

  /// Sends a text message in the active thread (existing conversation or
  /// draft). Returns an error message on failure, or null on success.
  Future<String?> send({required String text, required String myUserId}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _sending) return null;

    String? receiverId;
    String? courseId;

    final activeConvo = _findConversation(_activeConversationId);
    if (activeConvo != null) {
      receiverId = activeConvo.otherParticipant(myUserId).id;
      courseId = activeConvo.course?.id;
    } else if (_draftContact != null) {
      receiverId = _draftContact!.user.id;
      courseId = _draftContact!.course.id;
    }

    if (receiverId == null || receiverId.isEmpty || courseId == null || courseId.isEmpty) {
      return 'Unable to determine the recipient for this chat.';
    }

    _sending = true;
    notifyListeners();

    try {
      final result = await _service.sendMessage(
        receiverId: receiverId,
        courseId: courseId,
        text: trimmed,
      );

      if (_activeConversationId == null) {
        _activeConversationId = result.conversationId;
        _draftContact = null;
        _socket.joinConversation(result.conversationId);
        unawaited(loadConversations(refresh: true, silent: true));
      }

      if (!_activeMessages.any((m) => m.id == result.message.id)) {
        _activeMessages.add(result.message);
      }
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Failed to send message. Please try again.';
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  ConversationModel? _findConversation(String? id) {
    if (id == null) return null;
    for (final c in _conversations) {
      if (c.id == id) return c;
    }
    return null;
  }

  void _onNewMessage(dynamic data) {
    try {
      final msg = MessageModel.fromJson(Map<String, dynamic>.from(data as Map));
      if (msg.conversationId == _activeConversationId) {
        if (!_activeMessages.any((m) => m.id == msg.id)) {
          _activeMessages.add(msg);
          notifyListeners();
        }
      }
    } catch (_) {
      // Ignore malformed payloads.
    }
  }

  void _onNewNotification(dynamic data) {
    try {
      final map = Map<String, dynamic>.from(data as Map);
      final conversationId = map['conversationId']?.toString();
      if (conversationId != null && conversationId != _activeConversationId) {
        _conversationsWithActivity.add(conversationId);
      }
      unawaited(loadConversations(refresh: true, silent: true));
      notifyListeners();
    } catch (_) {
      // Ignore malformed payloads.
    }
  }
}
