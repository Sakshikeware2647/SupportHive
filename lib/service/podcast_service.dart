import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../model/podcast.dart';

/// Pure data-access layer. No UI, no ChangeNotifier.
class PodcastService {
  PodcastService._();
  static final PodcastService instance = PodcastService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  // ── Fetch podcasts ──────────────────────────────────────────────────────────

  Future<List<Podcast>> fetchPodcasts({String? category}) async {
    try {
      Query query =
          _db.collection('podcasts').orderBy('createdAt', descending: true);
      if (category != null && category != 'All') {
        query = query.where('category', isEqualTo: category);
      }
      final snap = await query.get();
      return snap.docs.map((d) => Podcast.fromDoc(d)).toList();
    } catch (_) {
      return _fallbackPodcasts();
    }
  }

  /// Real-time stream for live updates.
  Stream<List<Podcast>> podcastsStream() {
    return _db
        .collection('podcasts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Podcast.fromDoc(d)).toList());
  }

  // ── Access control (premium unlock) ────────────────────────────────────────

  /// Returns true if the current user has access to this podcast.
  Future<bool> hasAccess(Podcast podcast) async {
    if (!podcast.isPremium || podcast.isFree) return true;
    if (_uid.isEmpty) return false;
    try {
      final doc = await _db
          .collection('users')
          .doc(_uid)
          .collection('unlockedPodcasts')
          .doc(podcast.id)
          .get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  /// Records a successful Razorpay payment and unlocks the podcast for this user.
  Future<void> unlockPodcast(String podcastId, String paymentId) async {
    if (_uid.isEmpty) {
      throw Exception('User not logged in. Cannot unlock podcast.');
    }
    await _db
        .collection('users')
        .doc(_uid)
        .collection('unlockedPodcasts')
        .doc(podcastId)
        .set({
      'unlockedAt': FieldValue.serverTimestamp(),
      'paymentId': paymentId,
    });
  }

  /// Batch-fetch which podcast IDs the current user has unlocked.
  Future<Set<String>> fetchUnlockedIds() async {
    if (_uid.isEmpty) return {};
    try {
      final snap = await _db
          .collection('users')
          .doc(_uid)
          .collection('unlockedPodcasts')
          .get();
      return snap.docs.map((d) => d.id).toSet();
    } catch (_) {
      return {};
    }
  }

  // ── Playback progress ───────────────────────────────────────────────────────

  static const String _progressKey = 'podcast_progress';

  /// Save playback position locally (SharedPreferences).
  Future<void> saveProgress(String podcastId, Duration position) async {
    if (podcastId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _readProgressMap(prefs);
      map[podcastId] = position.inSeconds;
      await prefs.setString(_progressKey, jsonEncode(map));
    } catch (_) {}
  }

  /// Load saved position for a podcast. Returns [Duration.zero] if not saved.
  Future<Duration> loadProgress(String podcastId) async {
    if (podcastId.isEmpty) return Duration.zero;
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _readProgressMap(prefs);
      final seconds = map[podcastId] as int? ?? 0;
      return Duration(seconds: seconds);
    } catch (_) {
      return Duration.zero;
    }
  }

  /// Clear progress for a finished podcast.
  Future<void> clearProgress(String podcastId) async {
    if (podcastId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _readProgressMap(prefs);
      map.remove(podcastId);
      await prefs.setString(_progressKey, jsonEncode(map));
    } catch (_) {}
  }

  Map<String, dynamic> _readProgressMap(SharedPreferences prefs) {
    final raw = prefs.getString(_progressKey);
    if (raw == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  /// Returns a map of podcastId → completion percentage (0–100).
  /// FIX: properly casts stored int/double values to int.
  Future<Map<String, int>> fetchAllProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_progressKey);
      if (raw == null) return {};
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  // ── Likes ───────────────────────────────────────────────────────────────────

  Future<void> toggleLike(String podcastId, bool liked) async {
    if (_uid.isEmpty || podcastId.isEmpty) return;
    final ref = _db.collection('podcasts').doc(podcastId);
    if (liked) {
      await ref
          .update({'likeCount': FieldValue.increment(1)}).catchError((_) {});
      await _db
          .collection('users')
          .doc(_uid)
          .collection('likedPodcasts')
          .doc(podcastId)
          .set({'likedAt': FieldValue.serverTimestamp()});
    } else {
      await ref
          .update({'likeCount': FieldValue.increment(-1)}).catchError((_) {});
      await _db
          .collection('users')
          .doc(_uid)
          .collection('likedPodcasts')
          .doc(podcastId)
          .delete();
    }
  }

  Future<Set<String>> fetchLikedIds() async {
    if (_uid.isEmpty) return {};
    try {
      final snap = await _db
          .collection('users')
          .doc(_uid)
          .collection('likedPodcasts')
          .get();
      return snap.docs.map((d) => d.id).toSet();
    } catch (_) {
      return {};
    }
  }

  // ── Add / Delete ────────────────────────────────────────────────────────────

  Future<String> addPodcast(Podcast podcast) async {
    final data = podcast.toFirestore();
    data['authorId'] = _uid;
    final ref = await _db.collection('podcasts').add(data);
    return ref.id;
  }

  Future<void> deletePodcast(String id) async {
    await _db.collection('podcasts').doc(id).delete();
  }

  /// Fire-and-forget play count increment — errors are swallowed intentionally.
  void incrementPlayCount(String id) {
    if (id.isEmpty) return;
    _db
        .collection('podcasts')
        .doc(id)
        .update({'playCount': FieldValue.increment(1)}).catchError((_) {});
  }

  // ── Recommendations ─────────────────────────────────────────────────────────

  Future<List<Podcast>> fetchRecommended(Podcast current,
      {int limit = 3}) async {
    try {
      final snap = await _db
          .collection('podcasts')
          .where('category', isEqualTo: current.category)
          .orderBy('playCount', descending: true)
          .limit(limit + 1)
          .get();
      return snap.docs
          .map((d) => Podcast.fromDoc(d))
          .where((p) => p.id != current.id)
          .take(limit)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Fallback data ───────────────────────────────────────────────────────────

  List<Podcast> _fallbackPodcasts() => [
        Podcast(
          id: 'fallback_1',
          title: 'The Anxiety Solution',
          author: 'Michael Roberts',
          category: 'Mental Health',
          duration: '11:00',
          audioUrl:
              'assets/audios/Secret_To_Mastering_Your_Emotions_Dr_Sweta_Adatia_Raj_Shama_podcast.mp3',
          description:
              'Learn proven techniques to manage and overcome anxiety in daily life.',
          isNew: true,
          isPremium: false,
          tags: ['anxiety', 'mental health', 'wellness'],
        ),
        Podcast(
          id: 'fallback_2',
          title: 'Mindfulness Mastery',
          author: 'Dr. Priya Mehta',
          category: 'Mindfulness',
          duration: '18:30',
          audioUrl: '',
          description: 'A deep dive into mindfulness practices for everyday calm.',
          isNew: false,
          isPremium: true,
          price: 99,
          tags: ['mindfulness', 'meditation', 'calm'],
        ),
        Podcast(
          id: 'fallback_3',
          title: 'Sleep Science Unlocked',
          author: 'Dr. Arjun Kapoor',
          category: 'Sleep',
          duration: '22:15',
          audioUrl: '',
          description:
              'Expert insights into optimizing your sleep for better mental health.',
          isNew: true,
          isPremium: true,
          price: 149,
          tags: ['sleep', 'health', 'science'],
        ),
      ];
}