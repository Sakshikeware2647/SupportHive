class Game {
  final String title;
  final String category;
  final String description;
  final String duration;
  final String difficulty;
  final int likes;
  final int streakPoints;
  final int level;

  Game({
    required this.title,
    required this.category,
    required this.description,
    required this.duration,
    required this.difficulty,
    required this.likes,
    required this.streakPoints,
    required this.level,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      duration: json['duration'] ?? '',
      difficulty: json['difficulty'] ?? 'Easy',
      likes: json['likes'] ?? 0,
      streakPoints: json['streakPoints'] ?? 0,
      level: json['level'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'category': category,
      'description': description,
      'duration': duration,
      'difficulty': difficulty,
      'likes': likes,
      'streakPoints': streakPoints,
      'level': level,
    };
  }
}