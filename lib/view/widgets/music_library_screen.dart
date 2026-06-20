import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart'; // 🔥 added — for ProcessingState
import 'dart:async'; // 🔥 added — for StreamSubscription
import 'package:supporthive1/model/Playlist_model.dart';
import 'package:supporthive1/model/music.dart';
import 'package:supporthive1/service/audio_service.dart';
import 'package:supporthive1/view/widgets/Playlist_card.dart';

class MusicLibraryScreen extends StatefulWidget {
  const MusicLibraryScreen({super.key});

  @override
  State<MusicLibraryScreen> createState() => _MusicLibraryScreenState();
}

class _MusicLibraryScreenState extends State<MusicLibraryScreen> {
  int selectedTab = 0;
  double _volume = 1.0; // 🔥 added
  StreamSubscription<ProcessingState>? _completionSub; // 🔥 added

  @override
  void initState() {
    super.initState();
    _volume = AudioService.volume; // 🔥 added

    // 🔥 added — when a track finishes, auto-play the next one if enabled
    _completionSub = AudioService.processingStateStream.listen((state) {
      if (state == ProcessingState.completed && AudioService.autoPlayEnabled) {
        _playNextTrack();
      }
    });
  }

  @override
  void dispose() {
    AudioService.stop(); // 🔥 stop when leaving screen
    _completionSub?.cancel(); // 🔥 added
    super.dispose();
  }

  // 🔥 added — finds the currently playing song in musicList and plays the next one
  void _playNextTrack() {
    final currentUrl = AudioService.currentUrl;
    final index = musicList.indexWhere((m) => m.source == currentUrl);
    if (index == -1) return;
    final nextIndex = (index + 1) % musicList.length;
    final next = musicList[nextIndex];
    AudioService.play(next.source, isAsset: next.isAsset);
  }

  // 🎵 SONG LIST
  final List<Music> musicList = [
    Music(
      title: 'Nature Sounds',
      category: 'Nature',
      duration: '03:02',
      source: "assets/audios/nature_sound.mp3",
      isAsset: true,
    ),
    Music(
      title: 'Relaxation and Stress Relief',
      category: 'Relaxation',
      duration: '15:15',
      source: "assets/audios/deep_relaxation_stress_relief.mp3",
      isAsset: true,
    ),
    Music(
      title: 'Positive Energy',
      category: 'Nature',
      duration: '03:04',
      source: "assets/audios/piano_music_positive_energy.mp3",
      isAsset: true,
    ),
    Music(
      title: 'Ocean Waves',
      category: 'Waves',
      duration: '03:01',
      source: "assets/audios/meditation_music_with_ocean_waves.mp3",
      isAsset: true,
    ),
  ];

  // 🎧 PLAYLIST LIST
  final List<Playlist> playlists = [
    Playlist(
      title: "Calm Meditation",
      subtitle: "Peaceful music",
      songs: "12 songs",
      duration: "1h 25m",
      color: Colors.purple,
      url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
    ),
    Playlist(
      title: "Deep Sleep",
      subtitle: "Sleep sounds",
      songs: "10 songs",
      duration: "2h 15m",
      color: Colors.blue,
      url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
    ),
    Playlist(
      title: "Stress Relief",
      subtitle: "Relax your mind",
      songs: "8 songs",
      duration: "45m",
      color: Colors.green,
      url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 10),
          _buildTabs(),
          const SizedBox(height: 10),
          Expanded(
            child: selectedTab == 0 ? _buildPlaylistView() : _buildSongsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: playlists.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              "All Playlists",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          );
        }
        final playlist = playlists[index - 1];
        return PlaylistCard(
          playlist: playlist,
          onPlay: () {
            AudioService.play(playlist.url);
          },
        );
      },
    );
  }

  Widget _buildSongsView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: musicList.length,
      itemBuilder: (context, index) {
        final music = musicList[index];
        return ValueListenableBuilder<String>(
          valueListenable: AudioService.currentUrlNotifier,
          builder: (context, currentUrl, _) {
            final isThisTrack = currentUrl == music.source;
            return StreamBuilder<bool>(
              stream: AudioService.playingStream,
              initialData: AudioService.isPlaying,
              builder: (context, snapshot) {
                final isPlayingNow = isThisTrack && (snapshot.data ?? false);
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isThisTrack
                        ? const BorderSide(color: Color(0xFF3D7A2A), width: 1.2)
                        : BorderSide.none,
                  ),
                  color: isThisTrack ? const Color(0xFF3D7A2A).withOpacity(0.07) : null,
                  child: ListTile(
                    leading: Icon(
                      isPlayingNow ? Icons.graphic_eq : Icons.music_note,
                      color: isThisTrack ? const Color(0xFF3D7A2A) : null,
                    ),
                    title: Text(music.title),
                    subtitle: Text(music.subtitle),
                    trailing: IconButton(
                      icon: Icon(
                        isPlayingNow ? Icons.pause_circle_filled : Icons.play_circle_fill,
                        color: const Color(0xFF3D7A2A),
                        size: 32,
                      ),
                      onPressed: () {
                        if (isPlayingNow) {
                          AudioService.pause();
                        } else {
                          AudioService.play(music.source, isAsset: music.isAsset);
                        }
                      },
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF3D7A2A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Spacer(),
              // 🔥 settings icon is now wired up
              IconButton(
                onPressed: _showSettingsSheet,
                icon: const Icon(Icons.settings, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Music Library",
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Discover wellness through music",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // 🔥 NEW — settings bottom sheet: volume + autoplay
  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    "Playback Settings",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Icon(
                        _volume == 0 ? Icons.volume_off : Icons.volume_up,
                        color: const Color(0xFF3D7A2A),
                      ),
                      const SizedBox(width: 8),
                      const Text("Volume", style: TextStyle(fontSize: 15)),
                    ],
                  ),
                  Slider(
                    value: _volume,
                    min: 0.0,
                    max: 1.0,
                    activeColor: const Color(0xFF3D7A2A),
                    inactiveColor: Colors.grey.shade300,
                    onChanged: (value) {
                      setSheetState(() => _volume = value);
                      setState(() => _volume = value);
                      AudioService.setVolume(value);
                    },
                  ),

                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.repeat, color: Color(0xFF3D7A2A)),
                          SizedBox(width: 8),
                          Text("Auto-play next track", style: TextStyle(fontSize: 15)),
                        ],
                      ),
                      Switch(
                        value: AudioService.autoPlayEnabled,
                        activeColor: const Color(0xFF3D7A2A),
                        onChanged: (value) {
                          setSheetState(() => AudioService.autoPlayEnabled = value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _tab("Playlists", 0),
          _tab("All Songs", 1),
          _tab("Library", 2),
        ],
      ),
    );
  }

  Widget _tab(String text, int index) {
    final isSelected = selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(color: isSelected ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}