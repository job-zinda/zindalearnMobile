class ApiConstants {
  // static const String baseUrl = 'http://localhost:5005';
  static const String baseUrl = 'https://zindalearnbackend-1.onrender.com';

  // Google Sign-In (Firebase "zindalearn" project Web client ID — used as
  // serverClientId so Android/iOS return a backend-verifiable idToken)
  static const String googleServerClientId =
      '777539474175-jsv34a0uk81bttbsmvl1jb7f2otldh99.apps.googleusercontent.com';

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

  // Messages endpoints
  static const String conversations = '/api/messages/conversations';
  static const String eligibleContacts = '/api/messages/eligible-contacts';
  static const String sendMessage = '/api/messages';
  static String conversationMessages(String conversationId) =>
      '/api/messages/$conversationId';
  static String markConversationRead(String conversationId) =>
      '/api/messages/$conversationId/read';

  // Live classes
  static const String studentLiveClasses = '/api/live-classes/student';
  static String joinLiveClass(String id) => '/api/live-classes/$id/join';

  // Progress
  static const String progressOverview = '/api/student/progress/overview';
  static const String progressAnalytics = '/api/student/progress/analytics';

  // Certificates
  static const String certificateStats = '/api/student/certificates/stats';
  static const String certificates = '/api/student/certificates';
  static const String featuredCertificate = '/api/student/certificates/featured';

  // Settings
  static const String settings = '/api/student/settings';
  static const String updateNotifications = '/api/student/settings/notifications';

  // Support
  static const String supportTickets = '/api/support/tickets';
}
