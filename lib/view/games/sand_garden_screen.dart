import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SandGardenScreen extends StatefulWidget {
  const SandGardenScreen({super.key});

  @override
  State<SandGardenScreen> createState() =>
      _SandGardenScreenState();
}

class _SandGardenScreenState
    extends State<SandGardenScreen>
    with TickerProviderStateMixin {
  final List<Offset?> points = [];

  int score = 0;
  int highScore = 0;
  int timeLeft = 60;

  bool isGameOver = false;

  late Timer timer;

  late AnimationController glowController;

  @override
  void initState() {
    super.initState();

    final box = Hive.box('gameBox');

    highScore = box.get(
      'sandGardenHighScore',
      defaultValue: 0,
    );

    glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(
      const Duration(seconds: 1),
      (t) {
        if (timeLeft > 0) {
          setState(() {
            timeLeft--;
          });
        } else {
          t.cancel();

          final box = Hive.box('gameBox');

          if (score > highScore) {
            highScore = score;

            box.put(
              'sandGardenHighScore',
              highScore,
            );
          }

          setState(() {
            isGameOver = true;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    timer.cancel();
    glowController.dispose();
    super.dispose();
  }

  Widget hudCard(
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(0.25),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// 🌴 BACKGROUND
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFE6CCB2),
                  Color(0xFFDDB892),
                  Color(0xFFB08968),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          /// ✨ GLOW
          AnimatedBuilder(
            animation: glowController,
            builder: (_, __) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(
                        0.04 +
                            glowController.value *
                                0.05,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),

          /// 🎨 DRAW AREA
          GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                points.add(
                  details.localPosition,
                );

                score++;

                if (score > 9999) {
                  score = 9999;
                }
              });
            },
            onPanEnd: (_) {
              points.add(null);
            },
            child: CustomPaint(
              size: Size.infinite,
              painter: SandPainter(points),
            ),
          ),

          /// 🔝 UI
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  hudCard(
                    "🌊 $score",
                    Colors.brown.shade900,
                  ),

                  hudCard(
                    "🏆 $highScore",
                    Colors.brown.shade800,
                  ),

                  hudCard(
                    "⏱ $timeLeft",
                    Colors.brown.shade900,
                  ),
                ],
              ),
            ),
          ),

          /// 🌸 TITLE
          const Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Sand Garden",
                style: TextStyle(
                  fontSize: 32,
                  color: Color(0xFF6F4E37),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          /// 🧘 TIP
          const Positioned(
            top: 145,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Draw calming patterns",
                style: TextStyle(
                  color: Color(0xFF7F5539),
                ),
              ),
            ),
          ),

          /// 🛑 GAME OVER
          if (isGameOver)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5EBE0),
                    borderRadius:
                        BorderRadius.circular(28),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "🌴 Zen Complete",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6F4E37),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        "Calm Score: $score",
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),

                      Text(
                        "Best: $highScore",
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const SandGardenScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFB08968),
                        ),
                        child: const Text(
                          "Play Again",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),

                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Exit",
                          style: TextStyle(
                            color: Color(0xFF7F5539),
                          ),
                        ),
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
}

class SandPainter extends CustomPainter {
  final List<Offset?> points;

  SandPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color(0xFF7F5539)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null &&
          points[i + 1] != null) {
        canvas.drawLine(
          points[i]!,
          points[i + 1]!,
          paintLine,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}