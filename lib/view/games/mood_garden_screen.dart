import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../games/mood_garden_game.dart';

// ─── Leaf Particle ────────────────────────────────────────────────────────────

class _LeafParticle {
  double x, y, vx, vy, opacity, size, rotation, rotSpeed;
  String emoji;

  _LeafParticle({
    required this.x,
    required this.y,
    required this.emoji,
  })  : vx = (Random().nextDouble() - 0.5) * 6,
        vy = -(Random().nextDouble() * 6 + 3),
        opacity = 1.0,
        size = Random().nextDouble() * 16 + 12,
        rotation = Random().nextDouble() * pi * 2,
        rotSpeed = (Random().nextDouble() - 0.5) * 0.2;

  void update() {
    x += vx;
    y += vy;
    vy += 0.15;
    opacity -= 0.018;
    rotation += rotSpeed;
  }

  bool get isDead => opacity <= 0;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class MoodGardenScreen extends StatefulWidget {
  const MoodGardenScreen({super.key});

  @override
  State<MoodGardenScreen> createState() => _MoodGardenScreenState();
}

class _MoodGardenScreenState extends State<MoodGardenScreen>
    with TickerProviderStateMixin {
  late MoodGardenGame game;
  late Timer timer;
  late AnimationController flowerController;
  late AnimationController comboController;
  late AnimationController _particleController;

  final Random _random = Random();
  List<_LeafParticle> _particles = [];
  int _prevGrowth = 0;

  int score = 0;
  int highScore = 0;
  int timeLeft = 30;
  int growth = 0;
  int combo = 0;
  int maxCombo = 0;
  Timer? comboTimer;
  bool isGameOver = false;
  bool showCombo = false;

  String get plantEmoji {
    if (growth >= 100) return '🌸';
    if (growth >= 75) return '🌳';
    if (growth >= 50) return '🌿';
    if (growth >= 25) return '🌱';
    return '🪴';
  }

  @override
  void initState() {
    super.initState();

    final box = Hive.box('gameBox');
    highScore = box.get('gardenHighScore', defaultValue: 0);

    game = MoodGardenGame();

    game.onDropTap = () {
      if (isGameOver) return;
      HapticFeedback.lightImpact();

      combo++;
      if (combo > maxCombo) maxCombo = combo;

      comboTimer?.cancel();
      comboTimer = Timer(const Duration(milliseconds: 800), () {
        setState(() {
          combo = 0;
          showCombo = false;
        });
      });

      final points = 10 * (combo > 1 ? combo : 1);

      setState(() {
        score += points;
        growth = (growth + 5).clamp(0, 100);
        showCombo = combo > 1;

        if (growth > _prevGrowth) {
          _spawnLeaves(growth);
          _prevGrowth = growth;
        }
      });
    };

    game.onBombTap = () {
      if (isGameOver) return;
      HapticFeedback.heavyImpact();
      setState(() {
        score = (score - 20).clamp(0, 99999);
        growth = (growth - 10).clamp(0, 100);
        combo = 0;
        showCombo = false;
      });
    };

    flowerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    comboController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    _particleController.addListener(() {
      if (_particles.isNotEmpty) {
        setState(() {
          for (final p in _particles) p.update();
          _particles.removeWhere((p) => p.isDead);
        });
      }
    });

    startTimer();
  }

  void _spawnLeaves(int growth) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final cx = screenW / 2;
    final cy = screenH - 160.0;

    final emojis = growth >= 100
        ? ['🌸', '🌺', '🍀', '🌼', '✨', '🌷']
        : growth >= 75
            ? ['🌳', '🍃', '🌿', '✨']
            : growth >= 50
                ? ['🌿', '🍃', '💚']
                : ['🌱', '💚'];

    final count = growth >= 100 ? 18 : 6;

    for (int i = 0; i < count; i++) {
      _particles.add(_LeafParticle(
        x: cx + (_random.nextDouble() - 0.5) * 40,
        y: cy,
        emoji: emojis[_random.nextInt(emojis.length)],
      ));
    }
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timeLeft > 0) {
        setState(() => timeLeft--);
      } else {
        t.cancel();
        game.pauseEngine();
        final box = Hive.box('gameBox');
        if (score > highScore) {
          highScore = score;
          box.put('gardenHighScore', highScore);
        }
        setState(() => isGameOver = true);
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    comboTimer?.cancel();
    flowerController.dispose();
    comboController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🌌 Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF081C15),
                  Color(0xFF1B4332),
                  Color(0xFF2D6A4F),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 🎮 Game
          GameWidget(game: game),

          // 🌱 Plant — stages + particles + glow + multi-flower
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 260,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 🍃 Particles
                  ..._particles.map((p) => Positioned(
                        left: p.x - p.size / 2,
                        top: p.y - p.size / 2,
                        child: Opacity(
                          opacity: p.opacity.clamp(0.0, 1.0),
                          child: Transform.rotate(
                            angle: p.rotation,
                            child: Text(
                              p.emoji,
                              style: TextStyle(fontSize: p.size),
                            ),
                          ),
                        ),
                      )),

                  // 🌸 Side flowers at 100%
                  if (growth >= 100) ...[
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: AnimatedBuilder(
                        animation: flowerController,
                        builder: (_, __) => Transform.scale(
                          scale: 0.55 + flowerController.value * 0.08,
                          child: const Text('🌺',
                              style: TextStyle(fontSize: 60)),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: AnimatedBuilder(
                        animation: flowerController,
                        builder: (_, __) => Transform.scale(
                          scale: 0.5 + (1 - flowerController.value) * 0.08,
                          child: const Text('🌷',
                              style: TextStyle(fontSize: 55)),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 60,
                      left: 10,
                      child: AnimatedBuilder(
                        animation: flowerController,
                        builder: (_, __) => Text(
                          '🍀',
                          style: TextStyle(
                              fontSize: 30 + flowerController.value * 4),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 55,
                      right: 15,
                      child: AnimatedBuilder(
                        animation: flowerController,
                        builder: (_, __) => Text(
                          '🌼',
                          style: TextStyle(
                              fontSize:
                                  28 + (1 - flowerController.value) * 4),
                        ),
                      ),
                    ),
                  ],

                  // 🌱 Main center plant
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: AnimatedBuilder(
                        animation: flowerController,
                        builder: (_, __) {
                          final baseScale = growth >= 100
                              ? 1.0
                              : growth >= 75
                                  ? 0.85
                                  : growth >= 50
                                      ? 0.70
                                      : growth >= 25
                                          ? 0.55
                                          : 0.40;

                          final pulse = growth >= 100
                              ? flowerController.value * 0.06
                              : 0.0;

                          return Container(
                            decoration: growth >= 100
                                ? BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.greenAccent.withOpacity(
                                            0.3 +
                                                flowerController.value * 0.3),
                                        blurRadius: 50,
                                        spreadRadius: 20,
                                      ),
                                      BoxShadow(
                                        color: Colors.pinkAccent.withOpacity(
                                            0.2 +
                                                flowerController.value * 0.2),
                                        blurRadius: 30,
                                        spreadRadius: 10,
                                      ),
                                    ],
                                  )
                                : null,
                            child: Transform.scale(
                              scale: baseScale + pulse,
                              child: Text(
                                plantEmoji,
                                style: const TextStyle(fontSize: 90),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🔝 Top Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _glassCard("⭐ $score"),
                  _glassCard("🌿 $growth%"),
                  _glassCard("⏱ $timeLeft", urgent: timeLeft <= 5),
                ],
              ),
            ),
          ),

          // 🏆 High Score
          Positioned(
            top: 90,
            left: 16,
            child: _glassCard("🏆 Best: $highScore"),
          ),

          // 🔥 Combo Banner
          if (showCombo)
            Positioned(
              top: 160,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedScale(
                  scale: showCombo ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFE066), Color(0xFFFF6B35)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.6),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      '🔥 x$combo COMBO! +${10 * combo}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 💣 Bomb hint
          // Positioned(
          //   bottom: 200,
          //   left: 0,
          //   right: 0,
          //   child: Center(
          //     child: Text(
          //       '💣 Avoid bombs!',
          //       style: TextStyle(
          //         color: Colors.redAccent.withOpacity(0.6),
          //         fontSize: 13,
          //       ),
          //     ),
          //   ),
          // ),

          // 🏁 Game Over
          if (isGameOver)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4332),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.greenAccent),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        growth >= 100
                            ? "🌸 Garden Bloomed!"
                            : growth >= 75
                                ? "🌿 Great Growth!"
                                : growth >= 50
                                    ? "🌱 Good Start!"
                                    : "🪴 Keep Trying!",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _statRow("⭐ Score", "$score"),
                      _statRow("🏆 Best", "$highScore"),
                      _statRow("🌿 Growth", "$growth%"),
                      _statRow("🔥 Max Combo", "x$maxCombo"),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MoodGardenScreen()),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text("🔄 Play Again",
                            style: TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Exit",
                            style: TextStyle(color: Colors.white54)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 15)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _glassCard(String text, {bool urgent = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: urgent
            ? Colors.red.withOpacity(0.3)
            : Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: urgent ? Colors.redAccent : Colors.white.withOpacity(0.2),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: urgent ? Colors.redAccent : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
