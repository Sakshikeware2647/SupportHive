// ─────────────────────────────────────────────
//  model/note.dart  –  SupportHive
// ─────────────────────────────────────────────

class Note {
  final String? id; // Firestore document ID
  String title;
  String content;
  DateTime date;
  String? mood;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.date,
    this.mood,
  });

  // ── Firestore ──────────────────────────────
  Map<String, dynamic> toMap() => {
        'title': title,
        'content': content,
        'date': date.toIso8601String(),
        'mood': mood,
      };

  factory Note.fromMap(String id, Map<String, dynamic> map) {
    return Note(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      date: DateTime.parse(map['date']),
      mood: map['mood'] as String?,
    );
  }
}