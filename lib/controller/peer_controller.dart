// ─────────────────────────────────────────────────────────────────────────────
// controller/peer_controller.dart
// ─────────────────────────────────────────────────────────────────────────────
import '../model/peer_user_model.dart';
import '../service/peer_service.dart';

class PeerController {
  final PeerService _service = PeerService();

  late PeerUser currentUser;
  List<PeerUser> availablePeers = [];

  // ── Initialise with a stable Firebase Auth UID ────────────────────────────
  Future<void> initUser() async {
    final uid = await _service.getOrCreateAnonymousUid();
    final suffix =
        uid.length >= 4 ? uid.substring(uid.length - 4) : uid;

    currentUser = PeerUser(
      id: uid,
      username: '@user_$suffix',
      isAvailable: false,
    );

    await _service.registerUser(currentUser);
  }

  // ── Toggle availability in Firestore ──────────────────────────────────────
  Future<void> toggleAvailability(bool value) async {
    currentUser.isAvailable = value;
    await _service.updateAvailability(currentUser.id, value);
  }

  // ── Fetch peers (one-shot, used for initial navigation) ───────────────────
  Future<void> findPeers() async {
    availablePeers =
        await _service.getAvailablePeers(currentUser.id);
  }

  // ── Live stream — used by PeerListScreen ──────────────────────────────────
  Stream<List<PeerUser>> peersStream() =>
      _service.availablePeersStream(currentUser.id);

  // ── Mark user offline on app exit ────────────────────────────────────────
  Future<void> goOffline() async {
    await _service.goOffline(currentUser.id);
  }
}