// ─────────────────────────────────────────────────────────────────────────────
// service/peer_service.dart
// Handles peer presence/availability in Firestore
// Firestore structure:  peers/{uid} → { id, username, isAvailable, lastSeen }
// ─────────────────────────────────────────────────────────────────────────────
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/peer_user_model.dart';

class PeerService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ── Stable anonymous UID via Firebase Auth ────────────────────────────────
  Future<String> getOrCreateAnonymousUid() async {
    User? user = _auth.currentUser;
    if (user == null) {
      final cred = await _auth.signInAnonymously();
      user = cred.user!;
    }
    return user.uid;
  }

  // ── Register / refresh peer document in Firestore ─────────────────────────
  Future<void> registerUser(PeerUser peerUser) async {
    await _db.collection('peers').doc(peerUser.id).set({
      'id': peerUser.id,
      'username': peerUser.username,
      'isAvailable': peerUser.isAvailable,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── Toggle availability ────────────────────────────────────────────────────
  Future<void> updateAvailability(String userId, bool isAvailable) async {
    await _db.collection('peers').doc(userId).update({
      'isAvailable': isAvailable,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  // ── One-shot fetch of available peers (excludes self) ─────────────────────
  Future<List<PeerUser>> getAvailablePeers(String excludeId) async {
    final snap = await _db
        .collection('peers')
        .where('isAvailable', isEqualTo: true)
        .get();

    return snap.docs
        .where((doc) => doc.id != excludeId)
        .map((doc) => PeerUser.fromMap(doc.data()))
        .toList();
  }

  // ── Live stream of available peers (excludes self) ────────────────────────
  Stream<List<PeerUser>> availablePeersStream(String excludeId) {
    return _db
        .collection('peers')
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .where((doc) => doc.id != excludeId)
            .map((doc) => PeerUser.fromMap(doc.data()))
            .toList());
  }

  // ── Mark user offline when they leave the app ─────────────────────────────
  Future<void> goOffline(String userId) async {
    await _db.collection('peers').doc(userId).update({
      'isAvailable': false,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }
}