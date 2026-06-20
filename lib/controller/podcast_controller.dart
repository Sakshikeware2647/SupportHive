import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart'; // 🔥 added
import 'package:just_audio/just_audio.dart'; // 🔥 added
import '../model/podcast.dart';
import '../service/audio_service.dart';
import '../service/firestore_service.dart';
// 🔥 removed: import '../service/cloudinary_service.dart';

enum PodcastStatus { idle, loading, success, error }

/// Manages all podcast-related state and business logic.
/// Consumed via [ChangeNotifierProvider] in the widget tree.
class PodcastController extends ChangeNotifier {
  // ── Dependencies ────────────────────────────────────────────────────────────
  final FirestoreService _firestoreService = FirestoreService.instance;

  static const List<String> _videoExtensions = ['mp4', 'mov', 'avi', 'mkv'];

  // ── State ───────────────────────────────────────────────────────────────────
  List<Podcast> _podcasts = [];
  List<Podcast> get podcasts => List.unmodifiable(_podcasts);

  Podcast? _currentPodcast;
  Podcast? get currentPodcast => _currentPodcast;

  PodcastStatus _status = PodcastStatus.idle;
  PodcastStatus get status => _status;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  double _uploadProgress = 0.0;
  double get uploadProgress => _uploadProgress;

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  // ── Firestore live stream ───────────────────────────────────────────────────

  void startListening() {
    _status = PodcastStatus.loading;
    notifyListeners();

    _firestoreService.podcastsStream().listen(
      (list) {
        _podcasts = list;
        _status = PodcastStatus.success;
        notifyListeners();
      },
      onError: (Object e) {
        _setError(e.toString());
      },
    );
  }

  // ── Playback ────────────────────────────────────────────────────────────────

  Future<void> playPodcast(Podcast podcast) async {
    try {
      _currentPodcast = podcast;
      notifyListeners();

      final url = podcast.videoUrl.isNotEmpty
          ? podcast.videoUrl
          : podcast.audioUrl;
      if (url.isEmpty) throw Exception('No playable URL for this podcast.');

      await AudioService.play(url);

      if (podcast.id.isNotEmpty) {
        _firestoreService.incrementPlayCount(podcast.id).catchError((_) {});
      }
    } catch (e) {
      _setError('Playback error: $e');
    }
  }

  Future<void> stopPlayback() async {
    await AudioService.stop();
    _currentPodcast = null;
    notifyListeners();
  }

  // ── Media duration ───────────────────────────────────────────────────────────
  // 🔥 NEW — reads duration locally before upload (Firebase Storage doesn't
  // provide this the way Cloudinary did).
  Future<int> _getDurationSeconds(File file) async {
    final tempPlayer = AudioPlayer();
    try {
      final duration = await tempPlayer.setFilePath(file.path);
      return duration?.inSeconds ?? 0;
    } catch (e) {
      debugPrint('Could not read media duration: $e');
      return 0;
    } finally {
      await tempPlayer.dispose();
    }
  }

  // ── Firebase Storage upload ──────────────────────────────────────────────────
  // 🔥 NEW — replaces CloudinaryService.uploadMedia
  Future<String> _uploadToFirebaseStorage(
    File file,
    void Function(double progress) onProgress,
  ) async {
    final ext = file.path.split('.').last.toLowerCase();
    final fileName = 'podcast_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = FirebaseStorage.instance.ref().child('podcasts').child(fileName);

    final uploadTask = ref.putFile(file);

    final subscription = uploadTask.snapshotEvents.listen((snapshot) {
      if (snapshot.totalBytes > 0) {
        onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
      }
    });

    try {
      final completedSnapshot = await uploadTask;
      return await completedSnapshot.ref.getDownloadURL();
    } finally {
      await subscription.cancel();
    }
  }

  // ── Create podcast ──────────────────────────────────────────────────────────

  /// Uploads [mediaFile] to Firebase Storage, then saves podcast metadata to Firestore.
  /// Returns `true` on success, `false` on failure.
  Future<bool> createPodcast({
    required String title,
    required String author,
    required String category,
    required String description,
    required File mediaFile,
    String imageUrl = '',
  }) async {
    if (title.trim().isEmpty ||
        author.trim().isEmpty ||
        category.trim().isEmpty) {
      _setError('Title, author, and category are required.');
      return false;
    }

    _isUploading = true;
    _uploadProgress = 0.0;
    _status = PodcastStatus.loading;
    notifyListeners();

    try {
      final ext = mediaFile.path.split('.').last.toLowerCase();
      final isVideo = _videoExtensions.contains(ext);

      // 1. Read duration locally
      final durationSeconds = await _getDurationSeconds(mediaFile);
      final durationStr = _formatDuration(durationSeconds);

      // 2. Upload media to Firebase Storage
      final downloadUrl = await _uploadToFirebaseStorage(
        mediaFile,
        (p) {
          _uploadProgress = p;
          notifyListeners();
        },
      );

      // 3. Build podcast model
      final podcast = Podcast(
        id: '', // Firestore auto-generates
        title: title.trim(),
        author: author.trim(),
        authorId: '', // FirestoreService fills from FirebaseAuth
        category: category,
        duration: durationStr,
        audioUrl: isVideo ? '' : downloadUrl,
        videoUrl: isVideo ? downloadUrl : '',
        imageUrl: imageUrl,
        description: description.trim(),
        isNew: true,
        createdAt: DateTime.now(),
      );

      // 4. Persist to Firestore
      await _firestoreService.addPodcast(podcast);

      _isUploading = false;
      _status = PodcastStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _isUploading = false;
      _setError('Upload failed: $e');
      return false;
    }
  }

  /// Deletes a podcast from Firestore.
  Future<bool> deletePodcast(String id) async {
    try {
      await _firestoreService.deletePodcast(id);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _setError(String message) {
    _errorMessage = message;
    _status = PodcastStatus.error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    if (_status == PodcastStatus.error) {
      _status = PodcastStatus.idle;
    }
    notifyListeners();
  }

  static String _formatDuration(int seconds) {
    if (seconds <= 0) return '00:00';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    // AudioService is a global singleton — do NOT dispose here.
    super.dispose();
  }
}