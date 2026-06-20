import 'package:flutter/material.dart';

class Playlist {
  final String title;
  final String subtitle;
  final String songs;
  final String duration;
  final Color color;
  final String url;

  Playlist({
    required this.title,
    required this.subtitle,
    required this.songs,
    required this.duration,
    required this.color,
    required this.url,
  });
}