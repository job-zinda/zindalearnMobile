import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/certificate_model.dart';

class CertificateService {
  final _client = ApiClient.instance;

  /// GET /api/student/certificates/stats
  Future<CertificateStats> getStats() async {
    final response = await _client.get(ApiConstants.certificateStats);
    final data = response.data as Map<String, dynamic>;
    return CertificateStats.fromJson(Map<String, dynamic>.from(data['data']));
  }

  /// GET /api/student/certificates — all earned certificates.
  Future<List<CertificateModel>> getCertificates() async {
    final response = await _client.get(ApiConstants.certificates);
    final data = response.data as Map<String, dynamic>;
    final raw = (data['data'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((c) => CertificateModel.fromJson(Map<String, dynamic>.from(c)))
        .toList();
  }
}
