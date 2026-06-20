class UserProfileModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String photoUrl;
  final int sessions;
  final int podcastsListened;
  final String wellnessScore;
  final String bio;
  final DateTime? createdAt;

  UserProfileModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl = '',
    this.sessions = 0,
    this.podcastsListened = 0,
    this.wellnessScore = '0%',
    this.bio = '',
    this.createdAt,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return 'U';
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  factory UserProfileModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfileModel(
      uid: uid,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      sessions: (data['sessions'] as num?)?.toInt() ?? 0,
      podcastsListened: (data['podcastsListened'] as num?)?.toInt() ?? 0,
      wellnessScore: data['wellnessScore'] as String? ?? '0%',
      bio: data['bio'] as String? ?? '',
    );
  }

  /// Build a skeleton model directly from Firebase Auth — used as instant
  /// fallback while Firestore loads or when no document exists yet.
  factory UserProfileModel.fromFirebaseUser({
    required String uid,
    required String? displayName,
    required String? email,
    required String? photoURL,
  }) {
    return UserProfileModel(
      uid: uid,
      name: displayName ?? '',
      email: email ?? '',
      phone: '',
      photoUrl: photoURL ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'photoUrl': photoUrl,
        'sessions': sessions,
        'podcastsListened': podcastsListened,
        'wellnessScore': wellnessScore,
        'bio': bio,
      };

  UserProfileModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    int? sessions,
    int? podcastsListened,
    String? wellnessScore,
    String? bio,
  }) {
    return UserProfileModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      sessions: sessions ?? this.sessions,
      podcastsListened: podcastsListened ?? this.podcastsListened,
      wellnessScore: wellnessScore ?? this.wellnessScore,
      bio: bio ?? this.bio,
      createdAt: createdAt,
    );
  }
}