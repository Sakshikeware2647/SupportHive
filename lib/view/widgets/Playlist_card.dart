import 'package:flutter/material.dart';
import 'package:supporthive1/model/Playlist_model.dart';
import 'package:supporthive1/service/audio_service.dart'; // 🔥 added

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onPlay;

  const PlaylistCard({
    super.key,
    required this.playlist,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AudioService.currentUrlNotifier,
      builder: (context, currentUrl, _) {
        final isThisTrack = currentUrl == playlist.url;
        return StreamBuilder<bool>(
          stream: AudioService.playingStream,
          initialData: AudioService.isPlaying,
          builder: (context, snapshot) {
            final isPlayingNow = isThisTrack && (snapshot.data ?? false);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: isThisTrack
                    ? Border.all(color: playlist.color, width: 1.5)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: playlist.color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isPlayingNow ? Icons.graphic_eq : Icons.music_note,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlist.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          playlist.subtitle,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text("🎵 ${playlist.songs}", style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 10),
                            Text("⏱ ${playlist.duration}", style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF3D7A2A),
                    child: IconButton(
                      icon: Icon(
                        isPlayingNow ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        if (isPlayingNow) {
                          AudioService.pause();
                        } else {
                          onPlay();
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}