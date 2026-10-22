// ─────────────────────────────────────────────────────────────────
// model/intern_model.dart
// ─────────────────────────────────────────────────────────────────

class Intern {
  final String internId;
  final String name;
  final String email;
  final String phone;
  final String specialization;
  final double rating;
  final bool isAvailable;
  final String fcmToken;
  final String bio;
  final int sessionCount;

  Intern({
    required this.internId,
    required this.name,
    required this.email,
    required this.phone,
    required this.specialization,
    required this.rating,
    required this.isAvailable,
    required this.fcmToken,
    this.bio = '',
    this.sessionCount = 0,
  });

  String get avatarInitials =>
      name.split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).take(2).join();

  factory Intern.fromMap(String id, Map<String, dynamic> map) {
    return Intern(
      internId: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      specialization: map['specialization'] ?? '',
      rating: (map['rating'] ?? 4.5).toDouble(),
      isAvailable: map['isAvailable'] ?? false,
      fcmToken: map['fcmToken'] ?? '',
      bio: map['bio'] ?? '',
      sessionCount: map['sessionCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'specialization': specialization,
        'rating': rating,
        'isAvailable': isAvailable,
        'fcmToken': fcmToken,
        'bio': bio,
        'sessionCount': sessionCount,
      };
}