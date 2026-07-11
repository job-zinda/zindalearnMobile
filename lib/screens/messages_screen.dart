import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/utils/formatters.dart';
import '../models/conversation_model.dart';
import '../providers/auth_provider.dart';
import '../providers/course_provider.dart';
import '../providers/message_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/menu_button.dart';
import '../widgets/shimmer.dart';
import 'chat_screen.dart';
import 'new_chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  final ValueChanged<int>? onNavTap;
  final int currentIndex;
  const MessagesScreen({
    super.key,
    this.onNavTap,
    this.currentIndex = ZLBottomNav.messagesIndex,
  });

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<MessageProvider>();
      await provider.connect();
      if (provider.conversationsState == LoadState.idle) {
        provider.loadConversations(refresh: true);
      }
    });
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openConversation(ConversationModel conversation) async {
    await context.read<MessageProvider>().openConversation(conversation.id);
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatScreen()));
  }

  void _openNewChat() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewChatScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MessageProvider>();
    final myId = context.watch<AuthProvider>().user?.id ?? '';

    final filtered = _query.isEmpty
        ? provider.conversations
        : provider.conversations.where((c) {
            final other = c.otherParticipant(myId).name.toLowerCase();
            final course = (c.course?.title ?? '').toLowerCase();
            return other.contains(_query) || course.contains(_query);
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: const AppDrawer(),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.brand,
          onRefresh: () => provider.loadConversations(refresh: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(child: _header()),
              SliverToBoxAdapter(child: _searchBar()),
              _body(provider, filtered, myId),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ZLBottomNav(
        currentIndex: widget.currentIndex,
        onTap: (i) => widget.onNavTap?.call(i),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      child: Row(
        children: [
          const ZLMenuButton(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Messages',
                  style: GoogleFonts.dmSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Chat with your course instructors',
                  style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.muted),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _openNewChat,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.brand,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, size: 20, color: AppColors.faint),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.ink),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  hintText: 'Search chats…',
                  hintStyle: GoogleFonts.dmSans(fontSize: 14, color: AppColors.faint),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(MessageProvider provider, List<ConversationModel> filtered, String myId) {
    if (provider.conversationsState == LoadState.loading && provider.conversations.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        sliver: SliverList.separated(
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, _) => const _ConversationSkeleton(),
        ),
      );
    }

    if (provider.conversationsState == LoadState.error && provider.conversations.isEmpty) {
      return SliverToBoxAdapter(
        child: _ErrorState(
          message: provider.conversationsError ?? 'Please try again.',
          onRetry: () => provider.loadConversations(refresh: true),
        ),
      );
    }

    if (provider.conversations.isEmpty) {
      return SliverToBoxAdapter(child: _EmptyState(onStartChat: _openNewChat));
    }

    if (filtered.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text(
              'No chats match “${_searchCtrl.text}”',
              style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.muted),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      sliver: SliverList.separated(
        itemCount: filtered.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final conversation = filtered[i];
          return _ConversationTile(
            conversation: conversation,
            myUserId: myId,
            unread: provider.hasUnread(conversation.id),
            onTap: () => _openConversation(conversation),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final String myUserId;
  final bool unread;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.myUserId,
    required this.unread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final other = conversation.otherParticipant(myUserId);
    final avatar = other.avatar;
    final lastMessage = conversation.lastMessage;
    final preview = lastMessage != null && lastMessage.text.isNotEmpty
        ? (lastMessage.senderId == myUserId ? 'You: ${lastMessage.text}' : lastMessage.text)
        : 'Say hello 👋';
    final time = lastMessage?.createdAt ?? conversation.updatedAt;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.brandFaint,
                    image: (avatar != null && avatar.isNotEmpty)
                        ? DecorationImage(image: NetworkImage(avatar), fit: BoxFit.cover)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: (avatar == null || avatar.isEmpty)
                      ? Text(other.initial,
                          style: GoogleFonts.dmSans(
                              fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.brand))
                      : null,
                ),
                if (unread)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          other.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            fontSize: 14.5,
                            fontWeight: unread ? FontWeight.w800 : FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      Text(
                        Formatters.chatTimestamp(time),
                        style: GoogleFonts.dmSans(
                          fontSize: 11.5,
                          fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
                          color: unread ? AppColors.brand : AppColors.faint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  if (conversation.course != null)
                    Text(
                      conversation.course!.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(fontSize: 11.5, color: AppColors.brand),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                      color: unread ? AppColors.ink : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onStartChat;
  const _EmptyState({required this.onStartChat});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandFaint,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  size: 40, color: AppColors.brand),
            ),
            const SizedBox(height: 20),
            Text(
              'No active chats',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a chat to view your messages or start a\nnew one with your instructors.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 14, height: 1.5, color: AppColors.muted),
            ),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: onStartChat,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Start New Chat',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 60, 32, 40),
      child: Column(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 46)),
          const SizedBox(height: 14),
          Text(
            'Couldn’t load your messages',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationSkeleton extends StatelessWidget {
  const _ConversationSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          const ShimmerBox(
            width: 48,
            height: 48,
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const ShimmerBox(width: 120, height: 12),
                const SizedBox(height: 8),
                const ShimmerBox(width: 180, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
