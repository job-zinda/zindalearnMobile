import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/constants/api_constants.dart';
import '../core/storage/secure_storage.dart';

/// Thin wrapper around the app-wide Socket.IO connection used for
/// real-time messaging (see zinda-learn-backend/server/sockets/index.js).
class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_socket != null) return;

    final token = await SecureStorage.getToken();
    if (token == null) return;

    _socket = io.io(
      ApiConstants.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket!
      ..onConnect((_) => debugPrint('💬 Socket connected'))
      ..onConnectError((e) => debugPrint('💬 Socket connect error: $e'))
      ..onDisconnect((_) => debugPrint('💬 Socket disconnected'))
      ..connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void joinConversation(String conversationId) =>
      _socket?.emit('joinConversation', conversationId);

  void leaveConversation(String conversationId) =>
      _socket?.emit('leaveConversation', conversationId);

  void markSeen(String conversationId, List<String> messageIds) =>
      _socket?.emit('markAsSeen', {
        'conversationId': conversationId,
        'messageIds': messageIds,
      });

  void typing(String conversationId, String userName) =>
      _socket?.emit('typing', {
        'conversationId': conversationId,
        'userName': userName,
      });

  void stopTyping(String conversationId) =>
      _socket?.emit('stopTyping', {'conversationId': conversationId});

  void on(String event, void Function(dynamic) handler) =>
      _socket?.on(event, handler);

  void off(String event, [void Function(dynamic)? handler]) =>
      _socket?.off(event, handler);
}
