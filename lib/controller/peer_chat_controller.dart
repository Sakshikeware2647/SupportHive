// ─────────────────────────────────────────────────────────────────────────────
// controller/peer_chat_controller.dart
// ─────────────────────────────────────────────────────────────────────────────
import 'package:supporthive1/model/chat_model.dart';
import '../service/peer_chat_service.dart';

class PeerChatController {
  final PeerChatService _service = PeerChatService();

  String? chatRoomId;

  // ── Called by INITIATOR: User A who tapped "Chat" on User B ──────────────
  Future<String> initRoom(String myId, String peerId) async {
    chatRoomId = await _service.getOrCreateChatRoom(myId, peerId);
    return chatRoomId!;
  }

  // ── Called by RECEIVER: User B who was auto-navigated into the chat ───────
  // Accepts the roomId that already exists in Firestore (created by A).
  void acceptRoom(String roomId) {
    chatRoomId = roomId;
  }

  // ── Incoming chat stream — subscribed by PeerSupportScreen for the receiver
  Stream<Map<String, dynamic>?> incomingChatStream(String myId) {
    return _service.incomingChatStream(myId);
  }

  // ── Send ──────────────────────────────────────────────────────────────────
  Future<bool> sendMessage({
    required String senderId,
    required String text,
  }) async {
    if (chatRoomId == null) return false;
    return _service.sendMessage(
      chatRoomId: chatRoomId!,
      senderId: senderId,
      text: text,
    );
  }

  // ── Messages stream ───────────────────────────────────────────────────────
  Stream<List<ChatMessage>> messagesStream() {
    if (chatRoomId == null) return const Stream.empty();
    return _service.messagesStream(chatRoomId!);
  }

  // ── Typing ────────────────────────────────────────────────────────────────
  Future<void> setTyping(String userId, bool isTyping) async {
    if (chatRoomId == null) return;
    await _service.setTyping(chatRoomId!, userId, isTyping);
  }

  Stream<bool> peerTypingStream(String peerId) {
    if (chatRoomId == null) return const Stream.empty();
    return _service.peerTypingStream(chatRoomId!, peerId);
  }

  // ── Read receipts ─────────────────────────────────────────────────────────
  Future<void> markRead(String myId) async {
    if (chatRoomId == null) return;
    await _service.markRead(chatRoomId!, myId);
  }

  // ── End session ───────────────────────────────────────────────────────────
  Future<void> endSession() async {
    if (chatRoomId == null) return;
    await _service.endChatSession(chatRoomId!);
  }

  // ── Rating ────────────────────────────────────────────────────────────────
  Future<void> submitRating({
    required String raterUserId,
    required int stars,
  }) async {
    if (chatRoomId == null) return;
    await _service.submitRating(
      chatRoomId: chatRoomId!,
      raterUserId: raterUserId,
      stars: stars,
    );
  }

  // ── Session metadata ──────────────────────────────────────────────────────
  Future<ChatSession?> fetchSession() async {
    if (chatRoomId == null) return null;
    return _service.fetchSession(chatRoomId!);
  }

  Stream<ChatSession?> sessionStream() {
    if (chatRoomId == null) return const Stream.empty();
    return _service.sessionStream(chatRoomId!);
  }
}