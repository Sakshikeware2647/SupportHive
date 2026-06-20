// ─────────────────────────────────────────────────────────────────────────────
// model/peer_user_model.dart
// ─────────────────────────────────────────────────────────────────────────────

class PeerUser {
  final String id;
  final String username;
  bool isAvailable;

  PeerUser({
    required this.id,
    required this.username,
    this.isAvailable = false,
  });

  PeerUser copyWith({String? id, String? username, bool? isAvailable}) {
    return PeerUser(
      id: id ?? this.id,
      username: username ?? this.username,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'isAvailable': isAvailable,
      };

  factory PeerUser.fromMap(Map<String, dynamic> map) => PeerUser(
        id: map['id'] as String,
        username: map['username'] as String,
        isAvailable: map['isAvailable'] as bool? ?? false,
      );
}