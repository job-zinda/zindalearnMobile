import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/message_provider.dart';
import '../theme/app_colors.dart';

class ZLBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const ZLBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const int messagesIndex = 3;

  @override
  Widget build(BuildContext context) {
    final unread = context.select<MessageProvider, int>((p) => p.unreadCount);
    final items = [
      _NavItem(emoji: '🏠', label: 'Home'),
      _NavItem(emoji: '🔍', label: 'Browse'),
      _NavItem(emoji: '📚', label: 'Learning'),
      _NavItem(emoji: '💬', label: 'Messages'),
      _NavItem(emoji: '👤', label: 'Profile'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final active = currentIndex == i;
          final showBadge = i == messagesIndex && unread > 0;
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: active ? 1.0 : 0.35,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Text(items[i].emoji,
                          style: const TextStyle(fontSize: 20)),
                      if (showBadge)
                        Positioned(
                          right: -4,
                          top: -2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    items[i].label,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w400,
                      color: active ? AppColors.brand : AppColors.faint,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final String emoji;
  final String label;
  const _NavItem({required this.emoji, required this.label});
}
