import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/network/api_exceptions.dart';
import '../core/utils/formatters.dart';
import '../models/certificate_model.dart';
import '../services/certificate_service.dart';
import '../theme/app_colors.dart';

/// Certificates, backed by GET /api/student/certificates(/stats) (see
/// zinda-learn-backend/server/controllers/certificate.controller.js).
class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  final _service = CertificateService();
  CertificateStats? _stats;
  List<CertificateModel> _certificates = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.getStats(),
        _service.getCertificates(),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as CertificateStats;
        _certificates = results[1] as List<CertificateModel>;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load your certificates. Please try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.brand,
          onRefresh: _fetch,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            children: [
              _header(context),
              const SizedBox(height: 18),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator(color: AppColors.brand)),
                )
              else if (_error != null)
                _errorState()
              else ...[
                _statsGrid(_stats ?? CertificateStats()),
                const SizedBox(height: 22),
                Text(
                  _certificates.isEmpty ? 'Featured Achievement' : 'Your Certificates',
                  style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
                const SizedBox(height: 10),
                if (_certificates.isEmpty)
                  _featuredEmptyCard()
                else
                  ..._certificates.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CertificateCard(certificate: c),
                      )),
              ],
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Certificates',
                style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
              Text(
                'Showcase your skills to the world.',
                style: GoogleFonts.dmSans(fontSize: 12.5, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _errorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 13.5, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _fetch,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(12)),
              child: Text('Retry',
                  style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsGrid(CertificateStats stats) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.workspace_premium_rounded,
            iconColor: AppColors.brand,
            iconBg: AppColors.brandFaint,
            value: '${stats.certificatesEarned}',
            label: 'Earned',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_rounded,
            iconColor: const Color(0xFF059669),
            iconBg: const Color(0xFFD1FAE5),
            value: '${stats.coursesCompleted}',
            label: 'Completed',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.star_rounded,
            iconColor: const Color(0xFFD97706),
            iconBg: const Color(0xFFFEF3C7),
            value: '${stats.skillsAcquired}',
            label: 'Skills',
          ),
        ),
      ],
    );
  }

  Widget _featuredEmptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderMuted, width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF0EFEA)),
            child: const Icon(Icons.workspace_premium_outlined, size: 30, color: AppColors.faint),
          ),
          const SizedBox(height: 16),
          Text(
            'Your featured achievement will appear here once\nyou complete a course.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 13.5, height: 1.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(shape: BoxShape.circle, color: iconBg),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(fontSize: 10.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  final CertificateModel certificate;
  const _CertificateCard({required this.certificate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.brandFaint),
            child: const Icon(Icons.workspace_premium_rounded, color: AppColors.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  certificate.courseTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  'Issued ${Formatters.chatTimestamp(certificate.issueDate)} · ${certificate.instructorName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
