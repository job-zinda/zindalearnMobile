import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/network/api_exceptions.dart';
import '../../models/course_model.dart';
import '../../providers/instructor_provider.dart';
import '../../services/instructor_service.dart';
import '../../services/upload_service.dart';
import '../../theme/app_colors.dart';

/// Create Course when [course] is null, Edit Info when it's supplied —
/// same form either way, mirroring the web app's CreateCourse/EditCourse
/// pages (identical fields/validation, different submit target).
class CreateEditCourseScreen extends StatefulWidget {
  final CourseModel? course;
  const CreateEditCourseScreen({super.key, this.course});

  @override
  State<CreateEditCourseScreen> createState() => _CreateEditCourseScreenState();
}

class _CreateEditCourseScreenState extends State<CreateEditCourseScreen> {
  static const _categories = [
    MapEntry('development', 'Development'),
    MapEntry('business', 'Business'),
    MapEntry('design', 'Design'),
    MapEntry('marketing', 'Marketing'),
    MapEntry('it', 'IT & Software'),
    MapEntry('finance', 'Finance'),
  ];
  static const _levels = ['Beginner', 'Intermediate', 'Expert', 'All Levels'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _shortDescCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _discountCtrl;

  late String _category;
  late String _level;
  late bool _isFree;
  String? _thumbnailUrl;
  bool _uploadingThumbnail = false;
  String? _previewVideoUrl;
  String? _previewVideoPublicId;
  bool _uploadingVideo = false;
  bool _saving = false;

  bool get _isEdit => widget.course != null;

  @override
  void initState() {
    super.initState();
    final c = widget.course;
    _titleCtrl = TextEditingController(text: c?.title ?? '');
    _descCtrl = TextEditingController(text: c?.description ?? '');
    _shortDescCtrl = TextEditingController(text: c?.shortDescription ?? '');
    _priceCtrl = TextEditingController(text: c != null ? c.price.toStringAsFixed(0) : '99');
    _discountCtrl =
        TextEditingController(text: c != null ? c.discountPrice.toStringAsFixed(0) : '0');
    _category = c?.category ?? 'development';
    _level = _levels.contains(c?.level) ? c!.level : 'Beginner';
    _isFree = c != null ? c.price <= 0 : false;
    _thumbnailUrl = c?.thumbnail;
    _previewVideoUrl = c?.previewVideo;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _shortDescCtrl.dispose();
    _priceCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickThumbnail() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.brand),
              title: Text('Take Photo',
                  style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.ink)),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.brand),
              title: Text('Choose from Gallery',
                  style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.ink)),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked =
        await ImagePicker().pickImage(source: source, maxWidth: 1200, imageQuality: 85);
    if (picked == null || !mounted) return;

    setState(() => _uploadingThumbnail = true);
    try {
      final url = await UploadService().uploadImage(
        File(picked.path),
        folder: 'zinda-learn/courses/thumbnails',
      );
      if (!mounted) return;
      setState(() => _thumbnailUrl = url);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, error: true);
    } finally {
      if (mounted) setState(() => _uploadingThumbnail = false);
    }
  }

  Future<void> _pickVideo() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.videocam_outlined, color: AppColors.brand),
              title: Text('Record Video',
                  style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.ink)),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.video_library_outlined, color: AppColors.brand),
              title: Text('Choose from Gallery',
                  style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.ink)),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await ImagePicker()
        .pickVideo(source: source, maxDuration: const Duration(minutes: 10));
    if (picked == null || !mounted) return;

    final file = File(picked.path);
    const maxBytes = 100 * 1024 * 1024;
    if (await file.length() > maxBytes) {
      if (!mounted) return;
      _showSnack('Video must be 100MB or smaller.', error: true);
      return;
    }

    setState(() => _uploadingVideo = true);
    try {
      final result =
          await UploadService().uploadVideo(file, courseId: widget.course?.id);
      if (!mounted) return;
      setState(() {
        _previewVideoUrl = result.url;
        _previewVideoPublicId = result.publicId;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, error: true);
    } finally {
      if (mounted) setState(() => _uploadingVideo = false);
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final price = num.tryParse(_priceCtrl.text.trim()) ?? 0;
    final discount = num.tryParse(_discountCtrl.text.trim()) ?? 0;

    try {
      if (_isEdit) {
        final updated = await InstructorService().updateCourse(
          widget.course!.id,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          shortDescription: _shortDescCtrl.text.trim(),
          category: _category,
          level: _level,
          price: price,
          discountPrice: discount,
          isFree: _isFree,
          thumbnail: _thumbnailUrl,
          previewVideo: _previewVideoUrl,
          previewVideoPublicId: _previewVideoPublicId,
        );
        if (!mounted) return;
        context.read<InstructorProvider>().replaceCourse(updated);
        _showSnack('Course updated successfully!');
        Navigator.of(context).pop(updated);
      } else {
        final created = await context.read<InstructorProvider>().createCourse(
              title: _titleCtrl.text.trim(),
              description: _descCtrl.text.trim(),
              shortDescription: _shortDescCtrl.text.trim(),
              category: _category,
              level: _level,
              price: price,
              discountPrice: discount,
              isFree: _isFree,
              thumbnail: _thumbnailUrl ?? '',
              previewVideo: _previewVideoUrl ?? '',
              previewVideoPublicId: _previewVideoPublicId ?? '',
            );
        if (!mounted) return;
        _showSnack('Course created successfully!');
        Navigator.of(context).pop(created);
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
                      child: const Icon(Icons.arrow_back_ios_new,
                          size: 16, color: AppColors.ink),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isEdit ? 'Edit Course' : 'Create Course',
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
                        title: 'Course Essentials',
                        children: [
                          _Label('Course Title *'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _titleCtrl,
                            style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.ink),
                            decoration: _decoration('e.g. Advanced Editorial Design'),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                          ),
                          const SizedBox(height: 16),
                          _Label('Full Description *'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _descCtrl,
                            maxLines: 5,
                            style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.ink),
                            decoration: _decoration('Comprehensive details about what students will learn...'),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Description is required'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _Label('Short Description'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _shortDescCtrl,
                            maxLines: 3,
                            maxLength: 300,
                            style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.ink),
                            decoration: _decoration('A brief hook that summarizes your course...'),
                          ),
                          const SizedBox(height: 8),
                          _Label('Category *'),
                          const SizedBox(height: 6),
                          _CategoryDropdown(
                            value: _category,
                            items: _categories,
                            onChanged: (v) => setState(() => _category = v),
                          ),
                          const SizedBox(height: 16),
                          _Label('Difficulty Level'),
                          const SizedBox(height: 6),
                          _LevelChips(
                            levels: _levels,
                            value: _level,
                            onChanged: (v) => setState(() => _level = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Media & Branding',
                        children: [
                          _Label('Course Thumbnail'),
                          const SizedBox(height: 6),
                          _ThumbnailPicker(
                            url: _thumbnailUrl,
                            uploading: _uploadingThumbnail,
                            onTap: _pickThumbnail,
                          ),
                          const SizedBox(height: 16),
                          _Label('Promo Video'),
                          const SizedBox(height: 6),
                          _VideoPicker(
                            hasVideo: _previewVideoUrl != null && _previewVideoUrl!.isNotEmpty,
                            uploading: _uploadingVideo,
                            onTap: _pickVideo,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Pricing & Access',
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _Label('Currency'),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: AppColors.bg,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                            color: AppColors.border, width: 1.5),
                                      ),
                                      child: Text('INR (₹)',
                                          style: GoogleFonts.dmSans(
                                              fontSize: 14, color: AppColors.muted)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _Label('Price Amount'),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _priceCtrl,
                                      enabled: !_isFree,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(),
                                      style: GoogleFonts.dmSans(
                                          fontSize: 14, color: AppColors.ink),
                                      decoration: _decoration('99'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _Label('Discount Price'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _discountCtrl,
                            enabled: !_isFree,
                            keyboardType: const TextInputType.numberWithOptions(),
                            style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.ink),
                            decoration: _decoration('Optional'),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => setState(() => _isFree = !_isFree),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _isFree,
                                  activeColor: AppColors.brand,
                                  onChanged: (v) => setState(() => _isFree = v ?? false),
                                ),
                                Text('Free Course',
                                    style: GoogleFonts.dmSans(
                                        fontSize: 14, color: AppColors.ink)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brand,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(Colors.white)),
                                )
                              : Text(
                                  _isEdit ? 'Save Changes' : 'Create & Continue',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                        ),
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

class _CategoryDropdown extends StatelessWidget {
  final String value;
  final List<MapEntry<String, String>> items;
  final ValueChanged<String> onChanged;
  const _CategoryDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.faint),
          style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.ink),
          items: items
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _LevelChips extends StatelessWidget {
  final List<String> levels;
  final String value;
  final ValueChanged<String> onChanged;
  const _LevelChips({required this.levels, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: levels.map((level) {
        final selected = value == level;
        return GestureDetector(
          onTap: () => onChanged(level),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? AppColors.brandFaint : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? AppColors.brand : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Text(
              level,
              style: GoogleFonts.dmSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.brand : AppColors.muted,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ThumbnailPicker extends StatelessWidget {
  final String? url;
  final bool uploading;
  final VoidCallback onTap;
  const _ThumbnailPicker({required this.url, required this.uploading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasImage = url != null && url!.isNotEmpty;
    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: Container(
        height: 140,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.border,
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: uploading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.brand))
            : hasImage
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(url!, fit: BoxFit.cover),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit_rounded,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image_outlined, size: 28, color: AppColors.faint),
                      const SizedBox(height: 6),
                      Text(
                        'Tap to add a thumbnail',
                        style: GoogleFonts.dmSans(fontSize: 12.5, color: AppColors.muted),
                      ),
                      Text(
                        'JPG, PNG or WEBP',
                        style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.faint),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _VideoPicker extends StatelessWidget {
  final bool hasVideo;
  final bool uploading;
  final VoidCallback onTap;
  const _VideoPicker({
    required this.hasVideo,
    required this.uploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: Container(
        height: 140,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: uploading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.brand))
            : hasVideo
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      const ColoredBox(color: AppColors.brandDark),
                      const Center(
                        child: Icon(Icons.play_circle_fill_rounded,
                            size: 40, color: Colors.white70),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          color: Colors.black45,
                          alignment: Alignment.center,
                          child: Text(
                            'Video uploaded',
                            style: GoogleFonts.dmSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit_rounded,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_outlined, size: 28, color: AppColors.faint),
                      const SizedBox(height: 6),
                      Text(
                        'Tap to add a promo video',
                        style: GoogleFonts.dmSans(fontSize: 12.5, color: AppColors.muted),
                      ),
                      Text(
                        'MP4 or MOV, max 100MB',
                        style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.faint),
                      ),
                    ],
                  ),
      ),
    );
  }
}
