// import 'dart:async';
// import 'dart:math';

// import 'package:flutter/material.dart';

// class Balloon {
//   Offset position;
//   Color color;
//   String message;

//   Balloon({
//     required this.position,
//     required this.color,
//     required this.message,
//   });
// }

// class BalloonGame extends ChangeNotifier {
//   final Random random = Random();

//   List<Balloon> balloons = [];

//   int score = 0;
//   int timeLeft = 30;

//   bool isGameOver = false;

//   late Timer timer;
//   late Timer spawnTimer;

//   final List<String> messages = [
//     "You are amazing ✨",
//     "Keep going 💪",
//     "You matter ❤️",
//     "Stay calm 🌿",
//     "Believe in yourself 🌈",
//     "You are enough 🌸",
//     "Smile more 😊",
//     "Peace begins within ☁️",
//   ];

//   void startGame() {
//     spawnBalloon();

//     timer = Timer.periodic(
//       const Duration(seconds: 1),
//       (t) {
//         if (timeLeft > 0) {
//           timeLeft--;
//         } else {
//           isGameOver = true;
//           t.cancel();
//           spawnTimer.cancel();
//         }

//         notifyListeners();
//       },
//     );

//     spawnTimer = Timer.periodic(
//       const Duration(milliseconds: 900),
//       (t) {
//         if (!isGameOver) {
//           spawnBalloon();
//         }
//       },
//     );
//   }

//   void spawnBalloon() {
//     balloons.add(
//       Balloon(
//         position: Offset(
//           random.nextDouble() * 300,
//           600,
//         ),
//         color: Colors.primaries[
//             random.nextInt(Colors.primaries.length)],
//         message:
//             messages[random.nextInt(messages.length)],
//       ),
//     );

//     notifyListeners();
//   }

//   void updateBalloons() {
//     for (var balloon in balloons) {
//       balloon.position = Offset(
//         balloon.position.dx,
//         balloon.position.dy - 2,
//       );
//     }

//     balloons.removeWhere(
//       (b) => b.position.dy < -100,
//     );

//     notifyListeners();
//   }

//   String popBalloon(int index) {
//     final msg = balloons[index].message;

//     balloons.removeAt(index);

//     score += 10;

//     notifyListeners();

//     return msg;
//   }

//   void disposeGame() {
//     timer.cancel();
//     spawnTimer.cancel();
//   }
// }








import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────
//  BALLOON MODEL
// ─────────────────────────────────────────────
enum BalloonType { affirmation, star, bomb }

class Balloon {
  final String id;
  Offset position;
  final Color color;
  final Color glowColor;
  final String message;
  final BalloonType type;
  final double speed;
  final double size;
  double wobbleOffset;
  double wobbleTime;
  double opacity;
  bool isPopping;

  Balloon({
    required this.id,
    required this.position,
    required this.color,
    required this.glowColor,
    required this.message,
    required this.type,
    required this.speed,
    required this.size,
    this.wobbleOffset = 0,
    this.wobbleTime = 0,
    this.opacity = 1.0,
    this.isPopping = false,
  });
}

// ─────────────────────────────────────────────
//  FLOATING MESSAGE
// ─────────────────────────────────────────────
class FloatingMessage {
  final String text;
  final Color color;
  Offset position;
  double opacity;
  double scale;

  FloatingMessage({
    required this.text,
    required this.color,
    required this.position,
    this.opacity = 1.0,
    this.scale = 1.0,
  });
}

// ─────────────────────────────────────────────
//  GAME ENGINE
// ─────────────────────────────────────────────
class BalloonGame extends ChangeNotifier {
  final Random random = Random();

  List<Balloon> balloons = [];
  List<FloatingMessage> floatingMessages = [];

  int score = 0;
  int highScore = 0;
  int timeLeft = 30;
  int combo = 0;
  int maxCombo = 0;
  int popped = 0;
  int missed = 0;
  bool isGameOver = false;
  bool isPaused = false;

  DateTime _lastPopTime = DateTime.now();
  double _screenWidth = 360;
  double _screenHeight = 700;

  Timer? _gameTimer;
  Timer? _spawnTimer;
  Timer? _physicsTimer;

  int _difficultyLevel = 1;
  int _balloonIdCounter = 0;

  // ── AFFIRMATIONS ──
  static const List<Map<String, dynamic>> _wordPool = [
    // Affirmations — tap these ✅
    {"msg": "You are amazing ✨",     "type": BalloonType.affirmation, "points": 10},
    {"msg": "Keep going 💪",          "type": BalloonType.affirmation, "points": 10},
    {"msg": "You matter ❤️",          "type": BalloonType.affirmation, "points": 10},
    {"msg": "Stay calm 🌿",           "type": BalloonType.affirmation, "points": 10},
    {"msg": "Believe in yourself 🌈", "type": BalloonType.affirmation, "points": 10},
    {"msg": "You are enough 🌸",      "type": BalloonType.affirmation, "points": 10},
    {"msg": "Smile more 😊",          "type": BalloonType.affirmation, "points": 10},
    {"msg": "Peace begins within ☁️", "type": BalloonType.affirmation, "points": 10},
    {"msg": "Be kind to yourself 🤍", "type": BalloonType.affirmation, "points": 10},
    {"msg": "You've got this 🌟",     "type": BalloonType.affirmation, "points": 10},

    // Star balloons — bonus ⭐
    {"msg": "⭐ BONUS +30",           "type": BalloonType.star,        "points": 30},
    {"msg": "💫 SUPER +25",           "type": BalloonType.star,        "points": 25},

    // Bomb balloons — DON'T tap ❌
    {"msg": "💣 BOMB",                "type": BalloonType.bomb,        "points": -20},
    {"msg": "☠️ DANGER",              "type": BalloonType.bomb,        "points": -20},
  ];

  // Balloon color palettes
  static const List<List<Color>> _palettes = [
    [Color(0xFFFF6B9D), Color(0xFFFF8FA3)],   // pink
    [Color(0xFF845EF7), Color(0xFFA47CF7)],   // purple
    [Color(0xFF339AF0), Color(0xFF5BC0F8)],   // blue
    [Color(0xFF51CF66), Color(0xFF74E291)],   // green
    [Color(0xFFFF9F1C), Color(0xFFFFBF69)],   // orange
    [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],   // red
    [Color(0xFF22D3EE), Color(0xFF67E8F9)],   // cyan
    [Color(0xFFF59E0B), Color(0xFFFBD24D)],   // yellow
  ];

  void setScreenSize(double w, double h) {
    _screenWidth = w;
    _screenHeight = h;
  }

  void setHighScore(int hs) {
    highScore = hs;
  }

  void startGame() {
    _spawnBalloon();
    _startTimers();
  }

  void _startTimers() {
    // Game countdown
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (isPaused) return;
      if (timeLeft > 0) {
        timeLeft--;
        _updateDifficulty();
      } else {
        _endGame();
        t.cancel();
      }
      notifyListeners();
    });

    // Balloon physics — 60fps
    _physicsTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) {
        if (!isPaused && !isGameOver) _tickPhysics();
      },
    );

    // Spawn timer
    _scheduleSpawn();
  }

  void _scheduleSpawn() {
    final ms = _spawnIntervalMs();
    _spawnTimer = Timer(Duration(milliseconds: ms), () {
      if (!isGameOver) {
        _spawnBalloon();
        // Occasionally spawn 2 at higher difficulty
        if (_difficultyLevel >= 3 && random.nextDouble() < 0.35) {
          Future.delayed(const Duration(milliseconds: 300), _spawnBalloon);
        }
        _scheduleSpawn();
      }
    });
  }

  int _spawnIntervalMs() {
    return switch (_difficultyLevel) {
      1 => 1200,
      2 => 900,
      3 => 650,
      _ => 500,
    };
  }

  void _updateDifficulty() {
    final elapsed = 30 - timeLeft;
    _difficultyLevel = elapsed < 8 ? 1 : elapsed < 18 ? 2 : 3;
  }

  void _spawnBalloon() {
    final pool = _availablePool();
    final data = pool[random.nextInt(pool.length)];
    final type = data["type"] as BalloonType;
    final palette = _palettes[random.nextInt(_palettes.length)];

    // Bomb uses dark red
    final color = type == BalloonType.bomb
        ? const Color(0xFF1A0A0A)
        : palette[0];
    final glowColor = type == BalloonType.bomb
        ? const Color(0xFFFF0000)
        : palette[1];

    final baseSize = type == BalloonType.star ? 68.0 : type == BalloonType.bomb ? 58.0 : 62.0;
    final size = baseSize + random.nextDouble() * 12;
    final speed = (40.0 + _difficultyLevel * 15 + random.nextDouble() * 20)
        * (type == BalloonType.star ? 1.3 : 1.0);

    balloons.add(Balloon(
      id: "b${_balloonIdCounter++}",
      position: Offset(
        size / 2 + random.nextDouble() * (_screenWidth - size),
        _screenHeight + size,
      ),
      color: color,
      glowColor: glowColor,
      message: data["msg"] as String,
      type: type,
      speed: speed,
      size: size,
      wobbleOffset: random.nextDouble() * pi * 2,
      wobbleTime: 0,
    ));

    notifyListeners();
  }

  List<Map<String, dynamic>> _availablePool() {
    return _wordPool.where((w) {
      final type = w["type"] as BalloonType;
      if (type == BalloonType.bomb && _difficultyLevel < 2) return false;
      if (type == BalloonType.star && random.nextDouble() > 0.15) return false;
      return true;
    }).toList().isEmpty ? _wordPool.sublist(0, 10) : _wordPool.where((w) {
      final type = w["type"] as BalloonType;
      if (type == BalloonType.bomb && _difficultyLevel < 2) return false;
      if (type == BalloonType.star && random.nextDouble() > 0.15) return false;
      return true;
    }).toList();
  }

  void _tickPhysics() {
    bool changed = false;

    for (final b in balloons) {
      if (b.isPopping) continue;
      b.wobbleTime += 0.016;
      final wobble = sin(b.wobbleTime * 1.8 + b.wobbleOffset) * 0.8;
      b.position = Offset(
        b.position.dx + wobble,
        b.position.dy - b.speed * 0.016,
      );
      changed = true;
    }

    // Remove balloons that floated off screen
    final before = balloons.length;
    balloons.removeWhere((b) {
      if (b.position.dy < -b.size) {
        if (b.type == BalloonType.affirmation) missed++;
        return true;
      }
      return false;
    });
    if (balloons.length != before) changed = true;

    // Animate floating messages
    for (final m in floatingMessages) {
      m.position = Offset(m.position.dx, m.position.dy - 1.2);
      m.opacity -= 0.018;
      m.scale = (m.scale + 0.008).clamp(0, 1.4);
    }
    floatingMessages.removeWhere((m) => m.opacity <= 0);

    if (changed) notifyListeners();
  }

  /// Returns the message to display, or null if bomb
  String? popBalloon(String id, Offset tapPosition) {
    final idx = balloons.indexWhere((b) => b.id == id);
    if (idx < 0) return null;

    final balloon = balloons[idx];
    if (balloon.isPopping) return null;

    final now = DateTime.now();
    final isCombo = now.difference(_lastPopTime).inMilliseconds < 1500;
    _lastPopTime = now;

    int points;
    String? message;
    Color msgColor;

    switch (balloon.type) {
      case BalloonType.affirmation:
        combo = isCombo ? combo + 1 : 1;
        if (combo > maxCombo) maxCombo = combo;
        points = 10 + (combo > 1 ? combo * 2 : 0);
        message = balloon.message;
        msgColor = balloon.color;
        HapticFeedback.lightImpact();
        popped++;
        break;

      case BalloonType.star:
        combo = isCombo ? combo + 1 : 1;
        points = 30 + combo * 3;
        message = "⭐ +$points";
        msgColor = const Color(0xFFFBD24D);
        HapticFeedback.heavyImpact();
        popped++;
        break;

      case BalloonType.bomb:
        points = -20;
        message = "💣 -20";
        msgColor = const Color(0xFFFF4444);
        combo = 0;
        // Double buzz for mistake
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 100), HapticFeedback.heavyImpact);
        break;
    }

    score = (score + points).clamp(0, 99999);
    balloons.removeAt(idx);

    // Floating message
    floatingMessages.add(FloatingMessage(
      text: balloon.type == BalloonType.affirmation
          ? balloon.message
          : (points >= 0 ? "+$points" : "$points"),
      color: msgColor,
      position: tapPosition,
    ));

    notifyListeners();
    return message;
  }

  void togglePause() {
    isPaused = !isPaused;
    notifyListeners();
  }

  void _endGame() {
    isGameOver = true;
    _spawnTimer?.cancel();
    _physicsTimer?.cancel();
    notifyListeners();
  }

  void disposeGame() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _physicsTimer?.cancel();
  }

  void restart() {
    balloons.clear();
    floatingMessages.clear();
    score = 0;
    timeLeft = 30;
    combo = 0;
    maxCombo = 0;
    popped = 0;
    missed = 0;
    isGameOver = false;
    isPaused = false;
    _difficultyLevel = 1;
    _balloonIdCounter = 0;
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _physicsTimer?.cancel();
    startGame();
  }

  String get accuracyLabel {
    final total = popped + missed;
    if (total == 0) return "0%";
    return "${((popped / total) * 100).toStringAsFixed(0)}%";
  }
}


