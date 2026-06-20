// ─────────────────────────────────────────────────────────────────────────────
// model/chat_models.dart
// ─────────────────────────────────────────────────────────────────────────────
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final bool isRead;
  final bool isBlocked; // flagged by profanity filter

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
    this.isRead = false,
    this.isBlocked = false,
  });

  factory ChatMessage.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: d['senderId'] as String,
      text: d['text'] as String,
      sentAt: (d['sentAt'] as Timestamp).toDate(),
      isRead: d['isRead'] as bool? ?? false,
      isBlocked: d['isBlocked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'text': text,
        'sentAt': Timestamp.fromDate(sentAt),
        'isRead': isRead,
        'isBlocked': isBlocked,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// ChatSession — stored in Firestore under chats/{chatRoomId}
// Tracks metadata: participants, timing, rating, and typing state
// Firestore only stores session metadata — NOT readable message content (by design)
// ─────────────────────────────────────────────────────────────────────────────
class ChatSession {
  final String chatRoomId;
  final List<String> participants;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final Map<String, int?> ratings; // userId → 1–5 star rating
  final Map<String, bool> typing;

  const ChatSession({
    required this.chatRoomId,
    required this.participants,
    this.startedAt,
    this.endedAt,
    this.ratings = const {},
    this.typing = const {},
  });

  factory ChatSession.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatSession(
      chatRoomId: doc.id,
      participants: List<String>.from(d['participants'] ?? []),
      startedAt: d['startedAt'] != null
          ? (d['startedAt'] as Timestamp).toDate()
          : null,
      endedAt: d['endedAt'] != null
          ? (d['endedAt'] as Timestamp).toDate()
          : null,
      ratings: Map<String, int?>.from(d['ratings'] ?? {}),
      typing: Map<String, bool>.from(d['typing'] ?? {}),
    );
  }

  /// Duration of the chat session (null if not ended yet)
  Duration? get duration {
    if (startedAt == null || endedAt == null) return null;
    return endedAt!.difference(startedAt!);
  }

  String get formattedDuration {
    final d = duration;
    if (d == null) return '—';
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }
}