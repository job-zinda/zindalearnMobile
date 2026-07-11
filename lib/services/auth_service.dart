import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/api_response.dart';
import '../models/user_model.dart';

class AuthService {
  final _client = ApiClient.instance;

  /// POST /api/auth/register
  Future<ApiResponse<Map<String, dynamic>>> register({
    required String name,
    required String email,
    required String password,
    String role = 'student',
  }) async {
    final response = await _client.post(
      ApiConstants.register,
      data: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      },
    );
    return _authResponse(response.data);
  }

  /// POST /api/auth/login
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
    return _authResponse(response.data);
  }

  /// POST /api/auth/google-login
  Future<ApiResponse<Map<String, dynamic>>> googleLogin({
    required String token,
    required String email,
    String? name,
    String? photo,
  }) async {
    final response = await _client.post(
      ApiConstants.googleLogin,
      data: {
        'token': token,
        'email': email,
        'name': name,
        'photo': photo,
      },
    );
    return _authResponse(response.data);
  }

  /// The backend returns `token`/`user` at the JSON root for every auth
  /// endpoint (never nested under a `data` key), so build the ApiResponse
  /// manually instead of the generic `ApiResponse.fromJson`, which only
  /// looks for `json['data']` and would otherwise always come back null.
  ApiResponse<Map<String, dynamic>> _authResponse(dynamic rawData) {
    final json = rawData as Map<String, dynamic>;
    return ApiResponse(
      success: json['success'] ?? false,
      message: (json['message'] ?? '').toString(),
      data: {
        'token': json['token'],
        'user': json['user'],
      },
    );
  }

  /// POST /api/auth/send-otp
  Future<ApiResponse> sendOtp({required String email}) async {
    final response = await _client.post(
      ApiConstants.sendOtp,
      data: {'email': email},
    );
    return ApiResponse.fromJson(response.data);
  }

  /// POST /api/auth/verify-otp
  Future<ApiResponse<Map<String, dynamic>>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _client.post(
      ApiConstants.verifyOtp,
      data: {'email': email, 'otp': otp},
    );
    return ApiResponse.fromJson(response.data);
  }

  /// GET /api/auth/me
  Future<ApiResponse<UserModel>> getMe() async {
    final response = await _client.get(ApiConstants.me);
    return _userResponse(response.data);
  }

  /// PUT /api/student/settings/profile
  ///
  /// Field rules enforced by the backend:
  /// - name, username, phone, language: applied only if truthy.
  /// - email: applied if changed; server checks for duplicates and resets
  ///   `emailVerified` to false on change.
  /// - bio, avatar: applied whenever the key is present, even as ''.
  Future<ApiResponse<UserModel>> updateProfile({
    String? name,
    String? email,
    String? bio,
    String? username,
    String? phone,
    String? language,
    String? avatar,
  }) async {
    final body = <String, dynamic>{};
    if (name != null && name.isNotEmpty) body['name'] = name;
    if (email != null && email.isNotEmpty) body['email'] = email;
    if (bio != null) body['bio'] = bio;
    if (username != null && username.isNotEmpty) body['username'] = username;
    if (phone != null && phone.isNotEmpty) body['phone'] = phone;
    if (language != null && language.isNotEmpty) body['language'] = language;
    if (avatar != null) body['avatar'] = avatar;

    final response = await _client.put(ApiConstants.updateProfile, data: body);
    // This endpoint wraps its payload under `data` (unlike the other auth
    // endpoints above), so the generic ApiResponse parsing applies as-is.
    return ApiResponse.fromJson(
      response.data,
      fromJsonT: (data) => UserModel.fromJson(Map<String, dynamic>.from(data)),
    );
  }

  /// Backend returns `{ success, user }` at the JSON root (no `data` key).
  ApiResponse<UserModel> _userResponse(dynamic rawData) {
    final json = rawData as Map<String, dynamic>;
    return ApiResponse(
      success: json['success'] ?? false,
      message: (json['message'] ?? '').toString(),
      data: json['user'] != null
          ? UserModel.fromJson(Map<String, dynamic>.from(json['user']))
          : null,
    );
  }

  /// PUT /api/auth/password
  Future<ApiResponse> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _client.put(
      ApiConstants.changePassword,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
    return ApiResponse.fromJson(response.data);
  }

  /// POST /api/auth/logout
  Future<void> logout() async {
    await _client.post(ApiConstants.logout);
  }
}
