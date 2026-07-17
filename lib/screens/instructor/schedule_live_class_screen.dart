import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/network/api_exceptions.dart';
import '../../models/course_model.dart';
import '../../models/live_class_model.dart';
import '../../services/instructor_service.dart';
import '../../services/live_class_service.dart';
import '../../theme/app_colors.dart';

/// Schedule a session when [liveClass] is null, Edit session when it's
/// supplied — mirrors the web app's CreateLiveClass/EditLiveClass pages
/// (identical fields/validation, different submit target).
class ScheduleLiveClassScreen extends StatefulWidget {
  final LiveClassModel? liveClass;
  const ScheduleLiveClassScreen({super.key, this.liveClass});

  @override
  State<ScheduleLiveClassScreen> createState() =>
      _ScheduleLiveClassScreenState();
}

class _ScheduleLiveClassScreenState extends State<ScheduleLiveClassScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _meetingLinkCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _thumbnailCtrl;

  List<CourseModel> _courses = [];
  bool _loadingCourses = true;
  String? _courseId;
  DateTime? _date;
  TimeOfDay? _time;
  bool _saving = false;

  bool get _isEdit => widget.liveClass != null;

  @override
  void initState() {
    super.initState();
    final lc = widget.liveClass;
    _titleCtrl = TextEditingController(text: lc?.title ?? '');
    _descCtrl = TextEditingController(text: lc?.description ?? '');
    _meetingLinkCtrl = TextEditingController(text: lc?.meetingLink ?? '');
    _durationCtrl = TextEditingController(
      text: (lc?.duration ?? 60).toString(),
    );
    _thumbnailCtrl = TextEditingController(text: lc?.thumbnail ?? '');
    _courseId = (lc != null && lc.courseId.isNotEmpty) ? lc.courseId : null;

    if (lc != null && lc.scheduledDateStr.isNotEmpty) {
      _date = DateTime.tryParse(lc.scheduledDateStr);
    }
    if (lc != null && lc.startTimeStr.contains(':')) {
      final parts = lc.startTimeStr.split(':');
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) _time = TimeOfDay(hour: h, minute: m);
    }

    _loadCourses();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _meetingLinkCtrl.dispose();
    _durationCtrl.dispose();
    _thumbnailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    try {
      final page = await InstructorService().getMyCourses(limit: 100);
      if (!mounted) return;
      // If the course backing an existing session isn't in this page (e.g.
      // deleted), `_courseId` is kept so submit still round-trips it, but
      // the dropdown just won't show a selection for it.
      setState(() {
        _courses = page.courses;
        _loadingCourses = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCourses = false);
    }
  }

  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.red : AppColors.brand,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  String _dateStr(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _timeStr(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_courseId == null) {
      _showSnack('Please select a course.', error: true);
      return;
    }
    if (_date == null) {
      _showSnack('Please pick a date.', error: true);
      return;
    }
    if (_time == null) {
      _showSnack('Please pick a start time.', error: true);
      return;
    }

    final duration = int.tryParse(_durationCtrl.text.trim()) ?? 0;
    if (duration < 15) {
      _showSnack('Duration must be at least 15 minutes.', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await LiveClassService().updateLiveClass(
          widget.liveClass!.id,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          courseId: _courseId!,
          meetingLink: _meetingLinkCtrl.text.trim(),
          scheduledDate: _dateStr(_date!),
          startTime: _timeStr(_time!),
          duration: duration,
          thumbnail: _thumbnailCtrl.text.trim(),
        );
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
        await LiveClassService().createLiveClass(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          courseId: _courseId!,
          meetingLink: _meetingLinkCtrl.text.trim(),
          scheduledDate: _dateStr(_date!),
          startTime: _timeStr(_time!),
          duration: duration,
          thumbnail: _thumbnailCtrl.text.trim(),
        );
        if (!mounted) return;
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 16,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isEdit ? 'Edit Session' : 'Schedule a Session',
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionCard(
                        title: 'Session Info',
                        children: [
                          _Label('Class title *'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _titleCtrl,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: AppColors.ink,
                            ),
                            decoration: _decoration(
                              'e.g. Week 4 Q&A — React Hooks Deep Dive',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Title is required'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _Label('Course *'),
                          const SizedBox(height: 6),
                          _CourseDropdown(
                            loading: _loadingCourses,
                            courses: _courses,
                            value: _courseId,
                            onChanged: (v) => setState(() => _courseId = v),
                          ),
                          const SizedBox(height: 16),
                          _Label('Description *'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _descCtrl,
                            maxLines: 3,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: AppColors.ink,
                            ),
                            decoration: _decoration(
                              'Topics covered, prerequisites, what to bring…',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Description is required'
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Date & Time',
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _Label('Date *'),
                                    const SizedBox(height: 6),
                                    _PickerField(
                                      icon: Icons.calendar_today_rounded,
                                      label: _date == null
                                          ? 'dd-mm-yyyy'
                                          : _dateStr(_date!),
                                      filled: _date != null,
                                      onTap: _pickDate,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _Label('Start time *'),
                                    const SizedBox(height: 6),
                                    _PickerField(
                                      icon: Icons.access_time_rounded,
                                      label: _time == null
                                          ? '--:--'
                                          : _time!.format(context),
                                      filled: _time != null,
                                      onTap: _pickTime,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _Label('Duration (minutes) *'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _durationCtrl,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: AppColors.ink,
                            ),
                            decoration: _decoration('60'),
                            validator: (v) {
                              final n = int.tryParse((v ?? '').trim());
                              if (n == null) return 'Duration is required';
                              if (n < 15) return 'Minimum 15 minutes';
                              if (n > 360) return 'Maximum 360 minutes';
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Meeting',
                        children: [
                          _Label('Meeting link *'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _meetingLinkCtrl,
                            keyboardType: TextInputType.url,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: AppColors.ink,
                            ),
                            decoration: _decoration(
                              'https://meet.google.com/xxx-yyyy-zzz',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Meeting link is required'
                                : null,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Paste your Zoom, Google Meet, or Microsoft Teams invite link.',
                            style: GoogleFonts.dmSans(
                              fontSize: 11.5,
                              color: AppColors.faint,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _Label('Thumbnail URL'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _thumbnailCtrl,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: AppColors.ink,
                            ),
                            decoration: _decoration(
                              'https://example.com/thumbnail.jpg',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Optional. A cover image makes your session easier to identify.',
                            style: GoogleFonts.dmSans(
                              fontSize: 11.5,
                              color: AppColors.faint,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: OutlinedButton(
                                onPressed: _saving
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: AppColors.border,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.placeholder,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _saving ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.brand,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _saving
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        _isEdit
                                            ? 'Save Changes'
                                            : 'Schedule Session',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.dmSans(fontSize: 13.5, color: AppColors.faint),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.red, width: 1.5),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.dmSans(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: AppColors.muted,
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _PickerField({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.faint),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 13.5,
                  color: filled ? AppColors.ink : AppColors.faint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseDropdown extends StatelessWidget {
  final bool loading;
  final List<CourseModel> courses;
  final String? value;
  final ValueChanged<String?> onChanged;
  const _CourseDropdown({
    required this.loading,
    required this.courses,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Loading your courses…',
              style: GoogleFonts.dmSans(fontSize: 13.5, color: AppColors.faint),
            ),
          ],
        ),
      );
    }

    if (courses.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Text(
          'Create a course first to schedule a live session.',
          style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.faint),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: courses.any((c) => c.id == value) ? value : null,
          isExpanded: true,
          hint: Text(
            'Select a course',
            style: GoogleFonts.dmSans(fontSize: 13.5, color: AppColors.faint),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.faint,
          ),
          style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.ink),
          items: courses
              .map(
                (c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.title, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
