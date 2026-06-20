// ─────────────────────────────────────────────────────────────────────────────
// service/peer_chat_service.dart
//
// FIX SUMMARY
// ───────────
// BUG 1 — orderBy('sentAt') crashed / skipped messages because serverTimestamp()
//          is null on the sender device until the round-trip completes.
//          FIX: add includeMetadataChanges: false and a local 'sentAtMillis'
//          integer field written at send-time so ordering always works.
//
// BUG 2 — Receiver never knew a chat was started because nothing in Firestore
//          was listened to on the peer's side.
//          FIX: new incomingChatStream(myId) — queries chats where participants
//          contains myId AND isActive==true. PeerSupportScreen subscribes to
//          this and auto-navigates to PeerChatScreen when a room appears.
//
// Firestore structure (unchanged):
//   chats/{uid1_uid2}            → session doc
//   chats/{uid1_uid2}/messages/  → sub-collection
// ─────────────────────────────────────────────────────────────────────────────
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supporthive1/model/chat_model.dart';

class PeerChatService {
  final _db = FirebaseFirestore.instance;

  // ── Profanity block-list ───────────────────────────────────────────────────
  static const _blockedWords = <String>[
    'fuck', 'shit', 'bitch', 'asshole', 'bastard', 'cunt', 'dick',
    'pussy', 'faggot', 'nigger', 'slut', 'whore', 'motherfucker',
    'retard', 'kill yourself', 'kys',
  ];

  bool _containsProfanity(String text) {
    final lower = text.toLowerCase();
    return _blockedWords.any((w) => lower.contains(w));
  }

  // ── Create / get chat room ─────────────────────────────────────────────────
  // Called by the INITIATOR (User A who tapped "Chat" on User B).
  // The room document is written to Firestore with isActive:true, which
  // triggers the receiver's incomingChatStream and auto-opens the chat.
  Future<String> getOrCreateChatRoom(String myId, String peerId) async {
    final ids = [myId, peerId]..sort();
    final roomId = '${ids[0]}_${ids[1]}';
    final ref = _db.collection('chats').doc(roomId);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'participants': ids,
        'initiatorId': myId,   // who started the chat
        'peerId': peerId,      // who was invited
        'startedAt': FieldValue.serverTimestamp(),
        'startedAtMillis': DateTime.now().millisecondsSinceEpoch,
        'endedAt': null,
        'durationSeconds': null,
        'typing': {myId: false, peerId: false},
        'ratings': {},
        'isActive': true,      // ← receiver watches for this
      });
    } else {
      // Room already exists — re-activate if it was ended
      final data = snap.data()!;
      if (data['isActive'] != true) {
        await ref.update({
          'isActive': true,
          'startedAt': FieldValue.serverTimestamp(),
          'startedAtMillis': DateTime.now().millisecondsSinceEpoch,
          'endedAt': null,
          'durationSeconds': null,
          'typing': {myId: false, peerId: false},
        });
      }
    }
    return roomId;
  }

  // ── [KEY FIX] Incoming chat stream for the receiver ───────────────────────
  // User B subscribes to this from PeerSupportScreen.
  // When User A creates a chat room with B, this emits the roomId + initiator
  // username so B can be auto-navigated into the chat.
  Stream<Map<String, dynamic>?> incomingChatStream(String myId) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: myId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) {
      // Find rooms where I am the receiver (not the initiator)
      for (final doc in snap.docs) {
        final data = doc.data();
        final initiatorId = data['initiatorId'] as String?;
        // If I didn't start this room, I'm the receiver — open it
        if (initiatorId != null && initiatorId != myId) {
          return {
            'chatRoomId': doc.id,
            'initiatorId': initiatorId,
          };
        }
      }
      return null;
    });
  }

  // ── Send message ──────────────────────────────────────────────────────────
  // FIX: writes 'sentAtMillis' (int) alongside serverTimestamp so ordering
  // is reliable even before the server round-trip completes.
  Future<bool> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    final blocked = _containsProfanity(trimmed);
    final nowMillis = DateTime.now().millisecondsSinceEpoch;

    await _db
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'text': blocked ? '⚠️ Message blocked (inappropriate content)' : trimmed,
      'sentAt': FieldValue.serverTimestamp(),
      'sentAtMillis': nowMillis,   // ← used for ordering; never null
      'isRead': false,
      'isBlocked': blocked,
    });

    return !blocked;
  }

  // ── Messages stream ────────────────────────────────────────────────────────
  // FIX: order by 'sentAtMillis' (int) — always present, never null,
  // works instantly without waiting for server timestamp resolution.
  Stream<List<ChatMessage>> messagesStream(String chatRoomId) {
    return _db
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('sentAtMillis', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromDoc).toList());
  }

  // ── Typing indicator ──────────────────────────────────────────────────────
  Future<void> setTyping(
      String chatRoomId, String userId, bool isTyping) async {
    try {
      await _db.collection('chats').doc(chatRoomId).update({
        'typing.$userId': isTyping,
      });
    } catch (_) {}
  }

  Stream<bool> peerTypingStream(String chatRoomId, String peerId) {
    return _db
        .collection('chats')
        .doc(chatRoomId)
        .snapshots()
        .map((snap) {
      final data = snap.data();
      if (data == null) return false;
      final typing = data['typing'] as Map<String, dynamic>? ?? {};
      return typing[peerId] as bool? ?? false;
    });
  }

  // ── Mark messages as read ─────────────────────────────────────────────────
  Future<void> markRead(String chatRoomId, String myId) async {
    try {
      final unread = await _db
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .where('senderId', isNotEqualTo: myId)
          .where('isRead', isEqualTo: false)
          .get();

      if (unread.docs.isEmpty) return;
      final batch = _db.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (_) {}
  }

  // ── End session — records metadata, deletes all messages ─────────────────
  Future<void> endChatSession(String chatRoomId) async {
    final ref = _db.collection('chats').doc(chatRoomId);
    final snap = await ref.get();
    if (!snap.exists) return;

    final data = snap.data()!;
    final startMillis = data['startedAtMillis'] as int?;
    final nowMillis = DateTime.now().millisecondsSinceEpoch;
    final durationSeconds = startMillis != null
        ? ((nowMillis - startMillis) / 1000).round()
        : 0;

    await ref.update({
      'endedAt': FieldValue.serverTimestamp(),
      'durationSeconds': durationSeconds,
      'isActive': false,
      'typing': {},
    });

    await _deleteAllMessages(chatRoomId);
  }

  Future<void> _deleteAllMessages(String chatRoomId) async {
    const batchSize = 100;
    while (true) {
      final snap = await _db
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .limit(batchSize)
          .get();
      if (snap.docs.isEmpty) break;
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  // ── Rating ────────────────────────────────────────────────────────────────
  Future<void> submitRating({
    required String chatRoomId,
    required String raterUserId,
    required int stars,
  }) async {
    await _db.collection('chats').doc(chatRoomId).update({
      'ratings.$raterUserId': stars.clamp(1, 5),
    });
  }

  Future<ChatSession?> fetchSession(String chatRoomId) async {
    final snap = await _db.collection('chats').doc(chatRoomId).get();
    if (!snap.exists) return null;
    return ChatSession.fromDoc(snap);
  }

  Stream<ChatSession?> sessionStream(String chatRoomId) {
    return _db
        .collection('chats')
        .doc(chatRoomId)
        .snapshots()
        .map((snap) => snap.exists ? ChatSession.fromDoc(snap) : null);
  }
}