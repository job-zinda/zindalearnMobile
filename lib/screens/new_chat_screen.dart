import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/chat_contact_model.dart';
import '../providers/course_provider.dart';
import '../providers/message_provider.dart';
import '../theme/app_colors.dart';
import 'chat_screen.dart';

/// Lists eligible contacts to start a new conversation with — for a
/// student, the instructors of their enrolled courses.
class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessageProvider>().loadContacts(refresh: true);
    });
  }

  Future<void> _openChat(ChatContactModel contact) async {
    await context.read<MessageProvider>().startDraft(contact);
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MessageProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(child: _body(provider)),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 18, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
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
          const SizedBox(width: 12),
          Text(
            'New Message',
            style: GoogleFonts.dmSans(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
        ],
      ),
    );
  }

  Widget _body(MessageProvider provider) {
    if (provider.contactsState == LoadState.loading && provider.contacts.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.brand));
    }

    if (provider.contactsState == LoadState.error && provider.contacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 10),
              Text(
                provider.contactsError ?? 'Please try again.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => provider.loadContacts(refresh: true),
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

    if (provider.contacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📭', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 12),
              Text(
                'No contacts yet',
                style: GoogleFonts.dmSans(
                    fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
              const SizedBox(height: 6),
              Text(
                'Enroll in a course to message its instructor.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
      itemCount: provider.contacts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final contact = provider.contacts[i];
        return _ContactTile(contact: contact, onTap: () => _openChat(contact));
      },
    );
  }
}

class _ContactTile extends StatelessWidget {
  final ChatContactModel contact;
  final VoidCallback onTap;
  const _ContactTile({required this.contact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final user = contact.user;
    final avatar = user.avatar;

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
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandFaint,
                image: (avatar != null && avatar.isNotEmpty)
                    ? DecorationImage(image: NetworkImage(avatar), fit: BoxFit.cover)
                    : null,
              ),
              alignment: Alignment.center,
              child: (avatar == null || avatar.isEmpty)
                  ? Text(user.initial,
                      style: GoogleFonts.dmSans(
                          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.brand))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                        fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contact.course.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(fontSize: 12.5, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
          ],
        ),
      ),
    );
  }
}
