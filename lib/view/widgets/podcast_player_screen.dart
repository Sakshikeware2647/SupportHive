import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../model/podcast.dart';
import '../../service/audio_service.dart';
import '../../service/podcast_service.dart';
import 'podcast_card.dart';

typedef ProgressCallback = void Function(
    String podcastId, int positionSeconds, int durationSeconds);

class PodcastPlayerScreen extends StatefulWidget {
  final Podcast podcast;
  final ProgressCallback? onProgressUpdate;

  const PodcastPlayerScreen({
    super.key,
    required this.podcast,
    this.onProgressUpdate,
  });

  @override
  State<PodcastPlayerScreen> createState() => _PodcastPlayerScreenState();
}

class _PodcastPlayerScreenState extends State<PodcastPlayerScreen> {
  static const Color _brandGreen = Color(0xFF4A6741);

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isLoading = true;
  String? _error;
  double _speed = 1.0;
  bool _isLiked = false;

  List<Podcast> _recommended = [];
  Duration _savedProgress = Duration.zero;

  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<ProcessingState>? _stateSub;

  @override
  void initState() {
    super.initState();
    _initPlayer();
    _loadExtras();
  }

  // ── Player init ─────────────────────────────────────────────────────────────

  Future<void> _initPlayer() async {
    final url = widget.podcast.videoUrl.isNotEmpty
        ? widget.podcast.videoUrl
        : widget.podcast.audioUrl;

    if (url.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'No playable media found for this podcast.';
        });
      }
      return;
    }

    try {
      _savedProgress =
          await PodcastService.instance.loadProgress(widget.podcast.id);

      final isAsset = url.startsWith('assets/');
      await AudioService.play(url, isAsset: isAsset);

      if (_savedProgress > Duration.zero) {
        await AudioService.seekTo(_savedProgress);
      }

      _durationSub = AudioService.durationStream.listen((d) {
        if (d != null && mounted) setState(() => _duration = d);
      });

      _positionSub = AudioService.positionStream.listen((p) {
        if (!mounted) return;
        setState(() => _position = p);
        if (p.inSeconds % 5 == 0 && _duration.inSeconds > 0) {
          widget.onProgressUpdate
              ?.call(widget.podcast.id, p.inSeconds, _duration.inSeconds);
        }
      });

      _stateSub = AudioService.processingStateStream.listen((state) {
        if (state == ProcessingState.completed && mounted) {
          PodcastService.instance.clearProgress(widget.podcast.id);
          widget.onProgressUpdate
              ?.call(widget.podcast.id, 0, _duration.inSeconds);
        }
      });

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Playback failed: $e';
        });
      }
    }
  }

  // ── Extras ──────────────────────────────────────────────────────────────────

  Future<void> _loadExtras() async {
    try {
      final results = await Future.wait([
        PodcastService.instance.fetchRecommended(widget.podcast),
        PodcastService.instance.fetchLikedIds(),
      ]);
      if (!mounted) return;
      final liked = results[1] as Set<String>;
      setState(() {
        _recommended = results[0] as List<Podcast>;
        _isLiked = liked.contains(widget.podcast.id);
      });
    } catch (_) {}
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _changeSpeed() {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final idx = speeds.indexOf(_speed);
    final next = speeds[(idx + 1) % speeds.length];
    setState(() => _speed = next);
    AudioService.setSpeed(next);
  }

  Future<void> _toggleLike() async {
    final newLiked = !_isLiked;
    setState(() => _isLiked = newLiked);
    await PodcastService.instance.toggleLike(widget.podcast.id, newLiked);
  }

  // ── Dispose ─────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _stateSub?.cancel();

    if (_duration.inSeconds > 0 && _position.inSeconds > 0) {
      PodcastService.instance
          .saveProgress(widget.podcast.id, _position);
    }
    super.dispose();
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: _error != null
            ? _buildError()
            : _isLoading
                ? _buildLoader()
                : _buildPlayer(),
      ),
    );
  }

  Widget _buildLoader() {
    return const Center(
        child: CircularProgressIndicator(color: _brandGreen));
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.red, size: 56),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Go Back',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildAppBar()),
        SliverToBoxAdapter(child: _buildCoverArt()),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(child: _buildTitleBlock()),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverToBoxAdapter(child: _buildProgressBar()),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(child: _buildControls()),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(child: _buildSpeedAndLike()),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        if (_savedProgress > Duration.zero &&
            _savedProgress.inSeconds > 5)
          SliverToBoxAdapter(child: _buildResumeChip()),
        // ── "Create Podcast" button REMOVED — admin-only via admin panel ──
        if (_recommended.isNotEmpty) ...[
          SliverToBoxAdapter(child: _buildRecommendedHeader()),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: PodcastCard(
                  key: ValueKey(_recommended[i].id),
                  podcast: _recommended[i],
                  isUnlocked: !_recommended[i].isPremium,
                  onTap: () => _navigateToRecommended(_recommended[i]),
                ),
              ),
              childCount: _recommended.length,
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  void _navigateToRecommended(Podcast p) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PodcastPlayerScreen(
          podcast: p,
          onProgressUpdate: widget.onProgressUpdate,
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Now Playing',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildCoverArt() {
    return Center(
      child: Container(
        width: 200,
        height: 200,
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4A6741), Color(0xFF7BAD6A)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A6741).withValues(alpha: 0.4),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: widget.podcast.imageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(
                  widget.podcast.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.mic_rounded,
                    size: 80,
                    color: Colors.white54,
                  ),
                ),
              )
            : Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.mic_rounded,
                      size: 80, color: Colors.white54),
                  if (widget.podcast.isPremium)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildTitleBlock() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            widget.podcast.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, height: 1.3),
          ),
          const SizedBox(height: 4),
          Text(widget.podcast.author,
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
          if (widget.podcast.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              widget.podcast.description,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 12, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final maxSec = _duration.inSeconds.toDouble();
    final val = _position.inSeconds
        .toDouble()
        .clamp(0.0, maxSec > 0 ? maxSec : 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: _brandGreen,
              thumbColor: _brandGreen,
              inactiveTrackColor: Colors.grey.shade300,
            ),
            child: Slider(
              value: val,
              max: maxSec > 0 ? maxSec : 1.0,
              onChanged: maxSec > 0
                  ? (v) =>
                      AudioService.seekTo(Duration(seconds: v.toInt()))
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_fmt(_position),
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(_fmt(_duration),
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return StreamBuilder<bool>(
      stream: AudioService.playingStream,
      builder: (_, snap) {
        final playing = snap.data ?? false;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _controlBtn(Icons.replay_10_rounded, 28,
                () => AudioService.skipBackward(seconds: 10)),
            const SizedBox(width: 24),
            GestureDetector(
              onTap: () => playing
                  ? AudioService.pause()
                  : AudioService.player.play(),
              child: Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: _brandGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x554A6741),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
            const SizedBox(width: 24),
            _controlBtn(Icons.forward_10_rounded, 28,
                () => AudioService.skipForward(seconds: 10)),
          ],
        );
      },
    );
  }

  Widget _controlBtn(IconData icon, double size, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, size: size),
      color: Colors.grey.shade700,
      onPressed: onTap,
    );
  }

  Widget _buildSpeedAndLike() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _changeSpeed,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.speed_rounded,
                      size: 16, color: _brandGreen),
                  const SizedBox(width: 6),
                  Text(
                    '${_speed}x',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _brandGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: _toggleLike,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Icon(
                _isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: _isLiked ? Colors.red.shade400 : Colors.grey,
                size: 22,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share coming soon!'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Icon(Icons.share_rounded,
                  color: Colors.grey, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeChip() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _brandGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _brandGreen.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.history_rounded,
                color: _brandGreen, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Resumed from ${_fmt(_savedProgress)}',
                style: const TextStyle(
                  color: _brandGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () => AudioService.seekTo(Duration.zero),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
              ),
              child: const Text('Restart',
                  style:
                      TextStyle(color: _brandGreen, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Text(
        'You Might Also Like',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}