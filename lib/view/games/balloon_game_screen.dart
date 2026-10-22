// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:hive_flutter/hive_flutter.dart';

// import '../../games/balloon_game.dart';

// class BalloonGameScreen extends StatefulWidget {
//   const BalloonGameScreen({super.key});

//   @override
//   State<BalloonGameScreen> createState() =>
//       _BalloonGameScreenState();
// }

// class _BalloonGameScreenState
//     extends State<BalloonGameScreen>
//     with TickerProviderStateMixin {
//   late BalloonGame game;

//   late Timer movementTimer;

//   String currentMessage = "";

//   int highScore = 0;

//   @override
//   void initState() {
//     super.initState();

//     game = BalloonGame()..startGame();

//     final box = Hive.box('gameBox');

//     highScore = box.get(
//       'balloonHighScore',
//       defaultValue: 0,
//     );

//     game.addListener(() {
//       saveHighScore();

//       setState(() {});
//     });

//     movementTimer = Timer.periodic(
//       const Duration(milliseconds: 16),
//       (t) {
//         if (!game.isGameOver) {
//           game.updateBalloons();
//         }
//       },
//     );
//   }

//   void saveHighScore() {
//     final box = Hive.box('gameBox');

//     if (game.score > highScore) {
//       highScore = game.score;

//       box.put(
//         'balloonHighScore',
//         highScore,
//       );
//     }
//   }

//   @override
//   void dispose() {
//     movementTimer.cancel();
//     game.disposeGame();
//     super.dispose();
//   }

//   Widget hudCard(
//     String text,
//     Color color,
//   ) {
//     return Container(
//       padding: const EdgeInsets.symmetric(
//         horizontal: 16,
//         vertical: 10,
//       ),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.12),
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(
//           color: color.withOpacity(0.3),
//         ),
//       ),
//       child: Text(
//         text,
//         style: TextStyle(
//           color: color,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           /// 🌌 BACKGROUND
//           Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   Color(0xFF1B1F3B),
//                   Color(0xFF2E356B),
//                   Color(0xFF4B5FA0),
//                 ],
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//               ),
//             ),
//           ),

//           /// ☁️ SOFT GLOW
//           Positioned.fill(
//             child: IgnorePointer(
//               child: Container(
//                 decoration: BoxDecoration(
//                   gradient: RadialGradient(
//                     colors: [
//                       Colors.white.withOpacity(0.08),
//                       Colors.transparent,
//                     ],
//                     radius: 1,
//                   ),
//                 ),
//               ),
//             ),
//           ),

//           /// 🎈 BALLOONS
//           ...game.balloons.asMap().entries.map(
//             (entry) {
//               final index = entry.key;
//               final balloon = entry.value;

//               return Positioned(
//                 left: balloon.position.dx,
//                 top: balloon.position.dy,
//                 child: GestureDetector(
//                   onTap: () {
//                     final msg =
//                         game.popBalloon(index);

//                     setState(() {
//                       currentMessage = msg;
//                     });
//                   },
//                   child: TweenAnimationBuilder(
//                     tween: Tween(
//                       begin: 0.9,
//                       end: 1.05,
//                     ),
//                     duration:
//                         const Duration(milliseconds: 800),
//                     curve: Curves.easeInOut,
//                     builder:
//                         (_, value, child) {
//                       return Transform.scale(
//                         scale: value,
//                         child: child,
//                       );
//                     },
//                     child: Column(
//                       children: [
//                         Container(
//                           width: 70,
//                           height: 85,
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             color: balloon.color,
//                             boxShadow: [
//                               BoxShadow(
//                                 color: balloon.color
//                                     .withOpacity(0.4),
//                                 blurRadius: 25,
//                               ),
//                             ],
//                           ),
//                         ),

//                         Container(
//                           width: 2,
//                           height: 40,
//                           color: Colors.white70,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),

//           /// 🔝 UI
//           SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.all(18),
//               child: Row(
//                 mainAxisAlignment:
//                     MainAxisAlignment.spaceBetween,
//                 children: [
//                   hudCard(
//                     "⭐ ${game.score}",
//                     Colors.amber,
//                   ),

//                   hudCard(
//                     "🏆 $highScore",
//                     Colors.greenAccent,
//                   ),

//                   hudCard(
//                     "⏱ ${game.timeLeft}",
//                     Colors.white,
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           /// 💬 MESSAGE
//           if (currentMessage.isNotEmpty)
//             Align(
//               alignment: Alignment.bottomCenter,
//               child: Padding(
//                 padding:
//                     const EdgeInsets.only(bottom: 60),
//                 child: AnimatedContainer(
//                   duration:
//                       const Duration(milliseconds: 400),
//                   padding:
//                       const EdgeInsets.symmetric(
//                     horizontal: 24,
//                     vertical: 16,
//                   ),
//                   decoration: BoxDecoration(
//                     color:
//                         Colors.white.withOpacity(0.15),
//                     borderRadius:
//                         BorderRadius.circular(24),
//                   ),
//                   child: Text(
//                     currentMessage,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//             ),

//           /// 🛑 GAME OVER
//           if (game.isGameOver)
//             Container(
//               color: Colors.black.withOpacity(0.6),
//               child: Center(
//                 child: Container(
//                   width: 320,
//                   padding: const EdgeInsets.all(24),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF2E356B),
//                     borderRadius:
//                         BorderRadius.circular(28),
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Text(
//                         "🎈 Session Complete",
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 26,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),

//                       const SizedBox(height: 20),

//                       Text(
//                         "Score: ${game.score}",
//                         style: const TextStyle(
//                           color: Colors.white70,
//                           fontSize: 18,
//                         ),
//                       ),

//                       Text(
//                         "Best: $highScore",
//                         style: const TextStyle(
//                           color: Colors.greenAccent,
//                           fontSize: 18,
//                         ),
//                       ),

//                       const SizedBox(height: 20),

//                       ElevatedButton(
//                         onPressed: () {
//                           Navigator.pushReplacement(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) =>
//                                   const BalloonGameScreen(),
//                             ),
//                           );
//                         },
//                         child: const Text(
//                           "Play Again",
//                         ),
//                       ),

//                       TextButton(
//                         onPressed: () {
//                           Navigator.pop(context);
//                         },
//                         child: const Text(
//                           "Exit",
//                           style: TextStyle(
//                             color: Colors.white70,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }







import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supporthive1/games/balloon_game.dart';

// ─────────────────────────────────────────────
//  BALLOON PAINTER
// ─────────────────────────────────────────────
class _BalloonPainter extends CustomPainter {
  final Color color;
  final Color glowColor;
  final BalloonType type;
  final double size;

  _BalloonPainter({
    required this.color,
    required this.glowColor,
    required this.type,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final cx = canvasSize.width / 2;
    final cy = canvasSize.height * 0.42;
    final r = size / 2;

    // Glow
    canvas.drawCircle(
      Offset(cx, cy),
      r * 1.15,
      Paint()
        ..color = glowColor.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    // Main body
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 0.85,
        colors: [
          color.withOpacity(0.95),
          color,
          Color.lerp(color, Colors.black, 0.28)!,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: r * 1.85, height: r * 2.1),
      bodyPaint,
    );

    // Shine highlight
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - r * 0.28, cy - r * 0.45),
        width: r * 0.45,
        height: r * 0.28,
      ),
      Paint()..color = Colors.white.withOpacity(0.55),
    );

    // Knot
    final knotPath = Path()
      ..moveTo(cx - 4, cy + r * 0.95)
      ..quadraticBezierTo(cx, cy + r * 1.12, cx + 4, cy + r * 0.95)
      ..quadraticBezierTo(cx, cy + r * 1.05, cx - 4, cy + r * 0.95);
    canvas.drawPath(knotPath, Paint()..color = color.withOpacity(0.85));

    // String
    final stringPath = Path()
      ..moveTo(cx, cy + r * 1.1)
      ..quadraticBezierTo(
        cx + 8, cy + r * 1.5,
        cx - 5, cy + r * 1.9,
      );
    canvas.drawPath(
      stringPath,
      Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );

    // Bomb fuse
    if (type == BalloonType.bomb) {
      final fuseRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy - r * 0.95), width: 6, height: 12),
        const Radius.circular(3),
      );
      canvas.drawRRect(fuseRect, Paint()..color = const Color(0xFF8B6914));

      // Spark
      canvas.drawCircle(
        Offset(cx, cy - r * 1.05),
        4,
        Paint()
          ..color = const Color(0xFFFFD700)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
  }

  @override
  bool shouldRepaint(_BalloonPainter old) =>
      old.color != color || old.type != type;
}

// ─────────────────────────────────────────────
//  SINGLE BALLOON WIDGET
// ─────────────────────────────────────────────
class _BalloonWidget extends StatefulWidget {
  final Balloon balloon;
  final VoidCallback onPop;

  const _BalloonWidget({super.key,required this.balloon, required this.onPop});

  @override
  State<_BalloonWidget> createState() => _BalloonWidgetState();
}

class _BalloonWidgetState extends State<_BalloonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _popCtrl;
  late Animation<double> _popScale;
  late Animation<double> _popOpacity;

  @override
  void initState() {
    super.initState();
    _popCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _popScale = Tween(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _popCtrl, curve: Curves.easeOut),
    );
    _popOpacity = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _popCtrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _popCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    _popCtrl.forward();
    widget.onPop();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.balloon;
    return Positioned(
      left: b.position.dx - b.size / 2,
      top: b.position.dy - b.size / 2,
      child: GestureDetector(
        onTapDown: (_) => _handleTap(),
        child: AnimatedBuilder(
          animation: _popCtrl,
          builder: (_, __) => Opacity(
            opacity: _popOpacity.value,
            child: Transform.scale(
              scale: _popScale.value,
              child: SizedBox(
                width: b.size,
                height: b.size * 1.4,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: Size(b.size, b.size * 1.4),
                      painter: _BalloonPainter(
                        color: b.color,
                        glowColor: b.glowColor,
                        type: b.type,
                        size: b.size,
                      ),
                    ),
                    // Label inside balloon
                    Positioned(
                      top: b.size * 0.18,
                      left: 4,
                      right: 4,
                      child: Text(
                        b.type == BalloonType.bomb
                            ? "💣"
                            : b.type == BalloonType.star
                                ? "⭐"
                                : _shortLabel(b.message),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: b.type == BalloonType.bomb ? 22 : 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          shadows: const [
                            Shadow(color: Colors.black38, blurRadius: 4),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _shortLabel(String msg) {
    // Remove emoji suffix, keep first few words
    final clean = msg.replaceAll(RegExp(r'[\u{1F300}-\u{1FAFF}]', unicode: true), '').trim();
    final words = clean.split(' ');
    return words.take(3).join(' ');
  }
}

// ─────────────────────────────────────────────
//  FLOATING MESSAGE OVERLAY
// ─────────────────────────────────────────────
class _FloatingMsgWidget extends StatelessWidget {
  final FloatingMessage msg;
  const _FloatingMsgWidget({super.key,required this.msg});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: msg.position.dx - 80,
      top: msg.position.dy,
      child: Opacity(
        opacity: msg.opacity.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: msg.scale.clamp(0.5, 1.4),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: msg.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: msg.color.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(
                  color: msg.color.withOpacity(0.2),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Text(
              msg.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: msg.color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  TIMER ARC
// ─────────────────────────────────────────────
class _TimerArc extends CustomPainter {
  final double progress;
  final Color color;
  _TimerArc({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 4;

    canvas.drawCircle(c, r, Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5);

    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_TimerArc old) => old.progress != progress;
}

// ─────────────────────────────────────────────
//  CLOUD BACKGROUND PAINTER
// ─────────────────────────────────────────────
class _SkyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(7);

    // Draw soft cloud blobs
    for (int i = 0; i < 12; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = 30 + rng.nextDouble() * 60;
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = Colors.white.withOpacity(0.03 + rng.nextDouble() * 0.04)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );
    }
  }

  @override
  bool shouldRepaint(_SkyPainter old) => false;
}

// ─────────────────────────────────────────────
//  MAIN SCREEN
// ─────────────────────────────────────────────
class BalloonGameScreen extends StatefulWidget {
  const BalloonGameScreen({super.key});

  @override
  State<BalloonGameScreen> createState() => _BalloonGameScreenState();
}

class _BalloonGameScreenState extends State<BalloonGameScreen>
    with TickerProviderStateMixin {
  late BalloonGame _game;
  late AnimationController _comboCtrl;

  String? _lastMessage;
  int _lastCombo = 0;

  @override
  void initState() {
    super.initState();
    _game = BalloonGame();

    _comboCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Load high score
    final box = Hive.box('gameBox');
    _game.setHighScore(box.get('balloonHighScore', defaultValue: 0));

    // Post frame: set screen size then start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      _game.setScreenSize(size.width, size.height);
      _game.startGame();
    });

    _game.addListener(_onGameUpdate);
  }

  void _onGameUpdate() {
    if (_game.isGameOver) {
      _saveHighScore();
    }
    if (_game.combo >= 3 && _game.combo != _lastCombo) {
      _comboCtrl.forward(from: 0);
      _lastCombo = _game.combo;
    }
  }

  void _saveHighScore() {
    if (_game.score > _game.highScore) {
      _game.highScore = _game.score;
      Hive.box('gameBox').put('balloonHighScore', _game.score);
    }
  }

  @override
  void dispose() {
    _game.removeListener(_onGameUpdate);
    _game.disposeGame();
    _comboCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ChangeNotifierProvider.value(
        value: _game,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Consumer<BalloonGame>(
            builder: (context, game, _) {
              return Stack(
                children: [
                  // ── SKY GRADIENT BG ──
                  _buildBackground(),

                  // ── BALLOONS ──
                  ...game.balloons.map((b) => _BalloonWidget(
                        key: ValueKey(b.id),
                        balloon: b,
                        onPop: () {
                          final size = MediaQuery.of(context).size;
                          final msg = game.popBalloon(
                            b.id,
                            Offset(
                              b.position.dx,
                              b.position.dy - b.size * 0.3,
                            ),
                          );
                          if (msg != null) setState(() => _lastMessage = msg);
                        },
                      )),

                  // ── FLOATING MESSAGES ──
                  ...game.floatingMessages.map(
                    (m) => _FloatingMsgWidget(key: ValueKey(m.hashCode), msg: m),
                  ),

                  // ── TOP BAR ──
                  _buildTopBar(game),

                  // ── COMBO BURST ──
                  if (game.combo >= 3)
                    _buildComboBurst(game.combo),

                  // ── BOTTOM LEGEND ──
                  _buildLegend(),

                  // ── PAUSE OVERLAY ──
                  if (game.isPaused && !game.isGameOver)
                    _buildPauseOverlay(game),

                  // ── GAME OVER ──
                  if (game.isGameOver) _buildGameOver(game),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0A1628),
            Color(0xFF0D2137),
            Color(0xFF102744),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: CustomPaint(
        painter: _SkyPainter(),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildTopBar(BalloonGame game) {
    final timerColor = game.timeLeft > 10
        ? const Color(0xFF51CF66)
        : game.timeLeft > 5
            ? const Color(0xFFFFB300)
            : const Color(0xFFFF6B6B);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Back
            _iconBtn(Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context)),

            const Spacer(),

            // Score
            _chip(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars_rounded, color: Color(0xFFFBD24D), size: 16),
                  const SizedBox(width: 5),
                  Text(
                    "${game.score}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Combo
            _chip(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    color: game.combo >= 5
                        ? const Color(0xFFFF7043)
                        : game.combo >= 3
                            ? const Color(0xFFFFB300)
                            : Colors.white30,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "×${game.combo}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Timer ring
            SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(52, 52),
                    painter: _TimerArc(
                      progress: game.timeLeft / 30,
                      color: timerColor,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${game.timeLeft}",
                        style: TextStyle(
                          color: timerColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        "sec",
                        style: TextStyle(
                          color: timerColor.withOpacity(0.6),
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Pause
            _iconBtn(
              game.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              game.togglePause,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComboBurst(int combo) {
    final label = combo >= 10
        ? "🔥 UNSTOPPABLE ×$combo"
        : combo >= 7
            ? "⚡ LEGENDARY ×$combo"
            : combo >= 5
                ? "💥 MEGA ×$combo"
                : "✨ COMBO ×$combo";

    return AnimatedBuilder(
      animation: _comboCtrl,
      builder: (_, __) {
        final t = _comboCtrl.value;
        final opacity = t < 0.6 ? 1.0 : 1.0 - (t - 0.6) / 0.4;
        final scale = t < 0.25 ? 0.4 + t / 0.25 * 0.7 : 1.1 + sin(t * pi * 3) * 0.04;
        return Align(
          alignment: const Alignment(0, -0.35),
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6F00), Color(0xFFE91E63)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6F00).withOpacity(0.5),
                      blurRadius: 24,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegend() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendItem("🎈", "Pop = +10", const Color(0xFF845EF7)),
            const SizedBox(width: 12),
            _legendItem("⭐", "Star = +30", const Color(0xFFFBD24D)),
            const SizedBox(width: 12),
            _legendItem("💣", "Bomb = −20", const Color(0xFFFF6B6B)),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        "$icon $label",
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildPauseOverlay(BalloonGame game) {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pause_circle_filled_rounded,
                color: Colors.white60, size: 72),
            const SizedBox(height: 16),
            const Text(
              "PAUSED",
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 5,
              ),
            ),
            const SizedBox(height: 28),
            _actionButton("Resume", Icons.play_arrow_rounded,
                const Color(0xFF1565C0), game.togglePause),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOver(BalloonGame game) {
    final isNew = game.score >= game.highScore && game.score > 0;

    return Container(
      color: Colors.black.withOpacity(0.75),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 26),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A2942), Color(0xFF0D1B2A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 40,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                game.score >= 300 ? "🏆" : game.score >= 150 ? "🎉" : "🎈",
                style: const TextStyle(fontSize: 60),
              ),
              const SizedBox(height: 6),
              Text(
                game.score >= 300
                    ? "AMAZING!"
                    : game.score >= 150
                        ? "GREAT JOB!"
                        : "KEEP GOING!",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              if (isNew) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "🌟 NEW HIGH SCORE!",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Stats row
              Row(
                children: [
                  _statCard("Score", "${game.score}", const Color(0xFFFFD54F)),
                  const SizedBox(width: 8),
                  _statCard("Best", "${game.highScore}", const Color(0xFF51CF66)),
                  const SizedBox(width: 8),
                  _statCard("Combo", "×${game.maxCombo}", const Color(0xFFFF7043)),
                  const SizedBox(width: 8),
                  _statCard("Accuracy", game.accuracyLabel, const Color(0xFF339AF0)),
                ],
              ),

              const SizedBox(height: 24),
              _actionButton("Play Again", Icons.refresh_rounded,
                  const Color(0xFF1565C0), () {
                _lastCombo = 0;
                _game.restart();
              }),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Exit",
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── HELPERS ──
  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withOpacity(0.1),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _chip({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: child,
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                )),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  color: color.withOpacity(0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            )),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}