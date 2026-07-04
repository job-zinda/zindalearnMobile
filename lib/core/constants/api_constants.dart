class ApiConstants {
  static const String baseUrl = 'http://localhost:5005';

  // Auth endpoints
  static const String register = '/api/auth/register-direct';
  static const String login = '/api/auth/login';
  static const String googleLogin = '/api/auth/google-login';
  static const String sendOtp = '/api/auth/send-otp';
  static const String verifyOtp = '/api/auth/verify-otp';
  static const String me = '/api/auth/me';
  static const String updateProfile = '/api/student/settings/profile';
  static const String changePassword = '/api/auth/password';
  static const String logout = '/api/auth/logout';

  // Upload
  static const String upload = '/api/upload';

  // Course endpoints
  static const String courses = '/api/courses';
  static String course(String id) => '/api/courses/$id';

  // Enrollment endpoints
  static const String enrollments = '/api/enrollments';
  static const String enroll = '/api/enrollments/enroll';
}
