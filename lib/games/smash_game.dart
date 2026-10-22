// import 'dart:math';
// import 'package:flame/components.dart';
// import 'package:flame/events.dart';
// import 'package:flame/game.dart';
// import 'package:flutter/material.dart';

// class SmashGame extends FlameGame {
//   Function(String type)? onSmash;

//   final random = Random();

//   final List<Map<String, String>> words = [
//     {"text": "Stress", "type": "bad"},
//     {"text": "Fear", "type": "bad"},
//     {"text": "Anxiety", "type": "bad"},
//     {"text": "Peace", "type": "good"},
//     {"text": "Calm", "type": "good"},
//     {"text": "Focus", "type": "normal"},
//   ];

//   @override
//   Future<void> onLoad() async {
//     spawnWord();
//   }

//   void spawnWord() {
//     add(WordBox());

//     Future.delayed(const Duration(seconds: 1), () {
//       spawnWord();
//     });
//   }
// }

// class WordBox extends TextComponent
//     with TapCallbacks, HasGameRef<SmashGame> {
//   final random = Random();

//   /// ✅ FIX: ADD THIS
//   late String type;

//   WordBox()
//       : super(
//           textRenderer: TextPaint(
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         );

//   @override
//   Future<void> onLoad() async {
//     final words = gameRef.words;
//     final selected = words[random.nextInt(words.length)];

//     text = selected["text"]!;
//     type = selected["type"]!; // ✅ IMPORTANT

//     /// 🎨 COLOR BASED ON TYPE
//     if (type == "good") {
//       textRenderer = TextPaint(
//         style: const TextStyle(color: Colors.green),
//       );
//     } else if (type == "bad") {
//       textRenderer = TextPaint(
//         style: const TextStyle(color: Colors.red),
//       );
//     } else {
//       textRenderer = TextPaint(
//         style: const TextStyle(color: Colors.black),
//       );
//     }

//     position = Vector2(
//       random.nextDouble() * gameRef.size.x,
//       0,
//     );
//   }

//   @override
//   void update(double dt) {
//     position.y += 80 * dt;

//     if (position.y > gameRef.size.y) {
//       removeFromParent();
//     }
//   }

//   @override
//   void onTapDown(TapDownEvent event) {
//     /// ✅ PASS TYPE HERE
//     gameRef.onSmash?.call(type);

//     removeFromParent();
//   }
// }












import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  WORD DATA MODEL
// ─────────────────────────────────────────────
class WordData {
  final String text;
  final String type; // "good" | "bad" | "normal" | "bonus" | "danger"
  final int points;
  final Color color;
  final double speedMultiplier;

  const WordData({
    required this.text,
    required this.type,
    required this.points,
    required this.color,
    this.speedMultiplier = 1.0,
  });
}

// ─────────────────────────────────────────────
//  PARTICLE EFFECT COMPONENT
// ─────────────────────────────────────────────
class SmashParticle extends PositionComponent {
  final Color color;
  final Vector2 velocity;
  double _life = 1.0;

  SmashParticle({
    required Vector2 position,
    required this.color,
    required this.velocity,
  }) : super(position: position, size: Vector2(8, 8));

  @override
  void update(double dt) {
    _life -= dt * 2.5;
    position += velocity * dt;
    velocity.y += 200 * dt; // gravity
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = color.withOpacity(_life.clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 4 * _life, paint);
  }
}

// ─────────────────────────────────────────────
//  MAIN GAME CLASS
// ─────────────────────────────────────────────
class SmashGame extends FlameGame {
  Function(String type, int combo)? onSmash;
  Function()? onMissedBad; // penalty for NOT tapping bad words that fall off

  final random = Random();
  int _difficultyLevel = 1;
  double _spawnInterval = 1.2;
  double _baseSpeed = 80.0;

  // All word categories
  static const List<WordData> _allWords = [
    // BAD — destroy these for points
    WordData(text: "Stress",    type: "bad", points: 15, color: Color(0xFFE53935)),
    WordData(text: "Fear",      type: "bad", points: 15, color: Color(0xFFE53935)),
    WordData(text: "Anxiety",   type: "bad", points: 15, color: Color(0xFFE53935)),
    WordData(text: "Anger",     type: "bad", points: 15, color: Color(0xFFE53935)),
    WordData(text: "Doubt",     type: "bad", points: 15, color: Color(0xFFE53935)),
    WordData(text: "Shame",     type: "bad", points: 15, color: Color(0xFFE53935)),
    WordData(text: "Guilt",     type: "bad", points: 15, color: Color(0xFFE53935)),
    WordData(text: "Hate",      type: "bad", points: 20, color: Color(0xFFB71C1C)),
    WordData(text: "Panic",     type: "bad", points: 20, color: Color(0xFFB71C1C)),
    WordData(text: "Despair",   type: "bad", points: 20, color: Color(0xFFB71C1C)),

    // GOOD — DO NOT tap these (penalty if tapped)
    WordData(text: "Peace",     type: "good", points: -20, color: Color(0xFF43A047)),
    WordData(text: "Calm",      type: "good", points: -20, color: Color(0xFF43A047)),
    WordData(text: "Hope",      type: "good", points: -20, color: Color(0xFF43A047)),
    WordData(text: "Love",      type: "good", points: -20, color: Color(0xFF43A047)),
    WordData(text: "Joy",       type: "good", points: -20, color: Color(0xFF43A047)),

    // NORMAL — neutral, small points
    WordData(text: "Focus",     type: "normal", points: 5, color: Color(0xFFFFB300)),
    WordData(text: "Think",     type: "normal", points: 5, color: Color(0xFFFFB300)),
    WordData(text: "Breathe",   type: "normal", points: 5, color: Color(0xFFFFB300)),

    // BONUS — rare, big points, fast
    WordData(text: "⚡ POWER",  type: "bonus", points: 50, color: Color(0xFFAB47BC), speedMultiplier: 1.5),
    WordData(text: "🔥 FIRE",   type: "bonus", points: 40, color: Color(0xFFFF7043), speedMultiplier: 1.4),
  ];

  List<WordData> get availableWords {
    if (_difficultyLevel >= 3) return _allWords;
    if (_difficultyLevel == 2) return _allWords.where((w) => w.type != "bonus").toList();
    return _allWords.where((w) => w.type == "bad" || w.type == "normal").toList();
  }

  @override
  Future<void> onLoad() async {
    _scheduleSpawn();
  }

  void _scheduleSpawn() {
    _spawnWord();
    Future.delayed(
      Duration(milliseconds: (_spawnInterval * 1000).toInt()),
      () {
        if (!isMounted) return;
        _scheduleSpawn();
      },
    );
  }

  void _spawnWord() {
    final words = availableWords;
    final data = words[random.nextInt(words.length)];

    // Occasionally spawn 2 words at once at higher difficulty
    final count = (_difficultyLevel >= 2 && random.nextDouble() < 0.3) ? 2 : 1;

    for (int i = 0; i < count; i++) {
      final wordData = (i == 0) ? data : words[random.nextInt(words.length)];
      add(WordBox(
        wordData: wordData,
        baseSpeed: _baseSpeed,
      ));
    }
  }

  void increaseDifficulty(int level) {
    _difficultyLevel = level;
    _spawnInterval = (1.2 - (level * 0.1)).clamp(0.4, 1.2);
    _baseSpeed = (80.0 + (level * 15)).clamp(80, 180);
  }

  void spawnParticles(Vector2 position, Color color) {
    final r = Random();
    for (int i = 0; i < 8; i++) {
      final angle = r.nextDouble() * 2 * pi;
      final speed = 80 + r.nextDouble() * 120;
      add(SmashParticle(
        position: position.clone(),
        color: color,
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
      ));
    }
  }
}

// ─────────────────────────────────────────────
//  WORD BOX COMPONENT
// ─────────────────────────────────────────────
class WordBox extends PositionComponent
    with TapCallbacks, HasGameRef<SmashGame> {
  final WordData wordData;
  final double baseSpeed;
  final _random = Random();

  late TextComponent _label;
  late RectangleComponent _bg;
  double _wobble = 0;
  double _alpha = 1.0;
  bool _tapped = false;

  WordBox({required this.wordData, required this.baseSpeed});

  @override
  Future<void> onLoad() async {
    final padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8);

    // Background pill
    _bg = RectangleComponent(
      size: Vector2(100, 40), // will resize after text measurement
      paint: Paint()
        ..color = wordData.color.withOpacity(0.18)
        ..style = PaintingStyle.fill,
    );

    // Border
    final border = RectangleComponent(
      size: Vector2(100, 40),
      paint: Paint()
        ..color = wordData.color.withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    _label = TextComponent(
      text: wordData.text,
      textRenderer: TextPaint(
        style: TextStyle(
          color: wordData.color,
          fontSize: wordData.type == "bonus" ? 16 : 15,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );

    await add(_label);
    await add(_bg);
    await add(border);

    // Resize bg after text rendered
    final textSize = _label.size;
    final w = textSize.x + padding.horizontal;
    final h = textSize.y + padding.vertical;
    size = Vector2(w, h);
    _bg.size = size;
    border.size = size;
    _label.position = Vector2(padding.left, padding.top);

    // Anchor to center for wobble
    anchor = Anchor.topLeft;

    // Random X spawn
    position = Vector2(
      _random.nextDouble() * (gameRef.size.x - w).clamp(0, gameRef.size.x),
      -h - 10,
    );
  }

  @override
  void update(double dt) {
    if (_tapped) return;

    final speed = baseSpeed * wordData.speedMultiplier;
    position.y += speed * dt;

    // Gentle wobble
    _wobble += dt * 2;
    position.x += sin(_wobble) * 0.4;

    if (position.y > gameRef.size.y + 20) {
      // If a bad word falls off without being tapped — small penalty
      if (wordData.type == "bad") {
        gameRef.onMissedBad?.call();
      }
      removeFromParent();
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_tapped) return;
    _tapped = true;

    // Particles at center
    gameRef.spawnParticles(
      position + size / 2,
      wordData.color,
    );

    gameRef.onSmash?.call(wordData.type, 0 /* combo passed from screen */);
    removeFromParent();
  }
}