// Public promotional banner shown on student/instructor dashboards,
// configured by an admin (see zinda-learn-backend/server/models/Banner.js).
// Fetched via GET /api/public/banners (no auth required).

class BannerModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String linkUrl;

  BannerModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.linkUrl,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: (json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      linkUrl: (json['linkUrl'] ?? '').toString(),
    );
  }
}
