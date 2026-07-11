import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/network/api_exceptions.dart';
import '../providers/auth_provider.dart';
import '../services/settings_service.dart';
import '../theme/app_colors.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _service = SettingsService();
  NotificationPreferences? _prefs;
  bool _loadingPrefs = true;
  String? _savingKey;

  @override
  void initState() {
    super.initState();
    _fetchPrefs();
  }

  Future<void> _fetchPrefs() async {
    try {
      final prefs = await _service.getNotificationPreferences();
      if (!mounted) return;
      setState(() {
        _prefs = prefs;
        _loadingPrefs = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPrefs = false);
    }
  }

  Future<void> _togglePref(String key, bool value, NotificationPreferences updated) async {
    final previous = _prefs;
    setState(() {
      _prefs = updated;
      _savingKey = key;
    });
    try {
      await _service.updateNotificationPreferences(updated);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _prefs = previous);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _prefs = previous);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to update. Please try again.')));
    } finally {
      if (mounted) setState(() => _savingKey = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final prefs = _prefs ?? NotificationPreferences();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            _header(context),
            const SizedBox(height: 20),
            _sectionLabel('Account'),
            const SizedBox(height: 8),
            _card([
              _Row(
                icon: Icons.person_outline_rounded,
                label: 'Edit Profile',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ),
              ),
              _divider(),
              _Row(
                icon: Icons.lock_outline_rounded,
                label: 'Change Password',
                onTap: () => _showChangePassword(context),
              ),
            ]),
            const SizedBox(height: 20),
            _sectionLabel('Preferences'),
            const SizedBox(height: 8),
            _card([
              _Row(
                icon: Icons.language_rounded,
                label: 'Language',
                trailing: (user?.language?.isNotEmpty ?? false) ? user!.language! : 'English (US)',
                onTap: null,
              ),
            ]),
            const SizedBox(height: 20),
            _sectionLabel('Notifications'),
            const SizedBox(height: 8),
            if (_loadingPrefs)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.brand),
                  ),
                ),
              )
            else
              _card([
                _SwitchRow(
                  icon: Icons.mail_outline_rounded,
                  label: 'Email Notifications',
                  value: prefs.emailNotifications,
                  saving: _savingKey == 'email',
                  onChanged: (v) => _togglePref(
                      'email', v, prefs.copyWith(emailNotifications: v)),
                ),
                _divider(),
                _SwitchRow(
                  icon: Icons.videocam_outlined,
                  label: 'Live Class Reminders',
                  value: prefs.liveClassReminders,
                  saving: _savingKey == 'live',
                  onChanged: (v) => _togglePref(
                      'live', v, prefs.copyWith(liveClassReminders: v)),
                ),
                _divider(),
                _SwitchRow(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Chat Messages',
                  value: prefs.chatMessages,
                  saving: _savingKey == 'chat',
                  onChanged: (v) => _togglePref(
                      'chat', v, prefs.copyWith(chatMessages: v)),
                ),
                _divider(),
                _SwitchRow(
                  icon: Icons.menu_book_outlined,
                  label: 'Course Updates',
                  value: prefs.courseUpdates,
                  saving: _savingKey == 'course',
                  onChanged: (v) => _togglePref(
                      'course', v, prefs.copyWith(courseUpdates: v)),
                ),
              ]),
            const SizedBox(height: 20),
            _sectionLabel('About'),
            const SizedBox(height: 8),
            _card([
              const _Row(icon: Icons.info_outline_rounded, label: 'App Version', trailing: '1.0.0'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
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
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.ink),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Settings',
          style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() => const Divider(height: 1, thickness: 1, color: Color(0xFFF5F3F0), indent: 50);

  void _showChangePassword(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _ChangePasswordSheet(),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback? onTap;

  const _Row({required this.icon, required this.label, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 19, color: AppColors.muted),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.ink),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.muted),
              ),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              const Text('›', style: TextStyle(fontSize: 18, color: AppColors.faint)),
            ],
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final bool saving;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.saving,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 19, color: AppColors.muted),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.ink),
            ),
          ),
          if (saving)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand),
            )
          else
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.brand,
            ),
        ],
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_currentCtrl.text.isEmpty || _newCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill in both password fields.');
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'New passwords don’t match.');
      return;
    }
    if (_newCtrl.text.length < 6) {
      setState(() => _error = 'New password must be at least 6 characters.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final ok = await context.read<AuthProvider>().changePassword(
          currentPassword: _currentCtrl.text,
          newPassword: _newCtrl.text,
        );

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );
    } else {
      setState(() => _error = context.read<AuthProvider>().errorMessage ?? 'Failed to update password.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          Text(
            'Change Password',
            style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 18),
          _field('Current password', _currentCtrl),
          const SizedBox(height: 12),
          _field('New password', _newCtrl),
          const SizedBox(height: 12),
          _field('Confirm new password', _confirmCtrl),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.red)),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _saving ? null : _submit,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: _saving ? AppColors.faint : AppColors.brand,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(
                        'Update Password',
                        style: GoogleFonts.dmSans(
                            fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: true,
      style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.ink),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(fontSize: 13, color: AppColors.muted),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
        ),
      ),
    );
  }
}
