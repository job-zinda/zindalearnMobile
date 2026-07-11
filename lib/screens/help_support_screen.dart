import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/network/api_exceptions.dart';
import '../core/utils/formatters.dart';
import '../models/support_ticket_model.dart';
import '../services/support_service.dart';
import '../theme/app_colors.dart';

/// Help & Support. FAQs are static copy; tickets are backed by
/// /api/support/tickets (see zinda-learn-backend/server/controllers/
/// support.controller.js).
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _service = SupportService();
  int? _expanded;
  List<SupportTicketModel> _tickets = [];
  bool _loadingTickets = true;

  static const _faqs = [
    ('How do I enroll in a course?', 'Open the course from Browse Courses and tap Enroll. Free courses unlock instantly; paid courses go through checkout.'),
    ('Can I get a refund?', 'Reach out via Contact Support below within 7 days of purchase and we’ll take a look at your case.'),
    ('How do I message my instructor?', 'Go to the Messages tab, tap the + button, and pick the instructor from any course you’re enrolled in.'),
    ('Where do I find my certificate?', 'Certificates appear under Certificates in the menu once you complete a course.'),
  ];

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    setState(() => _loadingTickets = true);
    try {
      final tickets = await _service.getMyTickets();
      if (!mounted) return;
      setState(() {
        _tickets = tickets;
        _loadingTickets = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingTickets = false);
    }
  }

  void _openTicketForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _NewTicketSheet(
        service: _service,
        onSubmitted: _fetchTickets,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.brand,
          onRefresh: _fetchTickets,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            children: [
              _header(context),
              const SizedBox(height: 18),
              _contactCard(),
              const SizedBox(height: 22),
              _ticketsSection(),
              const SizedBox(height: 22),
              Text(
                'Frequently Asked Questions',
                style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
              const SizedBox(height: 10),
              ..._faqs.asMap().entries.map((e) => _FaqTile(
                    question: e.value.$1,
                    answer: e.value.$2,
                    expanded: _expanded == e.key,
                    onTap: () => setState(() => _expanded = _expanded == e.key ? null : e.key),
                  )),
            ],
          ),
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
          'Help & Support',
          style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
      ],
    );
  }

  Widget _contactCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6D28D9), Color(0xFF4C1D95)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.support_agent_rounded, color: Colors.white, size: 28),
          const SizedBox(height: 12),
          Text(
            'Still need help?',
            style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Our support team usually replies within a day.',
            style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _openTicketForm,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Text(
                'Contact Support',
                style: GoogleFonts.dmSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.brand),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ticketsSection() {
    if (_loadingTickets) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.brand),
          ),
        ),
      );
    }

    if (_tickets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Tickets',
          style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        const SizedBox(height: 10),
        ..._tickets.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TicketTile(ticket: t),
            )),
      ],
    );
  }
}

class _TicketTile extends StatelessWidget {
  final SupportTicketModel ticket;
  const _TicketTile({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusBg) = switch (ticket.status) {
      'resolved' => (const Color(0xFF059669), const Color(0xFFD1FAE5)),
      'closed' => (AppColors.faint, const Color(0xFFF0EFEA)),
      'pending' => (const Color(0xFFD97706), const Color(0xFFFEF3C7)),
      _ => (AppColors.brand, AppColors.brandFaint),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                const SizedBox(height: 3),
                Text(
                  '${ticket.category} · ${Formatters.chatTimestamp(ticket.createdAt)}',
                  style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(7)),
            child: Text(
              ticket.status.toUpperCase(),
              style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;
  final bool expanded;
  final VoidCallback onTap;

  const _FaqTile({
    required this.question,
    required this.answer,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      question,
                      style: GoogleFonts.dmSans(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink),
                    ),
                  ),
                  Icon(
                    expanded ? Icons.remove_rounded : Icons.add_rounded,
                    size: 20,
                    color: AppColors.brand,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  answer,
                  style: GoogleFonts.dmSans(fontSize: 13, height: 1.5, color: AppColors.muted),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NewTicketSheet extends StatefulWidget {
  final SupportService service;
  final VoidCallback onSubmitted;

  const _NewTicketSheet({required this.service, required this.onSubmitted});

  @override
  State<_NewTicketSheet> createState() => _NewTicketSheetState();
}

class _NewTicketSheetState extends State<_NewTicketSheet> {
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _category = 'Technical Issues';
  bool _saving = false;
  String? _error;

  static const _categories = ['Technical Issues', 'Payments', 'Other'];

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_subjectCtrl.text.trim().isEmpty || _messageCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in both subject and message.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.service.createTicket(
        subject: _subjectCtrl.text.trim(),
        category: _category,
        message: _messageCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSubmitted();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Support ticket submitted. We’ll get back to you soon.')),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Failed to submit ticket. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
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
            'Contact Support',
            style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 18),
          _textField('Subject', _subjectCtrl),
          const SizedBox(height: 12),
          _categoryPicker(),
          const SizedBox(height: 12),
          _textField('Describe your issue', _messageCtrl, maxLines: 4),
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
                        'Submit Ticket',
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

  Widget _categoryPicker() {
    return Wrap(
      spacing: 8,
      children: _categories.map((c) {
        final active = _category == c;
        return GestureDetector(
          onTap: () => setState(() => _category = c),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: active ? AppColors.brand : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: active ? AppColors.brand : AppColors.border, width: 1.5),
            ),
            child: Text(
              c,
              style: GoogleFonts.dmSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.ink,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _textField(String label, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
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
