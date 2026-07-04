import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/network/api_exceptions.dart';
import '../core/storage/secure_storage.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleInitialized = false;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;
  String? _profileMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  String? get profileMessage => _profileMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  /// Check if user is already logged in on app start
  Future<void> checkAuthStatus() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      // Try to load cached user first for instant UI
      final cachedUser = await SecureStorage.getUserData();
      if (cachedUser != null) {
        _user = UserModel.fromJson(jsonDecode(cachedUser));
        _status = AuthStatus.authenticated;
        notifyListeners();
      }

      // Then validate token with server
      final response = await _authService.getMe();
      if (response.success && response.data != null) {
        _user = response.data;
        await SecureStorage.saveUserData(jsonEncode(_user!.toJson()));
        _status = AuthStatus.authenticated;
      } else {
        await _logout();
      }
    } on ApiException catch (e) {
      // Only a genuine auth failure (401) should end the session. Network
      // errors (timeout / "no internet" → null statusCode) must NOT wipe the
      // saved token, otherwise the user is logged out on every launch whenever
      // the backend is momentarily unreachable.
      if (e.statusCode == 401) {
        await _logout();
      } else if (_user != null) {
        _status = AuthStatus.authenticated; // stay logged in on cached data
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      // If offline but has cached data, stay authenticated
      if (_user != null) {
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    }
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String role = 'student',
  }) async {
    return _handleAuth(() async {
      final response = await _authService.register(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      return response;
    });
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    return _handleAuth(() async {
      final response = await _authService.login(
        email: email,
        password: password,
      );
      return response;
    });
  }

  Future<void> _ensureGoogleInitialized() async {
    if (!_googleInitialized) {
      await _googleSignIn.initialize();
      _googleInitialized = true;
    }
  }

  Future<bool> googleLogin() async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      await _ensureGoogleInitialized();
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        _errorMessage = 'Failed to get Google credentials.';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }

      return _handleAuth(() async {
        final response = await _authService.googleLogin(token: idToken);
        return response;
      });
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
      _errorMessage = 'Google sign-in failed: ${e.description}';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Google sign-in failed. Please try again.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendOtp({required String email}) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final response = await _authService.sendOtp(email: email);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return response.success;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp({
    required String email,
    required String otp,
  }) async {
    return _handleAuth(() async {
      final response = await _authService.verifyOtp(
        email: email,
        otp: otp,
      );
      return response;
    });
  }

  Future<bool> updateProfile({
    String? name,
    String? email,
    String? bio,
    String? username,
    String? phone,
    String? language,
    String? avatar,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      _profileMessage = null;
      notifyListeners();

      final response = await _authService.updateProfile(
        name: name,
        email: email,
        bio: bio,
        username: username,
        phone: phone,
        language: language,
        avatar: avatar,
      );

      if (response.success && response.data != null) {
        _user = response.data;
        await SecureStorage.saveUserData(jsonEncode(_user!.toJson()));
        _profileMessage = response.message.isNotEmpty ? response.message : null;
      } else {
        _errorMessage = response.message;
      }

      _status = AuthStatus.authenticated;
      notifyListeners();
      return response.success;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final response = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      _status = AuthStatus.authenticated;
      notifyListeners();
      return response.success;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (_) {
      // Ignore — the local session must be cleared regardless of whether
      // the server call succeeds (e.g. offline logout).
    }
    try {
      await _ensureGoogleInitialized();
      await _googleSignIn.disconnect();
    } catch (_) {
      // Ignore Google sign-out errors
    }
    await _logout();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Shared logic for register / login / verifyOtp / googleLogin.
  /// Expects the API response to contain `token` and optionally `user`.
  Future<bool> _handleAuth(
    Future<dynamic> Function() apiCall,
  ) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final response = await apiCall();

      if (response.success) {
        final data = response.data as Map<String, dynamic>?;
        final token = data?['token'] as String?;

        if (token != null) {
          await SecureStorage.saveToken(token);
        }

        // Some endpoints return user directly, some need a /me call
        if (data?['user'] != null) {
          _user = UserModel.fromJson(data!['user']);
          await SecureStorage.saveUserData(jsonEncode(_user!.toJson()));
          _status = AuthStatus.authenticated;
        } else if (token != null) {
          await _fetchAndCacheUser();
        }

        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> _fetchAndCacheUser() async {
    try {
      final meResponse = await _authService.getMe();
      if (meResponse.success && meResponse.data != null) {
        _user = meResponse.data;
        await SecureStorage.saveUserData(jsonEncode(_user!.toJson()));
        _status = AuthStatus.authenticated;
      }
    } catch (_) {
      // Token might be invalid
    }
  }

  Future<void> _logout() async {
    _user = null;
    _status = AuthStatus.unauthenticated;
    await SecureStorage.clearAll();
  }
}
