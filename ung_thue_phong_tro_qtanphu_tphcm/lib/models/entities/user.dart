// ═══════════════════════════════════════════
// USER ENTITY
// ═══════════════════════════════════════════
enum UserRole { tenant, landlord, admin }

class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final UserRole role;
  final String? avatarUrl;
  final DateTime createdAt;
  final String? gender;
  final int? birthYear;
  final String? hometown;
  final String? occupation;
  final String? bio;
  final double? averageRating;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.avatarUrl,
    required this.createdAt,
    this.gender,
    this.birthYear,
    this.hometown,
    this.occupation,
    this.bio,
    this.averageRating,
  });

  bool get isLandlord => role == UserRole.landlord;
  bool get isTenant => role == UserRole.tenant;
  bool get isAdmin => role == UserRole.admin;

  AppUser copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    UserRole? role,
    String? avatarUrl,
    DateTime? createdAt,
    String? gender,
    int? birthYear,
    String? hometown,
    String? occupation,
    String? bio,
    double? averageRating,
  }) {
    return AppUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      gender: gender ?? this.gender,
      birthYear: birthYear ?? this.birthYear,
      hometown: hometown ?? this.hometown,
      occupation: occupation ?? this.occupation,
      bio: bio ?? this.bio,
      averageRating: averageRating ?? this.averageRating,
    );
  }
}
