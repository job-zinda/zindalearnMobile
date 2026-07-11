import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/utils/formatters.dart';
import '../models/message_model.dart';
import '../providers/auth_provider.dart';
import '../providers/course_provider.dart';
import '../providers/message_provider.dart';
import '../theme/app_colors.dart';

/// Thread view for one conversation. Expects the caller to have already
/// called [MessageProvider.openConversation] or [MessageProvider.startDraft]
/// before pushing this screen.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send(String myUserId) async {
    final text = _textCtrl.text;
    if (text.trim().isEmpty) return;
    _textCtrl.clear();
    final error = await context.read<MessageProvider>().send(
          text: text,
          myUserId: myUserId,
        );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MessageProvider>();
    final myId = context.read<AuthProvider>().user?.id ?? '';
    final conversation = provider.activeConversation;
    final draft = provider.draftContact;

    final title = conversation != null
        ? conversation.otherParticipant(myId).name
        : draft?.user.name ?? 'Chat';
    final subtitle = conversation?.course?.title ?? draft?.course.title;
    final avatar = conversation != null
        ? conversation.otherParticipant(myId).avatar
        : draft?.user.avatar;
    final initial = title.trim().isNotEmpty ? title.trim()[0].toUpperCase() : '?';

    if (provider.activeMessages.isNotEmpty) _scrollToBottom();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _header(title, subtitle, avatar, initial),
          Expanded(child: _body(provider)),
          _composer(myId, provider.sending),
        ],
      ),
    );
  }

  Widget _header(String title, String? subtitle, String? avatar, String initial) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(14, 8, 18, 12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                context.read<MessageProvider>().closeConversation();
                Navigator.of(context).pop();
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: AppColors.ink),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandFaint,
                image: (avatar != null && avatar.isNotEmpty)
                    ? DecorationImage(image: NetworkImage(avatar), fit: BoxFit.cover)
                    : null,
              ),
              alignment: Alignment.center,
              child: (avatar == null || avatar.isEmpty)
                  ? Text(initial,
                      style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brand))
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                        fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(MessageProvider provider) {
    if (provider.activeState == LoadState.loading && provider.activeMessages.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.brand));
    }

    if (provider.activeState == LoadState.error && provider.activeMessages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 10),
              Text(
                'Couldn’t load this conversation.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () {
                  final id = provider.activeConversationId;
                  if (id != null) provider.openConversation(id);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Retry',
                      style: GoogleFonts.dmSans(
                          fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.activeMessages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Say hello 👋\nStart the conversation below.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.muted, height: 1.5),
          ),
        ),
      );
    }

    final myId = context.read<AuthProvider>().user?.id ?? '';

    return ListView.builder(
      controller: _scrollCtrl,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      itemCount: provider.activeMessages.length,
      itemBuilder: (context, i) {
        final msg = provider.activeMessages[i];
        final isMine = msg.sender.id == myId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _Bubble(message: msg, isMine: isMine),
        );
      },
    );
  }

  Widget _composer(String myId, bool sending) {
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _textCtrl,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.ink),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Message…',
                    hintStyle: GoogleFonts.dmSans(fontSize: 14, color: AppColors.faint),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (_) => _send(myId),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: sending ? null : () => _send(myId),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: sending ? AppColors.faint : AppColors.brand,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.arrow_upward_rounded, size: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  const _Bubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMine ? AppColors.brand : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMine ? 16 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 16),
              ),
              border: isMine ? null : Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.previewText,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    height: 1.4,
                    color: isMine ? Colors.white : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.timeOfDay(message.createdAt),
                  style: GoogleFonts.dmSans(
                    fontSize: 10.5,
                    color: isMine ? Colors.white.withValues(alpha: 0.7) : AppColors.faint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
