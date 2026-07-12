class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? bio;
  final String? phone;
  final String? avatar;
  final String? username;
  final String? language;
  final bool isVerified;
  final bool emailVerified;
  // Instructor-only: whether an admin has approved this instructor account.
  // Unapproved instructors can sign in and see their dashboard, but course
  // creation is blocked (mirrors the web app's client-side gate).
  final bool isApproved;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.bio,
    this.phone,
    this.avatar,
    this.username,
    this.language,
    this.isVerified = false,
    this.emailVerified = false,
    this.isApproved = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'student',
      bio: json['bio'],
      phone: json['phone'],
      avatar: json['avatar'],
      username: json['username'],
      language: json['language'],
      isVerified: json['isVerified'] ?? false,
      emailVerified: json['emailVerified'] ?? false,
      isApproved: json['isApproved'] ?? (json['role'] != 'instructor'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'role': role,
      'bio': bio,
      'phone': phone,
      'avatar': avatar,
      'username': username,
      'language': language,
      'isVerified': isVerified,
      'emailVerified': emailVerified,
      'isApproved': isApproved,
    };
  }

  UserModel copyWith({
    String? name,
    String? bio,
    String? phone,
    String? avatar,
    String? username,
    String? language,
    bool? isVerified,
    bool? emailVerified,
    bool? isApproved,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      role: role,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      username: username ?? this.username,
      language: language ?? this.language,
      isVerified: isVerified ?? this.isVerified,
      emailVerified: emailVerified ?? this.emailVerified,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}
