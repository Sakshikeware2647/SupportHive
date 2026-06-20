class Music {
  final String title;
  final String category;
  final String duration;
  final String source; // asset OR url
  final bool isAsset;

  Music({
    required this.title,
    required this.category,
    required this.duration,
    required this.source,
    required this.isAsset,
  });

  String get subtitle => '$category • $duration';

  factory Music.fromJson(Map<String, dynamic> json) {
    return Music(
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      duration: json['duration'] ?? '',
      source: json['source'] ?? '',
      isAsset: json['isAsset'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'category': category,
      'duration': duration,
      'source': source,
      'isAsset': isAsset,
    };
  }
}