// Models for the course catalog, mapped to the backend `Course` schema
// (see zinda-learn-backend/server/models/Course.js).

class Instructor {
  final String id;
  final String name;
  final String? avatar;
  final String? bio;

  Instructor({
    required this.id,
    required this.name,
    this.avatar,
    this.bio,
  });

  factory Instructor.fromJson(dynamic json) {
    if (json is! Map) {
      return Instructor(id: json?.toString() ?? '', name: 'Instructor');
    }
    return Instructor(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: (json['name'] ?? 'Instructor').toString(),
      avatar: json['avatar']?.toString(),
      bio: json['bio']?.toString(),
    );
  }

  String get initial =>
      name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
}

class Lesson {
  final String id;
  final String title;
  final String? description;
  final int duration; // minutes
  final bool isFree;
  final String videoUrl;

  Lesson({
    required this.id,
    required this.title,
    this.description,
    this.duration = 0,
    this.isFree = false,
    this.videoUrl = '',
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: (json['title'] ?? 'Lesson').toString(),
      description: json['description']?.toString(),
      duration: _toInt(json['duration']),
      isFree: json['isFree'] == true,
      videoUrl: (json['videoUrl'] ?? '').toString(),
    );
  }
}

class Module {
  final String id;
  final String title;
  final String? description;
  final List<Lesson> lessons;

  Module({
    required this.id,
    required this.title,
    this.description,
    this.lessons = const [],
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    final rawLessons = json['lessons'];
    return Module(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: (json['title'] ?? 'Section').toString(),
      description: json['description']?.toString(),
      lessons: rawLessons is List
          ? rawLessons
              .whereType<Map>()
              .map((l) => Lesson.fromJson(Map<String, dynamic>.from(l)))
              .toList()
          : const [],
    );
  }
}

class CourseModel {
  final String id;
  final String title;
  final String description;
  final String? shortDescription;
  final double price;
  final double discountPrice;
  final String currency;
  final String? thumbnail;
  final String? previewVideo;
  final Instructor instructor;
  final String category;
  final String level;
  final String language;
  final List<String> tags;
  final List<String> whatYouWillLearn;
  final List<String> requirements;
  final List<Module> modules;
  final int totalStudents;
  final double rating;
  final int totalRatings;
  final int totalLessons;
  final int totalDuration; // minutes
  final bool enrolled;

  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    this.shortDescription,
    this.price = 0,
    this.discountPrice = 0,
    this.currency = 'INR',
    this.thumbnail,
    this.previewVideo,
    required this.instructor,
    this.category = 'development',
    this.level = 'All Levels',
    this.language = 'English',
    this.tags = const [],
    this.whatYouWillLearn = const [],
    this.requirements = const [],
    this.modules = const [],
    this.totalStudents = 0,
    this.rating = 0,
    this.totalRatings = 0,
    this.totalLessons = 0,
    this.totalDuration = 0,
    this.enrolled = false,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    final rawModules = json['modules'];
    final modules = rawModules is List
        ? rawModules
            .whereType<Map>()
            .map((m) => Module.fromJson(Map<String, dynamic>.from(m)))
            .toList()
        : <Module>[];

    // `totalLessons` / `totalDuration` are virtuals from the API, but fall back
    // to computing them from modules if they are missing.
    final lessonCount = json['totalLessons'] != null
        ? _toInt(json['totalLessons'])
        : modules.fold<int>(0, (a, m) => a + m.lessons.length);
    final durationTotal = json['totalDuration'] != null
        ? _toInt(json['totalDuration'])
        : modules.fold<int>(
            0, (a, m) => a + m.lessons.fold<int>(0, (b, l) => b + l.duration));

    return CourseModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: (json['title'] ?? 'Untitled Course').toString(),
      description: (json['description'] ?? '').toString(),
      shortDescription: json['shortDescription']?.toString(),
      price: _toDouble(json['price']),
      discountPrice: _toDouble(json['discountPrice']),
      currency: (json['currency'] ?? 'INR').toString(),
      thumbnail: _cleanUrl(json['thumbnail']),
      previewVideo: _cleanUrl(json['previewVideo']),
      instructor: Instructor.fromJson(json['instructor']),
      category: (json['category'] ?? 'development').toString(),
      level: (json['level'] ?? 'All Levels').toString(),
      language: (json['language'] ?? 'English').toString(),
      tags: _toStringList(json['tags']),
      whatYouWillLearn: _toStringList(json['whatYouWillLearn']),
      requirements: _toStringList(json['requirements']),
      modules: modules,
      totalStudents: _toInt(json['totalStudents']),
      rating: _toDouble(json['rating']),
      totalRatings: _toInt(json['totalRatings']),
      totalLessons: lessonCount,
      totalDuration: durationTotal,
      enrolled: json['enrolled'] == true,
    );
  }

  /// Effective price the learner pays.
  double get effectivePrice =>
      discountPrice > 0 && discountPrice < price ? discountPrice : price;

  bool get isFree => effectivePrice <= 0;

  bool get hasDiscount => discountPrice > 0 && discountPrice < price;

  int get discountPercent =>
      hasDiscount ? (((price - discountPrice) / price) * 100).round() : 0;
}

// -------- parsing helpers --------

int _toInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.round();
  if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.round() ?? 0;
  return 0;
}

double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

List<String> _toStringList(dynamic v) {
  if (v is List) return v.map((e) => e.toString()).toList();
  return const [];
}

String? _cleanUrl(dynamic v) {
  final s = v?.toString().trim();
  if (s == null || s.isEmpty) return null;
  return s;
}
