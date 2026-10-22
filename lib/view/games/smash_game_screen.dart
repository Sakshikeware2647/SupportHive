// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flame/game.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:supporthive1/utlities/responsive.dart';
// import '../../games/smash_game.dart';

// class SmashGameScreen extends StatefulWidget {
//   const SmashGameScreen({super.key});

//   @override
//   State<SmashGameScreen> createState() => _SmashGameScreenState();
// }

// class _SmashGameScreenState extends State<SmashGameScreen> {
//   late SmashGame game;
//   late Timer timer;

//   int score = 0;
//   int highScore = 0;
//   int timeLeft = 30;
//   bool isGameOver = false;
//   bool isPaused = false;

//   int combo = 0;
//   int maxCombo = 0;
//   DateTime lastTapTime = DateTime.now();

//   @override
//   void initState() {
//     super.initState();

//     game = SmashGame();

//     /// 🔥 LOAD HIGH SCORE
//     final box = Hive.box('gameBox');
//     highScore = box.get('smashHighScore', defaultValue: 0);

//     /// 🔥 GAME LOGIC
//     game.onSmash = (String wordType) {
//       if (isGameOver) return;

//       final now = DateTime.now();

//       /// COMBO LOGIC
//       if (now.difference(lastTapTime).inMilliseconds < 1500) {
//         combo++;
//       } else {
//         combo = 1;
//       }

//       lastTapTime = now;

//       if (combo > maxCombo) maxCombo = combo;

//       int points = 10;

//       /// SPECIAL WORDS
//       if (wordType == "good") {
//         points = 30;
//       } else if (wordType == "bad") {
//         points = -10;
//       }

//       /// COMBO BONUS
//       points += combo * 2;

//       setState(() {
//         score += points;
//       });
//     };

//     startTimer();
//   }

//   void startTimer() {
//     timer = Timer.periodic(const Duration(seconds: 1), (t) {
//       if (timeLeft > 0) {
//         setState(() => timeLeft--);
//       } else {
//         t.cancel();
//         game.pauseEngine();

//         final box = Hive.box('gameBox');

//         /// SAVE HIGH SCORE
//         if (score > highScore) {
//           highScore = score;
//           box.put('smashHighScore', highScore);
//         }

//         setState(() => isGameOver = true);
//       }
//     });
//   }

//   void restartGame() {
//     timer.cancel();

//     setState(() {
//       score = 0;
//       timeLeft = 30;
//       isGameOver = false;
//       isPaused = false;
//       combo = 0;
//       maxCombo = 0;
//       lastTapTime = DateTime.now();
//     });

//     game = SmashGame();

//     /// 🔥 RE-ATTACH LOGIC (IMPORTANT)
//     game.onSmash = (String wordType) {
//       if (isGameOver) return;

//       final now = DateTime.now();

//       if (now.difference(lastTapTime).inMilliseconds < 1500) {
//         combo++;
//       } else {
//         combo = 1;
//       }

//       lastTapTime = now;

//       if (combo > maxCombo) maxCombo = combo;

//       int points = 10;

//       if (wordType == "good") {
//         points = 30;
//       } else if (wordType == "bad") {
//         points = -10;
//       }

//       points += combo * 2;

//       setState(() {
//         score += points;
//       });
//     };

//     game.resumeEngine();
//     startTimer();
//   }

//   @override
//   void dispose() {
//     timer.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           /// 🎨 BACKGROUND
//           Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Color(0xFF4A6741), Color(0xFF7FA36B)],
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//               ),
//             ),
//           ),

//           /// 🎮 GAME
//           GameWidget(game: game),

//           /// 🔝 TOP BAR
//           SafeArea(
//             child: Padding(
//               // padding: const EdgeInsets.all(16),
//               padding: EdgeInsets.all(R.wp(context, 4)),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   _circleButton(Icons.arrow_back, () {
//                     Navigator.pop(context);
//                   }),

//                   /// SCORE + COMBO + TIMER
//                   Row(
//                     children: [
//                       _glassContainer(
//                         Row(
//                           children: [
//                             const Icon(Icons.flash_on, color: Colors.orange),
//                             const SizedBox(width: 2),
//                             Text(
//                               "$score",
//                               style: const TextStyle(color: Colors.white),
//                             ),
//                           ],
//                         ),
//                       ),

//                       const SizedBox(width: 4),

//                       _glassContainer(
//                         Row(
//                           children: [
//                             const Icon(
//                               Icons.local_fire_department,
//                               color: Colors.red,
//                             ),
//                             const SizedBox(width: 3),
//                             Text(
//                               "x$combo",
//                               style: const TextStyle(color: Colors.white),
//                             ),
//                           ],
//                         ),
//                       ),

//                       const SizedBox(width: 4),

//                       _glassContainer(
//                         Row(
//                           children: [
//                             const Icon(Icons.timer, color: Colors.white),
//                             const SizedBox(width: 3),
//                             Text(
//                               "$timeLeft s",
//                               style: const TextStyle(color: Colors.white),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),

//                   _circleButton(isPaused ? Icons.play_arrow : Icons.pause, () {
//                     setState(() {
//                       isPaused = !isPaused;
//                       isPaused ? game.pauseEngine() : game.resumeEngine();
//                     });
//                   }),
//                 ],
//               ),
//             ),
//           ),

//           /// 🔽 BOTTOM TEXT
//           Align(
//             alignment: Alignment.bottomCenter,
//             child: Padding(
//               padding: const EdgeInsets.all(15),
//               child: _glassContainer(
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: const [
//                     Text(
//                       "Destroy negative thoughts 💥",
//                       style: TextStyle(color: Colors.white),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),

//           /// 🛑 GAME OVER
//           if (isGameOver)
//             Container(
//               color: Colors.black.withOpacity(0.7),
//               child: Center(
//                 child: Container(
//                   padding: const EdgeInsets.all(24),
//                   margin: const EdgeInsets.symmetric(horizontal: 30),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Text(
//                         "Game Over",
//                         style: TextStyle(
//                           fontSize: 22,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 10),
//                       Text("Score: $score"),
//                       const SizedBox(height: 6),
//                       Text("High Score: $highScore"),
//                       const SizedBox(height: 20),

//                       ElevatedButton(
//                         onPressed: restartGame,
//                         child: const Text("Play Again"),
//                       ),

//                       TextButton(
//                         onPressed: () => Navigator.pop(context),
//                         child: const Text("Exit"),
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

//   Widget _circleButton(IconData icon, VoidCallback onTap) {
//     return Container(
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         color: Colors.white.withOpacity(0.2),
//       ),
//       child: IconButton(
//         icon: Icon(icon, color: Colors.white),
//         onPressed: onTap,
//       ),
//     );
//   }

//   Widget _glassContainer(Widget child) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.2),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: child,
//     );
//   }
// }








import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../games/smash_game.dart';

// ─────────────────────────────────────────────
//  FLOATING SCORE LABEL (pops up on tap)
// ─────────────────────────────────────────────
class _FloatingScore extends StatefulWidget {
  final String text;
  final Color color;
  final Offset position;
  final VoidCallback onDone;

  const _FloatingScore({
    super.key,
    required this.text,
    required this.color,
    required this.position,
    required this.onDone,
  });

  @override
  State<_FloatingScore> createState() => _FloatingScoreState();
}

class _FloatingScoreState extends State<_FloatingScore>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<double> _slide;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward().then((_) => widget.onDone());

    _opacity = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.5, 1.0)),
    );
    _slide = Tween(begin: 0.0, end: -60.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _scale = Tween(begin: 0.6, end: 1.3).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Positioned(
        left: widget.position.dx - 24,
        top: widget.position.dy + _slide.value,
        child: Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: _scale.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.color.withOpacity(0.5)),
              ),
              child: Text(
                widget.text,
                style: TextStyle(
                  color: widget.color,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  shadows: [Shadow(color: widget.color.withOpacity(0.4), blurRadius: 8)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PULSING TIMER RING
// ─────────────────────────────────────────────
class _TimerRing extends StatefulWidget {
  final int timeLeft;
  final int totalTime;
  const _TimerRing({required this.timeLeft, required this.totalTime});

  @override
  State<_TimerRing> createState() => _TimerRingState();
}

class _TimerRingState extends State<_TimerRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct = widget.timeLeft / widget.totalTime;
    final color = pct > 0.5
        ? const Color(0xFF66BB6A)
        : pct > 0.25
            ? const Color(0xFFFFB300)
            : const Color(0xFFEF5350);

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final scale = widget.timeLeft <= 5
            ? 1.0 + _pulse.value * 0.08
            : 1.0;
        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(56, 56),
                  painter: _RingPainter(progress: pct, color: color),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${widget.timeLeft}",
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      "sec",
                      style: TextStyle(
                        color: color.withOpacity(0.7),
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─────────────────────────────────────────────
//  COMBO BURST OVERLAY
// ─────────────────────────────────────────────
class _ComboBurst extends StatefulWidget {
  final int combo;
  const _ComboBurst({super.key, required this.combo});

  @override
  State<_ComboBurst> createState() => _ComboBurstState();
}

class _ComboBurstState extends State<_ComboBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.combo >= 10
        ? "🔥 UNSTOPPABLE x${widget.combo}"
        : widget.combo >= 7
            ? "⚡ LEGENDARY x${widget.combo}"
            : widget.combo >= 5
                ? "💥 MEGA x${widget.combo}"
                : widget.combo >= 3
                    ? "✨ COMBO x${widget.combo}"
                    : "";

    if (label.isEmpty) return const SizedBox();

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final opacity = _ctrl.value < 0.7
            ? 1.0
            : 1.0 - (_ctrl.value - 0.7) / 0.3;
        final scale = _ctrl.value < 0.3
            ? 0.5 + (_ctrl.value / 0.3) * 0.7
            : 1.0 + sin(_ctrl.value * pi * 2) * 0.04;
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6F00), Color(0xFFE91E63)],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6F00).withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  MAIN SCREEN
// ─────────────────────────────────────────────
class SmashGameScreen extends StatefulWidget {
  const SmashGameScreen({super.key});

  @override
  State<SmashGameScreen> createState() => _SmashGameScreenState();
}

class _SmashGameScreenState extends State<SmashGameScreen>
    with TickerProviderStateMixin {
  late SmashGame game;
  late Timer _gameTimer;

  static const int kTotalTime = 30;

  int score = 0;
  int highScore = 0;
  int timeLeft = kTotalTime;
  bool isGameOver = false;
  bool isPaused = false;

  int combo = 0;
  int maxCombo = 0;
  DateTime lastTapTime = DateTime.now();

  // Missed bad words penalty tracker
  int missedBad = 0;

  // Difficulty
  int _difficultyLevel = 1;

  // Floating labels
  final List<_FloatingScoreEntry> _floatingLabels = [];
  int _floatingIdCounter = 0;

  // Combo burst key to re-trigger animation
  Key _comboKey = UniqueKey();
  bool _showComboBurst = false;

  // Score shake animation
  late AnimationController _scoreShake;

  @override
  void initState() {
    super.initState();

    _scoreShake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _initGame();
  }

  void _initGame() {
    game = SmashGame();

    final box = Hive.box('gameBox');
    highScore = box.get('smashHighScore', defaultValue: 0);

    game.onSmash = (String wordType, int _) => _handleSmash(wordType);
    game.onMissedBad = _handleMissedBad;

    _startTimer();
  }

  void _handleSmash(String wordType) {
    if (isGameOver || isPaused) return;

    HapticFeedback.lightImpact();

    final now = DateTime.now();
    final isCombo = now.difference(lastTapTime).inMilliseconds < 1500;

    combo = isCombo ? combo + 1 : 1;
    lastTapTime = now;
    if (combo > maxCombo) maxCombo = combo;

    int points;
    Color popColor;

    switch (wordType) {
      case "bad":
        points = 15 + (combo * 3);
        popColor = const Color(0xFFEF5350);
        break;
      case "good":
        points = -20;
        popColor = const Color(0xFF66BB6A);
        _scoreShake.forward(from: 0);
        combo = 0;
        break;
      case "bonus":
        points = 50 + (combo * 5);
        popColor = const Color(0xFFAB47BC);
        HapticFeedback.heavyImpact();
        break;
      case "normal":
        points = 5 + combo;
        popColor = const Color(0xFFFFB300);
        break;
      default:
        points = 10;
        popColor = Colors.white;
    }

    // Show combo burst
    if (combo >= 3) {
      setState(() {
        _comboKey = UniqueKey();
        _showComboBurst = true;
      });
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _showComboBurst = false);
      });
    }

    // Floating label
    final rng = Random();
    final pos = Offset(
      80 + rng.nextDouble() * (MediaQuery.of(context).size.width - 160),
      MediaQuery.of(context).size.height * 0.4,
    );

    final id = _floatingIdCounter++;
    setState(() {
      score = (score + points).clamp(0, 99999);
      _floatingLabels.add(_FloatingScoreEntry(
        id: id,
        text: points >= 0 ? "+$points" : "$points",
        color: popColor,
        position: pos,
      ));
    });

    // Update difficulty
    _updateDifficulty();
  }

  void _handleMissedBad() {
    if (isGameOver) return;
    setState(() {
      missedBad++;
      // Small score penalty for letting bad words escape
      score = (score - 5).clamp(0, 99999);
    });
  }

  void _updateDifficulty() {
    final elapsed = kTotalTime - timeLeft;
    final newLevel = elapsed < 8
        ? 1
        : elapsed < 18
            ? 2
            : 3;
    if (newLevel != _difficultyLevel) {
      _difficultyLevel = newLevel;
      game.increaseDifficulty(newLevel);
    }
  }

  void _startTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (timeLeft > 0) {
        setState(() => timeLeft--);
        if (timeLeft <= 5) HapticFeedback.selectionClick();
      } else {
        t.cancel();
        game.pauseEngine();
        _saveHighScore();
        setState(() => isGameOver = true);
      }
    });
  }

  void _saveHighScore() {
    if (score > highScore) {
      highScore = score;
      Hive.box('gameBox').put('smashHighScore', highScore);
    }
  }

  void _restartGame() {
    _gameTimer.cancel();

    setState(() {
      score = 0;
      timeLeft = kTotalTime;
      isGameOver = false;
      isPaused = false;
      combo = 0;
      maxCombo = 0;
      missedBad = 0;
      _difficultyLevel = 1;
      lastTapTime = DateTime.now();
      _floatingLabels.clear();
    });

    _initGame();
  }

  @override
  void dispose() {
    _gameTimer.cancel();
    _scoreShake.dispose();
    super.dispose();
  }

  // ──────────────── BUILD ────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // ── BACKGROUND ──
            _buildBackground(),

            // ── GAME ENGINE ──
            GameWidget(game: game),

            // ── FLOATING SCORE LABELS ──
            ..._floatingLabels.map((e) => _FloatingScore(
                  key: ValueKey(e.id),
                  text: e.text,
                  color: e.color,
                  position: e.position,
                  onDone: () {
                    if (mounted) {
                      setState(() => _floatingLabels.removeWhere((x) => x.id == e.id));
                    }
                  },
                )),

            // ── TOP BAR ──
            _buildTopBar(),

            // ── COMBO BURST ──
            if (_showComboBurst)
              Align(
                alignment: const Alignment(0, -0.2),
                child: _ComboBurst(key: _comboKey, combo: combo),
              ),

            // ── BOTTOM HINT ──
            _buildBottomHint(),

            // ── PAUSE OVERLAY ──
            if (isPaused && !isGameOver) _buildPauseOverlay(),

            // ── GAME OVER ──
            if (isGameOver) _buildGameOver(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1B2A), Color(0xFF1B2838), Color(0xFF0D2137)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CustomPaint(
        painter: _StarfieldPainter(),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Back button
            _iconBtn(Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context)),

            const Spacer(),

            // Score
            _statChip(
              icon: Icons.flash_on_rounded,
              iconColor: const Color(0xFFFFD54F),
              label: _formatScore(score),
              shake: _scoreShake,
            ),

            const SizedBox(width: 8),

            // Combo
            _statChip(
              icon: Icons.local_fire_department_rounded,
              iconColor: combo >= 5
                  ? const Color(0xFFFF7043)
                  : combo >= 3
                      ? const Color(0xFFFFB300)
                      : Colors.white38,
              label: "×$combo",
            ),

            const SizedBox(width: 8),

            // Timer ring
            _TimerRing(timeLeft: timeLeft, totalTime: kTotalTime),

            const Spacer(),

            // Pause
            _iconBtn(
              isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              () {
                setState(() {
                  isPaused = !isPaused;
                  isPaused ? game.pauseEngine() : game.resumeEngine();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomHint() {
    final hints = [
      "💥 Smash negative thoughts!",
      "🟢 Protect positive words!",
      "⚡ Combos multiply your score!",
    ];
    final hint = hints[timeLeft % hints.length];

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Text(
            hint,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPauseOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.65),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pause_circle_filled_rounded,
                color: Colors.white70, size: 64),
            const SizedBox(height: 16),
            const Text(
              "PAUSED",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 24),
            _primaryButton("Resume", Icons.play_arrow_rounded, () {
              setState(() {
                isPaused = false;
                game.resumeEngine();
              });
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOver() {
    final isNewRecord = score >= highScore && score > 0;
    return Container(
      color: Colors.black.withOpacity(0.75),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A2942), Color(0xFF0D1B2A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Trophy / emoji
              Text(
                score >= 300
                    ? "🏆"
                    : score >= 150
                        ? "🎉"
                        : "💪",
                style: const TextStyle(fontSize: 56),
              ),
              const SizedBox(height: 8),

              Text(
                score >= 300
                    ? "OUTSTANDING!"
                    : score >= 150
                        ? "GREAT JOB!"
                        : "KEEP GOING!",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),

              if (isNewRecord) ...[
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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

              // Stats grid
              _statsGrid(),

              const SizedBox(height: 24),

              _primaryButton("Play Again", Icons.refresh_rounded, _restartGame),
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

  Widget _statsGrid() {
    return Row(
      children: [
        _statCard("Score", _formatScore(score), const Color(0xFFFFD54F)),
        const SizedBox(width: 10),
        _statCard("Best", _formatScore(highScore), const Color(0xFF66BB6A)),
        const SizedBox(width: 10),
        _statCard("Combo", "×$maxCombo", const Color(0xFFFF7043)),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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

  Widget _statChip({
    required IconData icon,
    required Color iconColor,
    required String label,
    AnimationController? shake,
  }) {
    Widget child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    if (shake != null) {
      child = AnimatedBuilder(
        animation: shake,
        builder: (_, c) => Transform.translate(
          offset: Offset(sin(shake.value * pi * 6) * 4, 0),
          child: c,
        ),
        child: child,
      );
    }

    return child;
  }

  Widget _primaryButton(String label, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1565C0),
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

  String _formatScore(int s) {
    if (s >= 1000) return "${(s / 1000).toStringAsFixed(1)}k";
    return "$s";
  }
}

// ─────────────────────────────────────────────
//  STARFIELD BACKGROUND PAINTER
// ─────────────────────────────────────────────
class _StarfieldPainter extends CustomPainter {
  final _rng = Random(42);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (int i = 0; i < 80; i++) {
      final x = _rng.nextDouble() * size.width;
      final y = _rng.nextDouble() * size.height;
      final r = _rng.nextDouble() * 1.5;
      final opacity = 0.1 + _rng.nextDouble() * 0.4;
      canvas.drawCircle(Offset(x, y), r, paint..color = Colors.white.withOpacity(opacity));
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter old) => false;
}

// ─────────────────────────────────────────────
//  DATA HOLDER
// ─────────────────────────────────────────────
class _FloatingScoreEntry {
  final int id;
  final String text;
  final Color color;
  final Offset position;
  _FloatingScoreEntry({
    required this.id,
    required this.text,
    required this.color,
    required this.position,
  });
}