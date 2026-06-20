import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// WellnessService
/// Central source of truth for points, streaks, task completion & notifications.
/// All screens read/write through this class — never directly to Firestore.
/// ─────────────────────────────────────────────────────────────────────────────
class WellnessService {
  static final WellnessService _i = WellnessService._();
  factory WellnessService() => _i;
  WellnessService._();

  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  // ── Firestore paths ────────────────────────────────────────────────────────
  DocumentReference get _userDoc  => _db.collection('users').doc(_uid);
  CollectionReference get _notifs => _db.collection('users').doc(_uid).collection('notifications');

  // ── Point values per action ────────────────────────────────────────────────
  static const int pointsQuiz       = 20;
  static const int pointsJournal    = 15;
  static const int pointsPodcast    = 10;
  static const int pointsMusic      = 5;
  static const int pointsMindGame   = 10;
  static const int pointsAIChat     = 5;
  static const int pointsStreakBonus = 25;   // awarded every 7-day streak

  // ─────────────────────────────────────────────────────────────────────────
  // LOAD USER WELLNESS DATA
  // ─────────────────────────────────────────────────────────────────────────
  Future<WellnessData> loadData() async {
    if (_uid.isEmpty) return WellnessData.empty();
    try {
      final doc  = await _userDoc.get();
      final data = doc.data() as Map<String, dynamic>? ?? {};
      return WellnessData.fromMap(data);
    } catch (_) {
      return WellnessData.empty();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AWARD POINTS  (call this from any feature screen)
  // ─────────────────────────────────────────────────────────────────────────
  /// [action] = 'quiz' | 'journal' | 'podcast' | 'music' | 'game' | 'ai_chat'
  Future<void> awardPoints(String action) async {
    if (_uid.isEmpty) return;
    final pts = _pointsFor(action);
    if (pts == 0) return;

    final today     = _dateString(DateTime.now());
    final data      = await loadData();
    final lastDate  = data.lastActivityDate;
    final isNewDay  = lastDate != today;

    int newStreak = data.streakDays;
    bool streakBonus = false;

    if (isNewDay) {
      // Check if yesterday was active (streak continues)
      final yesterday = _dateString(DateTime.now().subtract(const Duration(days: 1)));
      newStreak = (lastDate == yesterday) ? newStreak + 1 : 1;
      if (newStreak % 7 == 0) streakBonus = true;
    }

    final totalPts = data.totalPoints + pts + (streakBonus ? pointsStreakBonus : 0);
    final score    = (totalPts.clamp(0, 100));

    // Mark today's task done
    final todayTasks = Map<String, bool>.from(data.todayTasks);
    todayTasks[action] = true;

    await _userDoc.set({
      'totalPoints':    totalPts,
      'wellnessScore':  score,
      'streakDays':     newStreak,
      'lastActivityDate': today,
      'todayTasks':     isNewDay ? {action: true} : todayTasks,
      'completedToday': (isNewDay ? 1 : (data.completedToday + 1)).clamp(0, 6),
    }, SetOptions(merge: true));

    // Push notification for the reward
    await _pushNotification(
      title: _rewardTitle(action, pts),
      body:  streakBonus
          ? '🔥 $newStreak-day streak! +$pointsStreakBonus bonus pts. Total: $totalPts pts'
          : _rewardBody(action, pts, totalPts),
      type:  'reward',
      meta:  {'action': action, 'points': pts},
    );

    if (streakBonus) {
      await _pushNotification(
        title: '🔥 Streak Milestone!',
        body:  'You\'ve been active for $newStreak days in a row. Keep it up!',
        type:  'streak',
        meta:  {'streak': newStreak},
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PUSH A NOTIFICATION  (called internally or from any screen)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _pushNotification({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? meta,
  }) async {
    if (_uid.isEmpty) return;
    await _notifs.add({
      'title':     title,
      'body':      body,
      'type':      type,
      'meta':      meta ?? {},
      'isRead':    false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Public method so any feature can push a notification
  Future<void> pushNotification({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? meta,
  }) => _pushNotification(title: title, body: body, type: type, meta: meta);

  // ─────────────────────────────────────────────────────────────────────────
  // MARK DAILY REMINDER  (call on app open if not yet sent today)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> sendDailyReminderIfNeeded() async {
    if (_uid.isEmpty) return;
    final today = _dateString(DateTime.now());
    final data  = await loadData();
    if (data.lastReminderDate == today) return;

    final hour = DateTime.now().hour;
    String title, body;
    if (hour < 12) {
      title = '🌅 Good morning!';
      body  = 'Start your day right — take your wellness quiz and write a journal entry.';
    } else if (hour < 17) {
      title = '☀️ Afternoon check-in';
      body  = 'Don\'t forget your daily tasks! Earn points and keep your streak alive.';
    } else {
      title = '🌙 Evening reminder';
      body  = 'Wind down with a mindfulness session. Your journal is waiting for you.';
    }

    await _pushNotification(title: title, body: body, type: 'reminder');
    await _userDoc.set({'lastReminderDate': today}, SetOptions(merge: true));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // REAL-TIME NOTIFICATIONS STREAM
  // ─────────────────────────────────────────────────────────────────────────
  Stream<List<AppNotification>> notificationsStream() {
    if (_uid.isEmpty) return const Stream.empty();
    return _notifs
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppNotification.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  Future<int> unreadCount() async {
    if (_uid.isEmpty) return 0;
    final snap = await _notifs.where('isRead', isEqualTo: false).count().get();
    return snap.count ?? 0;
  }

  Future<void> markAllRead() async {
    final snap = await _notifs.where('isRead', isEqualTo: false).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> markRead(String id) async {
    await _notifs.doc(id).update({'isRead': true});
  }

  Future<void> deleteNotification(String id) async {
    await _notifs.doc(id).delete();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────
  int _pointsFor(String action) {
    switch (action) {
      case 'quiz':     return pointsQuiz;
      case 'journal':  return pointsJournal;
      case 'podcast':  return pointsPodcast;
      case 'music':    return pointsMusic;
      case 'game':     return pointsMindGame;
      case 'ai_chat':  return pointsAIChat;
      default:         return 0;
    }
  }

  String _rewardTitle(String action, int pts) {
    switch (action) {
      case 'quiz':    return '🧠 Quiz Completed! +$pts pts';
      case 'journal': return '📓 Journal Written! +$pts pts';
      case 'podcast': return '🎙️ Podcast Listened! +$pts pts';
      case 'music':   return '🎵 Music Session! +$pts pts';
      case 'game':    return '🎮 Mindful Game Done! +$pts pts';
      case 'ai_chat': return '🐝 Chatted with Hive AI! +$pts pts';
      default:        return '✅ Activity Done! +$pts pts';
    }
  }

  String _rewardBody(String action, int pts, int total) {
    return 'You earned $pts points. Total wellness score: $total pts. Keep going!';
  }

  String _dateString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

class WellnessData {
  final int totalPoints;
  final int wellnessScore;
  final int streakDays;
  final int completedToday;
  final String lastActivityDate;
  final String lastReminderDate;
  final Map<String, bool> todayTasks;   // 'quiz', 'journal', etc.

  WellnessData({
    required this.totalPoints,
    required this.wellnessScore,
    required this.streakDays,
    required this.completedToday,
    required this.lastActivityDate,
    required this.lastReminderDate,
    required this.todayTasks,
  });

  factory WellnessData.empty() => WellnessData(
    totalPoints: 0, wellnessScore: 0, streakDays: 0,
    completedToday: 0, lastActivityDate: '', lastReminderDate: '',
    todayTasks: {},
  );

  factory WellnessData.fromMap(Map<String, dynamic> m) {
    final rawTasks = m['todayTasks'] as Map<String, dynamic>? ?? {};
    return WellnessData(
      totalPoints:      (m['totalPoints'] as num?)?.toInt()     ?? 0,
      wellnessScore:    (m['wellnessScore'] as num?)?.toInt()   ?? 0,
      streakDays:       (m['streakDays'] as num?)?.toInt()      ?? 0,
      completedToday:   (m['completedToday'] as num?)?.toInt()  ?? 0,
      lastActivityDate: m['lastActivityDate'] as String?         ?? '',
      lastReminderDate: m['lastReminderDate'] as String?         ?? '',
      todayTasks:       rawTasks.map((k, v) => MapEntry(k, v as bool? ?? false)),
    );
  }

  bool taskDone(String key) => todayTasks[key] == true;
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;   // 'reward' | 'reminder' | 'streak' | 'system' | 'booking'
  final bool isRead;
  final DateTime? createdAt;
  final Map<String, dynamic> meta;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.meta,
    this.createdAt,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> m) {
    return AppNotification(
      id:        id,
      title:     m['title'] as String? ?? '',
      body:      m['body']  as String? ?? '',
      type:      m['type']  as String? ?? 'system',
      isRead:    m['isRead'] as bool?   ?? false,
      meta:      m['meta']  as Map<String, dynamic>? ?? {},
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}