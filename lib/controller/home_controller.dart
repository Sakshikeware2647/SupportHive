import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supporthive1/model/activity.dart';
import 'package:supporthive1/model/music.dart';
import 'package:supporthive1/model/podcast.dart';
import 'package:supporthive1/model/quote.dart';
import 'package:supporthive1/view/widgets/podcast_player_screen.dart';
import 'package:supporthive1/view/widgets/wellness_status_screen.dart';

class HomeController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Tab index ─────────────────────────────────────────────────────────────
  int _selectedTabIndex = 0;
  int get selectedTabIndex => _selectedTabIndex;

  void setTabIndex(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  // ── User data ─────────────────────────────────────────────────────────────
  String _userName = '';
  String get userName => _userName;

  String get _uid => _auth.currentUser?.uid ?? '';

  // ── Dynamic data from Firestore ───────────────────────────────────────────
  List<Podcast> _podcasts = [];
  List<Podcast> get podcasts => _podcasts;

  List<Music> _musicList = [];
  List<Music> get musicList => _musicList;

  List<Activity> _activities = [];
  List<Activity> get activities => _activities;

  Quote _dailyQuote = Quote(text: '"Loading..."', author: '');
  Quote get dailyQuote => _dailyQuote;

  bool isLoading = true;

  HomeController() {
    _loadAll();
  }

  // ── Load all data from Firestore ──────────────────────────────────────────
  Future<void> _loadAll() async {
    isLoading = true;
    notifyListeners();
    try {
      await Future.wait([
        _loadUserName(),
        _loadPodcasts(),
        _loadMusic(),
        _loadActivities(),
        _loadDailyQuote(),
      ]);
    } catch (e) {
      debugPrint('HomeController load error: $e');
      _loadFallbackData();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserName() async {
    if (_uid.isEmpty) return;
    final doc = await _db.collection('users').doc(_uid).get();
    final data = doc.data();
    if (data != null) {
      _userName = (data['name'] as String? ?? '').split(' ').first;
    }
  }

  Future<void> _loadPodcasts() async {
    final snap = await _db.collection('podcasts').orderBy('order').get();
    if (snap.docs.isEmpty) {
      _podcasts = _fallbackPodcasts();
      return;
    }
    _podcasts = snap.docs.map((d) {
      final data = d.data();
      return Podcast(
        title: data['title'] ?? '',
        author: data['author'] ?? '',
        category: data['category'] ?? '',
        duration: data['duration'] ?? '',
        audioUrl: data['audioUrl'] ?? '',
        isNew: data['isNew'] ?? false,
      );
    }).toList();
  }

  Future<void> _loadMusic() async {
    final snap = await _db.collection('music').orderBy('order').get();
    if (snap.docs.isEmpty) {
      _musicList = _fallbackMusic();
      return;
    }
    _musicList = snap.docs.map((d) {
      final data = d.data();
      return Music(
        title: data['title'] ?? '',
        category: data['category'] ?? '',
        duration: data['duration'] ?? '',
        source: data['source'] ?? '',
        isAsset: data['isAsset'] ?? true,
      );
    }).toList();
  }

  Future<void> _loadActivities() async {
    final snap = await _db.collection('activities').orderBy('order').get();
    if (snap.docs.isEmpty) {
      _activities = _fallbackActivities();
      return;
    }
    _activities = snap.docs.map((d) {
      final data = d.data();
      return Activity(
        title: data['title'] ?? '',
        subtitle: data['subtitle'] ?? '',
        icon: _iconFromName(data['icon'] ?? ''),
        buttonText: data['buttonText'] ?? 'Start',
      );
    }).toList();
  }

  Future<void> _loadDailyQuote() async {
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year, 1, 1))
        .inDays;
    final snap = await _db.collection('quotes').get();
    if (snap.docs.isEmpty) {
      _dailyQuote = _fallbackQuote();
      return;
    }
    final index = dayOfYear % snap.docs.length;
    final data = snap.docs[index].data();
    _dailyQuote = Quote(
      text: data['text'] ?? '',
      author: data['author'] ?? '',
    );
  }

  // ── Refresh ───────────────────────────────────────────────────────────────
  Future<void> refresh() => _loadAll();

  // ── Add podcast (called from CreatePodcastScreen) ─────────────────────────
  // Updates local list instantly for responsive UI, then persists to Firestore
  Future<void> addPodcast(Podcast podcast) async {
    _podcasts = [podcast, ..._podcasts];
    notifyListeners();
    try {
      await _db.collection('podcasts').add({
        'title': podcast.title,
        'author': podcast.author,
        'category': podcast.category,
        'duration': podcast.duration,
        'audioUrl': podcast.audioUrl,
        'isNew': podcast.isNew,
        'order': DateTime.now().millisecondsSinceEpoch,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('addPodcast Firestore error: $e');
      // Local list already updated — podcast visible for this session
    }
  }

  // ── Add music (called from any create music screen) ───────────────────────
  Future<void> addMusic(Music music) async {
    _musicList = [music, ..._musicList];
    notifyListeners();
    try {
      await _db.collection('music').add({
        'title': music.title,
        'category': music.category,
        'duration': music.duration,
        'source': music.source,
        'isAsset': music.isAsset,
        'order': DateTime.now().millisecondsSinceEpoch,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('addMusic Firestore error: $e');
    }
  }

  // ── Add activity ──────────────────────────────────────────────────────────
  Future<void> addActivity(Activity activity) async {
    _activities = [..._activities, activity];
    notifyListeners();
    try {
      await _db.collection('activities').add({
        'title': activity.title,
        'subtitle': activity.subtitle,
        'icon': _iconNameFromData(activity.icon),
        'buttonText': activity.buttonText,
        'order': DateTime.now().millisecondsSinceEpoch,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('addActivity Firestore error: $e');
    }
  }

  // ── Wellness stats (for WellnessStatusScreen) ─────────────────────────────
  Future<Map<String, dynamic>> getWellnessStats() async {
    if (_uid.isEmpty) return {'dailyCheckIns': 0, 'wellnessScore': '0%'};
    try {
      final doc = await _db.collection('users').doc(_uid).get();
      final data = doc.data() ?? {};
      return {
        'dailyCheckIns': data['dailyCheckIns'] ?? 0,
        'activeChats': data['activeChats'] ?? 0,
        'wellnessScore': data['wellnessScore'] ?? '0%',
      };
    } catch (e) {
      return {'dailyCheckIns': 0, 'activeChats': 0, 'wellnessScore': '0%'};
    }
  }

  // ── Fallbacks (used if Firestore empty or offline) ────────────────────────
  void _loadFallbackData() {
    _podcasts = _fallbackPodcasts();
    _musicList = _fallbackMusic();
    _activities = _fallbackActivities();
    _dailyQuote = _fallbackQuote();
  }

  List<Podcast> _fallbackPodcasts() => [
        Podcast(
          title: 'The Anxiety Solution',
          author: 'Michael Roberts',
          category: 'Mental Health',
          duration: '11:00',
          audioUrl:
              'assets/audios/Secret_To_Mastering_Your_Emotions_Dr_Sweta_Adatia_Raj_Shama_podcast.mp3',
          isNew: true,
        ),
      ];

  List<Music> _fallbackMusic() => [
        Music(
          title: 'Nature Sounds',
          category: 'Nature',
          duration: '03:02',
          source: 'assets/audios/nature_sound.mp3',
          isAsset: true,
        ),
        Music(
          title: 'Relaxation & Stress Relief',
          category: 'Relaxation',
          duration: '15:15',
          source: 'assets/audios/deep_relaxation_stress_relief.mp3',
          isAsset: true,
        ),
        Music(
          title: 'Positive Energy',
          category: 'Nature',
          duration: '03:04',
          source: 'assets/audios/piano_music_positive_energy.mp3',
          isAsset: true,
        ),
      ];

  List<Activity> _fallbackActivities() => [
        Activity(
          title: 'Morning Check-in',
          subtitle: "Share how you're feeling today",
          icon: Icons.wb_sunny,
          buttonText: 'Start',
        ),
        Activity(
          title: 'Mindfulness Session',
          subtitle: '15-minute guided meditation',
          icon: Icons.self_improvement,
          buttonText: 'Join',
        ),
        Activity(
          title: 'Connect with Support',
          subtitle: 'Chat with your wellness guide',
          icon: Icons.chat,
          buttonText: 'Chat',
        ),
      ];

  Quote _fallbackQuote() => Quote(
        text:
            '"Small steps in the right direction can turn out to be the biggest steps of your life."',
        author: 'Unknown',
      );

  // ── Icon helpers ──────────────────────────────────────────────────────────
  IconData _iconFromName(String name) {
    switch (name) {
      case 'wb_sunny':         return Icons.wb_sunny;
      case 'self_improvement': return Icons.self_improvement;
      case 'chat':             return Icons.chat;
      case 'fitness_center':  return Icons.fitness_center;
      case 'book':             return Icons.book;
      case 'favorite':         return Icons.favorite;
      case 'music_note':       return Icons.music_note;
      default:                 return Icons.star;
    }
  }

  String _iconNameFromData(IconData icon) {
    if (icon == Icons.wb_sunny)         return 'wb_sunny';
    if (icon == Icons.self_improvement) return 'self_improvement';
    if (icon == Icons.chat)             return 'chat';
    if (icon == Icons.fitness_center)   return 'fitness_center';
    if (icon == Icons.book)             return 'book';
    if (icon == Icons.favorite)         return 'favorite';
    if (icon == Icons.music_note)       return 'music_note';
    return 'star';
  }

  // ── Navigation actions ────────────────────────────────────────────────────
  void onOpenDiary() {}
  void onTakeQuiz() {}

  void onCheckWellnessStatus(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WellnessStatusScreen()),
    );
  }

  void onPlayMusic(String musicTitle) {}

  void onListenPodcast(BuildContext context, Podcast podcast) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PodcastPlayerScreen(podcast: podcast),
      ),
    );
  }

  void onStartActivity(String activityTitle) {}
}