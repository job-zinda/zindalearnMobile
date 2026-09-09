import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/utils/formatters.dart';
import '../../models/course_model.dart';
import '../../providers/instructor_provider.dart';
import '../../services/course_service.dart';
import '../../services/instructor_service.dart';
import '../../services/upload_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/course_status_style.dart';
import 'create_edit_course_screen.dart';

/// "Manage Course" — mirrors the web app's CourseDetail page: status pills,
/// Submit for Review, Edit Info, and a basic Content tab (add/delete
/// sections & lessons only; richer curriculum editing stays web-only).
class InstructorCourseDetailScreen extends StatefulWidget {
  final String courseId;
  const InstructorCourseDetailScreen({super.key, required this.courseId});

  @override
  State<InstructorCourseDetailScreen> createState() =>
      _InstructorCourseDetailScreenState();
}

class _InstructorCourseDetailScreenState
    extends State<InstructorCourseDetailScreen> {
  final _courseService = CourseService();
  final _instructorService = InstructorService();

  CourseModel? _course;
  String? _error;
  bool _submitting = false;
  bool _mutating = false;
  final Set<String> _expandedSections = {};

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final course = await _courseService.getCourse(widget.courseId);
      if (!mounted) return;
      setState(() {
        _course = course;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Unable to load this course.');
    }
  }

  void _applyUpdatedCourse(CourseModel updated) {
    if (!mounted) return;
    setState(() => _course = updated);
    context.read<InstructorProvider>().replaceCourse(updated);
  }

  Future<void> _submitForReview() async {
    setState(() => _submitting = true);
    try {
      final updated = await _instructorService.submitForReview(widget.courseId);
      _applyUpdatedCourse(updated);
      if (!mounted) return;
      _showSnack('Course submitted for admin review!');
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
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

  Future<void> _editInfo() async {
    final updated = await Navigator.of(context).push<CourseModel>(
      MaterialPageRoute(
        builder: (_) => CreateEditCourseScreen(course: _course),
      ),
    );
    if (updated != null) _applyUpdatedCourse(updated);
  }

  Future<void> _addSection() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _SectionDialog(),
    );
    if (result == null) return;

    setState(() => _mutating = true);
    try {
      final updated = await _instructorService.addSection(
        widget.courseId,
        title: result['title']!,
        description: result['description'] ?? '',
      );
      _applyUpdatedCourse(updated);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, error: true);
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _deleteSection(String sectionId) async {
    final confirmed = await _confirm(
      'Delete this section?',
      'This will remove the section and all its lessons. This cannot be undone.',
    );
    if (confirmed != true) return;

    setState(() => _mutating = true);
    try {
      final updated =
          await _instructorService.deleteSection(widget.courseId, sectionId);
      _applyUpdatedCourse(updated);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, error: true);
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _addLesson(String sectionId) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _LessonDialog(courseId: widget.courseId),
    );
    if (result == null) return;

    setState(() => _mutating = true);
    try {
      final updated = await _instructorService.addLesson(
        widget.courseId,
        sectionId,
        title: result['title'] as String,
        videoUrl: result['videoUrl'] as String? ?? '',
        source: result['source'] as String? ?? '',
        bunnyVideoId: result['bunnyVideoId'] as String? ?? '',
        hlsUrl: result['hlsUrl'] as String? ?? '',
        duration: result['duration'] as int? ?? 0,
        isFree: result['isFree'] as bool? ?? false,
      );
      _applyUpdatedCourse(updated);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, error: true);
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _deleteLesson(String sectionId, String lessonId) async {
    final confirmed =
        await _confirm('Delete this lesson?', 'This cannot be undone.');
    if (confirmed != true) return;

    setState(() => _mutating = true);
    try {
      final updated = await _instructorService.deleteLesson(
          widget.courseId, sectionId, lessonId);
      _applyUpdatedCourse(updated);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, error: true);
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<bool?> _confirm(String title, String body) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final course = _course;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _appBar(course),
            Expanded(
              child: course == null
                  ? (_error != null
                      ? _errorView()
                      : const Center(
                          child: CircularProgressIndicator(color: AppColors.brand)))
                  : _content(course),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appBar(CourseModel? course) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
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
          Expanded(
            child: Text(
              course?.title ?? 'Manage Course',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 15, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _fetch,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  borderRadius: BorderRadius.circular(11),
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

  Widget _content(CourseModel course) {
    final canSubmit = course.status == 'draft' || course.status == 'declined';

    return RefreshIndicator(
      color: AppColors.brand,
      onRefresh: _fetch,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
        children: [
          Text(
            'Course Management & Curriculum',
            style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          _StatusRow(current: course.status),
          const SizedBox(height: 14),

          if (course.status == 'declined' &&
              (course.declineReason ?? '').isNotEmpty) ...[
            _DeclineBanner(reason: course.declineReason!),
            const SizedBox(height: 14),
          ],

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: (canSubmit && !_submitting) ? _submitForReview : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canSubmit ? AppColors.brand : AppColors.border,
                      foregroundColor: canSubmit ? Colors.white : AppColors.muted,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                          )
                        : Text(
                            canSubmit ? 'Submit for Review' : 'In Review',
                            style: GoogleFonts.dmSans(
                                fontSize: 13.5, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 46,
                child: OutlinedButton(
                  onPressed: _editInfo,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, size: 16, color: AppColors.ink),
                      const SizedBox(width: 6),
                      Text('Edit Info',
                          style: GoogleFonts.dmSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Course Modules',
                style: GoogleFonts.dmSans(
                    fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandFaint,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${course.modules.length} Sections',
                  style: GoogleFonts.dmSans(
                      fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.brand),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (course.modules.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Column(
                children: [
                  const Icon(Icons.play_circle_outline_rounded,
                      size: 34, color: AppColors.faint),
                  const SizedBox(height: 10),
                  Text('Build your curriculum',
                      style: GoogleFonts.dmSans(
                          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 4),
                  Text(
                    'Start by adding your first section and uploading your lessons.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(fontSize: 12.5, color: AppColors.muted),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                for (final section in course.modules) ...[
                  _SectionTile(
                    section: section,
                    expanded: _expandedSections.contains(section.id),
                    onToggle: () => setState(() {
                      if (!_expandedSections.add(section.id)) {
                        _expandedSections.remove(section.id);
                      }
                    }),
                    onDelete: _mutating ? null : () => _deleteSection(section.id),
                    onAddLesson: _mutating ? null : () => _addLesson(section.id),
                    onDeleteLesson: (lessonId) =>
                        _mutating ? null : _deleteLesson(section.id, lessonId),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _mutating ? null : _addSection,
              icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.brand),
              label: Text(
                course.modules.isEmpty ? 'Add First Section' : 'Add New Section',
                style: GoogleFonts.dmSans(
                    fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.brand),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.brand, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String current;
  const _StatusRow({required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final status in CourseStatusStyle.workflowOrder) ...[
          Expanded(child: _StatusPill(status: status, active: current == status)),
          if (status != CourseStatusStyle.workflowOrder.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  final bool active;
  const _StatusPill({required this.status, required this.active});

  @override
  Widget build(BuildContext context) {
    final style = CourseStatusStyle.of(status);
    return Opacity(
      opacity: active ? 1 : 0.4,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? style.background : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? style.color : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            if (style.icon != null)
              Icon(style.icon, size: 14, color: active ? style.color : AppColors.faint),
            const SizedBox(height: 2),
            Text(
              status,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: active ? style.color : AppColors.faint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeclineBanner extends StatelessWidget {
  final String reason;
  const _DeclineBanner({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDA4AF), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_rounded, size: 18, color: Color(0xFFBE123C)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Course Declined by Admin',
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFBE123C))),
                const SizedBox(height: 3),
                Text('Reason: "$reason"',
                    style: GoogleFonts.dmSans(
                        fontSize: 12.5, color: const Color(0xFFBE123C), height: 1.4)),
                const SizedBox(height: 3),
                Text('Fix the issue above and submit again for review.',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: const Color(0xFFBE123C).withValues(alpha: 0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  final Module section;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onAddLesson;
  final ValueChanged<String>? onDeleteLesson;

  const _SectionTile({
    required this.section,
    required this.expanded,
    required this.onToggle,
    required this.onDelete,
    required this.onAddLesson,
    required this.onDeleteLesson,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(expanded ? Icons.expand_more_rounded : Icons.chevron_right_rounded,
                      color: AppColors.muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(section.title,
                            style: GoogleFonts.dmSans(
                                fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                        Text('${section.lessons.length} lessons',
                            style:
                                GoogleFonts.dmSans(fontSize: 11.5, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onDelete,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.delete_outline_rounded,
                          size: 18, color: AppColors.faint),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1, color: AppColors.border),
            for (final lesson in section.lessons)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 0),
                child: Row(
                  children: [
                    Icon(
                      lesson.isFree
                          ? Icons.play_circle_outline_rounded
                          : Icons.lock_outline_rounded,
                      size: 16,
                      color: AppColors.faint,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        lesson.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.ink),
                      ),
                    ),
                    if (lesson.duration > 0)
                      Text(
                        Formatters.duration(lesson.duration),
                        style: GoogleFonts.dmSans(fontSize: 11.5, color: AppColors.muted),
                      ),
                    IconButton(
                      onPressed: () => onDeleteLesson?.call(lesson.id),
                      icon: const Icon(Icons.close_rounded,
                          size: 16, color: AppColors.faint),
                      splashRadius: 16,
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 12),
              child: TextButton.icon(
                onPressed: onAddLesson,
                icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.brand),
                label: Text('Add Lesson',
                    style: GoogleFonts.dmSans(
                        fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.brand)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionDialog extends StatefulWidget {
  const _SectionDialog();

  @override
  State<_SectionDialog> createState() => _SectionDialogState();
}

class _SectionDialogState extends State<_SectionDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Section'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Section title *'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            if (_titleCtrl.text.trim().isEmpty) return;
            Navigator.of(context).pop({
              'title': _titleCtrl.text.trim(),
              'description': _descCtrl.text.trim(),
            });
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _LessonDialog extends StatefulWidget {
  final String courseId;
  const _LessonDialog({required this.courseId});

  @override
  State<_LessonDialog> createState() => _LessonDialogState();
}

class _LessonDialogState extends State<_LessonDialog> {
  final _titleCtrl = TextEditingController();
  final _videoCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  String _source = 'bunny';
  String _bunnyVideoId = '';
  String _hlsUrl = '';
  bool _isFree = false;
  bool _uploading = false;
  String? _uploadStatusText;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _videoCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    final file = File(picked.path);
    final fileName = picked.name;

    setState(() {
      _uploading = true;
      _uploadStatusText = 'Uploading to Bunny.net...';
      if (_titleCtrl.text.trim().isEmpty) {
        _titleCtrl.text = fileName.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
      }
    });

    try {
      final result = await UploadService().uploadVideo(
        file,
        courseId: widget.courseId,
        title: _titleCtrl.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _videoCtrl.text = result.url;
        _source = result.source;
        _bunnyVideoId = result.bunnyVideoId ?? '';
        _hlsUrl = result.hlsUrl ?? '';
        if (result.duration > 0) {
          _durationCtrl.text = (result.duration / 60).ceil().toString();
        }
        _uploadStatusText = 'Uploaded to Bunny.net Stream!';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: AppColors.red,
        ),
      );
      setState(() => _uploadStatusText = null);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Lesson'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Lesson title *',
                hintText: 'e.g. Introduction to React',
              ),
            ),
            const SizedBox(height: 14),

            // Video Upload Section
            Text(
              'Lesson Video',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            if (_uploading)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.brand.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.brand,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _uploadStatusText ?? 'Uploading...',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppColors.brand,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              GestureDetector(
                onTap: _pickAndUploadVideo,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(
                    color: _videoCtrl.text.isNotEmpty
                        ? const Color(0xFFF0FDF4)
                        : AppColors.brand.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _videoCtrl.text.isNotEmpty
                          ? const Color(0xFF86EFAC)
                          : AppColors.brand.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _videoCtrl.text.isNotEmpty
                            ? Icons.check_circle_outline_rounded
                            : Icons.video_library_rounded,
                        size: 18,
                        color: _videoCtrl.text.isNotEmpty
                            ? const Color(0xFF16A34A)
                            : AppColors.brand,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _videoCtrl.text.isNotEmpty
                            ? 'Video Attached (Tap to change)'
                            : 'Pick & Upload Video File',
                        style: GoogleFonts.dmSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _videoCtrl.text.isNotEmpty
                              ? const Color(0xFF16A34A)
                              : AppColors.brand,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),
            TextField(
              controller: _videoCtrl,
              decoration: const InputDecoration(
                labelText: 'Video URL (auto-filled on upload)',
                hintText: 'https://...',
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _source,
              decoration: const InputDecoration(labelText: 'Source'),
              items: const [
                DropdownMenuItem(value: 'bunny', child: Text('Bunny.net Stream')),
                DropdownMenuItem(value: 'upload', child: Text('Cloudinary')),
                DropdownMenuItem(value: 'youtube', child: Text('YouTube')),
                DropdownMenuItem(value: '', child: Text('None / Text-only')),
              ],
              onChanged: (v) => setState(() => _source = v ?? ''),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _durationCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Duration (minutes)'),
            ),
            const SizedBox(height: 4),
            CheckboxListTile(
              value: _isFree,
              onChanged: (v) => setState(() => _isFree = v ?? false),
              title: const Text('Available as free preview'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _uploading
              ? null
              : () {
                  if (_titleCtrl.text.trim().isEmpty) return;
                  Navigator.of(context).pop({
                    'title': _titleCtrl.text.trim(),
                    'videoUrl': _videoCtrl.text.trim(),
                    'source': _source,
                    'bunnyVideoId': _bunnyVideoId,
                    'hlsUrl': _hlsUrl,
                    'duration': int.tryParse(_durationCtrl.text.trim()) ?? 0,
                    'isFree': _isFree,
                  });
                },
          child: const Text('Add Lesson'),
        ),
      ],
    );
  }
}
