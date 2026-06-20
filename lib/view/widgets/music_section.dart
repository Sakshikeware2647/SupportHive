import 'package:flutter/material.dart';
import 'package:supporthive1/model/music.dart';
import 'package:supporthive1/service/audio_service.dart';
import 'dart:async';
import 'package:supporthive1/view/widgets/music_library_screen.dart';

class MusicSection extends StatefulWidget {
  final List<Music> musicList;
  final Function(String) onPlayMusic;

  const MusicSection({
    super.key,
    required this.musicList,
    required this.onPlayMusic,
  });

  @override
  State<MusicSection> createState() => _MusicSectionState();
}

class _MusicSectionState extends State<MusicSection> {
  int _currentPage = 0;
  Timer? _timer;
  StreamSubscription<bool>? _playingSub; // 🔥 added
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _startAutoScroll();

    // 🔥 Pause the carousel while a track is playing, resume when it stops/pauses.
    _playingSub = AudioService.playingStream.listen((playing) {
      if (!mounted) return;
      if (playing) {
        _timer?.cancel();
        _timer = null;
      } else {
        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _playingSub?.cancel(); // 🔥 added
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    if (_timer != null && _timer!.isActive) return; // 🔥 guard against duplicates
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || widget.musicList.isEmpty) return;

      int nextPage = _currentPage + 1;
      if (nextPage >= widget.musicList.length) nextPage = 0;

      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink.shade100, Colors.purple.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.music_note, color: Colors.purple),
                  SizedBox(width: 8),
                  Text(
                    'Relaxing Music',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () {
                  AudioService.stop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MusicLibraryScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 260,
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              children: widget.musicList.map(_buildMusicCard).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.musicList.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.purple
                        : Colors.purple.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 Card now listens to AudioService so it always shows true state.
  Widget _buildMusicCard(Music music) {
    return ValueListenableBuilder<String>(
      valueListenable: AudioService.currentUrlNotifier,
      builder: (context, currentUrl, _) {
        final isThisTrack = currentUrl == music.source;
        return StreamBuilder<bool>(
          stream: AudioService.playingStream,
          initialData: AudioService.isPlaying,
          builder: (context, snapshot) {
            final isPlayingNow = isThisTrack && (snapshot.data ?? false);
            return _musicCardContent(music, isThisTrack, isPlayingNow);
          },
        );
      },
    );
  }

  Widget _musicCardContent(Music music, bool isThisTrack, bool isPlayingNow) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isThisTrack
            ? Border.all(color: const Color(0xFF4A6741), width: 2)
            : null,
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A6741),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPlayingNow ? Icons.graphic_eq : Icons.music_note,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              music.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Text(
              music.subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),

            // 🔥 single toggle button replaces the old stacked Play + Pause buttons
            ElevatedButton.icon(
              onPressed: () {
                if (isPlayingNow) {
                  AudioService.pause();
                } else {
                  AudioService.play(music.source, isAsset: music.isAsset);
                }
              },
              icon: Icon(isPlayingNow ? Icons.pause : Icons.play_arrow, size: 18),
              label: Text(isPlayingNow ? 'Pause' : 'Play'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A6741),
                foregroundColor: Colors.white,
                minimumSize: const Size(110, 40),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}