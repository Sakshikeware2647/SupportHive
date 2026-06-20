import 'package:cloud_firestore/cloud_firestore.dart';

class Podcast {
  final String id;
  final String title;
  final String author;
  final String authorId;
  final String category;
  final String duration;
  final String audioUrl;
  final String videoUrl;
  final String imageUrl;
  final String description;
  final bool isNew;
  final bool isPremium;
  final double price;
  final DateTime createdAt;
  final int playCount;
  final int likeCount;
  final List<String> tags;

  Podcast({
    this.id = '',
    required this.title,
    required this.author,
    this.authorId = '',
    required this.category,
    required this.duration,
    required this.audioUrl,
    this.videoUrl = '',
    this.imageUrl = '',
    this.description = '',
    this.isNew = false,
    this.isPremium = false,
    this.price = 0,
    DateTime? createdAt,
    this.playCount = 0,
    this.likeCount = 0,
    this.tags = const [],
  }) : createdAt = createdAt ?? _epoch;

  static final DateTime _epoch = DateTime(2024);

  factory Podcast.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Podcast(
      id: doc.id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      authorId: data['authorId'] ?? '',
      category: data['category'] ?? '',
      duration: data['duration'] ?? '00:00',
      audioUrl: data['audioUrl'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      isNew: data['isNew'] ?? false,
      isPremium: data['isPremium'] ?? false,
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      playCount: data['playCount'] ?? 0,
      likeCount: data['likeCount'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'author': author,
        'authorId': authorId,
        'category': category,
        'duration': duration,
        'audioUrl': audioUrl,
        'videoUrl': videoUrl,
        'imageUrl': imageUrl,
        'description': description,
        'isNew': isNew,
        'isPremium': isPremium,
        'price': price,
        'createdAt': FieldValue.serverTimestamp(),
        'playCount': playCount,
        'likeCount': likeCount,
        'tags': tags,
      };

  Podcast copyWith({
    String? id,
    String? title,
    String? author,
    String? authorId,
    String? category,
    String? duration,
    String? audioUrl,
    String? videoUrl,
    String? imageUrl,
    String? description,
    bool? isNew,
    bool? isPremium,
    double? price,
    DateTime? createdAt,
    int? playCount,
    int? likeCount,
    List<String>? tags,
  }) =>
      Podcast(
        id: id ?? this.id,
        title: title ?? this.title,
        author: author ?? this.author,
        authorId: authorId ?? this.authorId,
        category: category ?? this.category,
        duration: duration ?? this.duration,
        audioUrl: audioUrl ?? this.audioUrl,
        videoUrl: videoUrl ?? this.videoUrl,
        imageUrl: imageUrl ?? this.imageUrl,
        description: description ?? this.description,
        isNew: isNew ?? this.isNew,
        isPremium: isPremium ?? this.isPremium,
        price: price ?? this.price,
        createdAt: createdAt ?? this.createdAt,
        playCount: playCount ?? this.playCount,
        likeCount: likeCount ?? this.likeCount,
        tags: tags ?? this.tags,
      );

  bool get isFree => !isPremium || price == 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Podcast && other.id == id);

  @override
  int get hashCode => id.hashCode;
}