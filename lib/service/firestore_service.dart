import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/podcast.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Collection reference ────────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _podcastsCol =>
      _db.collection('podcasts');

  // ── Current user guard ──────────────────────────────────────────────────────
  User get _currentUser {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user;
  }

  // ── Read ────────────────────────────────────────────────────────────────────

  /// Returns a real-time stream of all podcasts ordered by newest first.
  Stream<List<Podcast>> podcastsStream() {
    return _podcastsCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Podcast.fromDoc).toList());
  }

  /// One-shot fetch (useful for pagination / pull-to-refresh).
  Future<List<Podcast>> fetchPodcasts({int limit = 20}) async {
    final snap = await _podcastsCol
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(Podcast.fromDoc).toList();
  }

  /// Fetches podcasts uploaded by the currently signed-in user.
  Stream<List<Podcast>> myPodcastsStream() {
    return _podcastsCol
        .where('authorId', isEqualTo: _currentUser.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Podcast.fromDoc).toList());
  }

  /// Fetches a single podcast by its ID.
  Future<Podcast?> fetchPodcastById(String id) async {
    final doc = await _podcastsCol.doc(id).get();
    if (!doc.exists) return null;
    return Podcast.fromDoc(doc);
  }

  // ── Write ───────────────────────────────────────────────────────────────────

  /// Adds a new podcast document and returns the assigned ID.
  Future<String> addPodcast(Podcast podcast) async {
    final user = _currentUser;

    final data = podcast.toFirestore()
      ..['authorId'] = user.uid
      ..['author'] = user.displayName ?? podcast.author
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['isNew'] = true;

    final ref = await _podcastsCol.add(data);
    return ref.id;
  }

  /// Updates an existing podcast document (only fields provided are changed).
  Future<void> updatePodcast(String id, Map<String, dynamic> fields) async {
    final user = _currentUser;

    // Security: only the author can update their own podcast.
    final doc = await _podcastsCol.doc(id).get();
    final authorId = (doc.data() ?? {})['authorId'] as String?;
    if (authorId != user.uid) {
      throw Exception('Permission denied: you are not the author of this podcast.');
    }

    await _podcastsCol.doc(id).update(fields);
  }

  /// Deletes a podcast document. Only the author may do this.
  Future<void> deletePodcast(String id) async {
    final user = _currentUser;

    final doc = await _podcastsCol.doc(id).get();
    final authorId = (doc.data() ?? {})['authorId'] as String?;
    if (authorId != user.uid) {
      throw Exception('Permission denied: you are not the author of this podcast.');
    }

    await _podcastsCol.doc(id).delete();
  }

  /// Increments the play count atomically.
  Future<void> incrementPlayCount(String id) async {
    await _podcastsCol.doc(id).update({
      'playCount': FieldValue.increment(1),
    });
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Marks podcasts older than 7 days as no longer "new".
  /// Call this from a Cloud Function or a background task.
  Future<void> expireNewBadges() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final snap = await _podcastsCol
        .where('isNew', isEqualTo: true)
        .where('createdAt', isLessThan: Timestamp.fromDate(cutoff))
        .get();

    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isNew': false});
    }
    await batch.commit();
  }
}