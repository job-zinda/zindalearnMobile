import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/banner_model.dart';

class BannerService {
  final _client = ApiClient.instance;

  /// GET /api/public/banners — active promotional banners, admin-configured.
  Future<List<BannerModel>> getActiveBanners() async {
    final response = await _client.get(ApiConstants.activeBanners);
    final data = response.data as Map<String, dynamic>;
    final raw = (data['data'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((e) => BannerModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
