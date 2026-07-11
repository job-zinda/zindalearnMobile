import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/message_provider.dart';
import '../screens/certificates_screen.dart';
import '../screens/help_support_screen.dart';
import '../screens/live_classes_screen.dart';
import '../screens/progress_screen.dart';
import '../screens/settings_screen.dart';
import '../theme/app_colors.dart';

/// Shared side drawer for sections that don't fit the bottom nav — reachable
/// via a menu icon on every top-level screen (Home, Browse, Learning,
/// Messages, Profile).
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _openScreen(BuildContext context, Widget screen) {
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _signOut(BuildContext context) async {
    // Capture the navigator and providers before popping the drawer —
    // popping unmounts this context, so anything read from it after the
    // `await` below (including `context.mounted`) would silently no-op.
    final navigator = Navigator.of(context, rootNavigator: true);
    final messageProvider = context.read<MessageProvider>();
    final authProvider = context.read<AuthProvider>();

    Navigator.of(context).pop();
    messageProvider.disconnectAndReset();
    await authProvider.logout();
    navigator.pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final displayName = user?.name ?? 'Guest';
    final initials = displayName.trim().isNotEmpty ? displayName.trim()[0].toUpperCase() : '?';
    final avatar = user?.avatar;

    return Drawer(
      backgroundColor: AppColors.surface,
      width: 300,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      image: (avatar != null && avatar.isNotEmpty)
                          ? DecorationImage(image: NetworkImage(avatar), fit: BoxFit.cover)
                          : null,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                    ),
                    alignment: Alignment.center,
                    child: (avatar == null || avatar.isEmpty)
                        ? Text(initials,
                            style: GoogleFonts.dmSans(
                                fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.brand))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                              fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                              fontSize: 12.5, color: Colors.white.withValues(alpha: 0.75)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  _DrawerItem(
                    emoji: '📹',
                    label: 'Live Classes',
                    onTap: () => _openScreen(context, const LiveClassesScreen()),
                  ),
                  _DrawerItem(
                    emoji: '📊',
                    label: 'Progress',
                    onTap: () => _openScreen(context, const ProgressScreen()),
                  ),
                  _DrawerItem(
                    emoji: '🎖️',
                    label: 'Certificates',
                    onTap: () => _openScreen(context, const CertificatesScreen()),
                  ),
                  _DrawerItem(
                    emoji: '⚙️',
                    label: 'Settings',
                    onTap: () => _openScreen(context, const SettingsScreen()),
                  ),
                  _DrawerItem(
                    emoji: '❓',
                    label: 'Help & Support',
                    onTap: () => _openScreen(context, const HelpSupportScreen()),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            _DrawerItem(
              emoji: '🚪',
              label: 'Sign Out',
              color: AppColors.red,
              onTap: () => _signOut(context),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({
    required this.emoji,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Text(emoji, style: const TextStyle(fontSize: 20)),
      title: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: color ?? AppColors.ink,
        ),
      ),
    );
  }
}
