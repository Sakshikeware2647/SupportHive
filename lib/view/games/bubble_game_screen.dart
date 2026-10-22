// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flame/game.dart';
// import 'package:hive/hive.dart';
// import '../../games/bubble_game.dart';

// class BubbleGameScreen extends StatefulWidget {
//   const BubbleGameScreen({super.key});

//   @override
//   State<BubbleGameScreen> createState() => _BubbleGameScreenState();
// }

// class _BubbleGameScreenState extends State<BubbleGameScreen> {
//   late BubbleGame game;
//   late Timer timer;

//   int score = 0;
//   int highScore = 0;
//   int timeLeft = 30;
//   bool isGameOver = false;
//   bool isPaused = false;

//   @override
//   void initState() {
//     super.initState();

//     game = BubbleGame();

//     /// 🎯 SCORE UPDATE
//     game.onBubblePop = () {
//       if (!isGameOver) {
//         setState(() {
//           score += 10;
//         });
//       }
//     };

//     final box = Hive.box('gameBox');
//     highScore = box.get('highScore', defaultValue: 0);

//     /// ⏱ START TIMER
//     startTimer();
//   }

//   void startTimer() {
//     timer = Timer.periodic(const Duration(seconds: 1), (t) {
//       if (timeLeft > 0) {
//         setState(() {
//           timeLeft--;
//         });
//         // } else {
//         //   t.cancel();
//         //   game.pauseEngine();

//         //   setState(() {
//         //     isGameOver = true;
//         //   });
//         // }
//       } else {
//         t.cancel();
//         game.pauseEngine();

//         final box = Hive.box('gameBox');

//         if (score > highScore) {
//           highScore = score;
//           box.put('highScore', highScore); // ✅ SAVE
//         }

//         setState(() {
//           isGameOver = true;
//         });
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
//     });

//     game = BubbleGame();

//     game.onBubblePop = () {
//       setState(() {
//         score += 10;
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
//           /// 🎮 BACKGROUND
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

//           /// 🔥 TOP BAR
//           SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   _circleButton(Icons.arrow_back, () {
//                     Navigator.pop(context);
//                   }),

//                   /// SCORE + TIMER
//                   Row(
//                     children: [
//                       _glassContainer(
//                         Row(
//                           children: [
//                             const Icon(Icons.star, color: Colors.yellow),
//                             const SizedBox(width: 6),
//                             Text(
//                               "$score",
//                               style: const TextStyle(color: Colors.white),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(width: 10),
//                       _glassContainer(
//                         Row(
//                           children: [
//                             const Icon(Icons.timer, color: Colors.white),
//                             const SizedBox(width: 6),
//                             Text(
//                               "$timeLeft s",
//                               style: const TextStyle(color: Colors.white),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),

//                   /// PAUSE
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

//           /// 🔥 BOTTOM TEXT
//           Align(
//             alignment: Alignment.bottomCenter,
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: _glassContainer(
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: const [
//                     Text(
//                       "Relax & Breathe",
//                       style: TextStyle(color: Colors.white),
//                     ),
//                     Text(
//                       "Tap bubbles 🫧",
//                       style: TextStyle(color: Colors.white70),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),

//           /// 🛑 GAME OVER SCREEN
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
//                       const SizedBox(height: 20),
//                       Text("High Score: $highScore"),

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

//   /// 🔘 BUTTON
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

//   /// 🧊 GLASS UI
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
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:hive/hive.dart';
import '../../games/bubble_game.dart';

class BubbleGameScreen extends StatefulWidget {
  const BubbleGameScreen({super.key});

  @override
  State<BubbleGameScreen> createState() => _BubbleGameScreenState();
}

class _BubbleGameScreenState extends State<BubbleGameScreen>
    with TickerProviderStateMixin {

  late BubbleGame game;
  late Timer timer;

  int score     = 0;
  int highScore = 0;
  int timeLeft  = 30;
  bool isGameOver = false;
  bool isPaused   = false;

  late AnimationController _scoreAnim;
  late Animation<double>   _scoreScale;
  late AnimationController _gameOverAnim;
  late Animation<double>   _gameOverScale;

  @override
  void initState() {
    super.initState();

    // ── Animations ───────────────────────────────────────────
    _scoreAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _scoreScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _scoreAnim, curve: Curves.easeOut));

    _gameOverAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _gameOverScale =
        CurvedAnimation(parent: _gameOverAnim, curve: Curves.elasticOut);

    // ── Game setup ───────────────────────────────────────────
    game = BubbleGame();

    game.onBubblePop = () {
      if (!isGameOver) {
        setState(() => score += 10);
        _scoreAnim.forward(from: 0);
      }
    };

    final box = Hive.box('gameBox');
    highScore = box.get('highScore', defaultValue: 0);

    startTimer();
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
          box.put('highScore', highScore);
        }

        setState(() => isGameOver = true);
        _gameOverAnim.forward();
      }
    });
  }

  void restartGame() {
    timer.cancel();

    setState(() {
      score     = 0;
      timeLeft  = 30;
      isGameOver = false;
      isPaused   = false;
    });

    _gameOverAnim.reset();

    game = BubbleGame();
    game.onBubblePop = () {
      setState(() => score += 10);
      _scoreAnim.forward(from: 0);
    };

    game.resumeEngine();
    startTimer();
  }

  @override
  void dispose() {
    timer.cancel();
    _scoreAnim.dispose();
    _gameOverAnim.dispose();
    super.dispose();
  }

  Color get _timerColor {
    if (timeLeft > 15) return const Color(0xFF4BFF91);
    if (timeLeft > 8)  return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Background ──────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D1F14), Color(0xFF1A3828), Color(0xFF2A5040)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ── Subtle radial glow in center ────────────────────
          Center(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00C96A).withOpacity(0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Flame game canvas ───────────────────────────────
          GameWidget(game: game),

          // ── Top HUD ─────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Back button
                  _PremiumIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context), highlight: false ,
                  ),

                  const SizedBox(width: 10),

                  // Score chip
                  AnimatedBuilder(
                    animation: _scoreScale,
                    builder: (_, child) =>
                        Transform.scale(scale: _scoreScale.value, child: child),
                    child: _HudChip(
                      label: 'SCORE',
                      value: '$score',
                      valueColor: const Color(0xFFFFD700),
                      borderColor: const Color(0xFFFFD700),
                    ),
                  ),

                  const Spacer(),

                  // Timer ring
                  _TimerRing(timeLeft: timeLeft, color: _timerColor),

                  const Spacer(),

                  // Best chip
                  _HudChip(
                    label: 'BEST',
                    value: '$highScore',
                    valueColor: const Color(0xFF7DF9C8),
                    borderColor: const Color(0xFF00E5A0),
                  ),

                  const SizedBox(width: 10),

                  // Pause button
                  // _PremiumIconButton(
                  //   icon: isPaused
                  //       ? Icons.play_arrow_rounded
                  //       : Icons.pause_rounded,
                  //   onTap: () {
                  //     setState(() {
                  //       isPaused = !isPaused;
                  //       isPaused ? game.pauseEngine() : game.resumeEngine();
                  //     });
                  //   },
                  //   highlight: isPaused,
                  // ),
                ],
              ),
            ),
          ),

          // ── Bottom hint bar ──────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Relax & Breathe',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      Text(
                        'Tap bubbles 🫧',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 12,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Game Over overlay ────────────────────────────────
          if (isGameOver)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: ScaleTransition(
                  scale: _gameOverScale,
                  child: _GameOverCard(
                    score: score,
                    highScore: highScore,
                    onRestart: restartGame,
                    onExit: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium Icon Button
// ─────────────────────────────────────────────────────────────────────────────
class _PremiumIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool highlight;

  const _PremiumIconButton({
    required this.icon,
    required this.onTap, required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: highlight
              ? const Color(0xFF4BFF91).withOpacity(0.15)
              : Colors.black.withOpacity(0.35),
          border: Border.all(
            color: highlight
                ? const Color(0xFF4BFF91).withOpacity(0.6)
                : Colors.white.withOpacity(0.15),
            width: 1.5,
          ),
          boxShadow: highlight
              ? [
                  BoxShadow(
                    color: const Color(0xFF4BFF91).withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: Icon(
          icon,
          color: highlight ? const Color(0xFF4BFF91) : Colors.white70,
          size: 18,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HUD Chip  (same as emoji game)
// ─────────────────────────────────────────────────────────────────────────────
class _HudChip extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final Color borderColor;

  const _HudChip({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.2),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              decoration: TextDecoration.none,
              color: valueColor.withOpacity(0.6),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              decoration: TextDecoration.none,
              color: valueColor,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Timer Ring  (same as emoji game)
// ─────────────────────────────────────────────────────────────────────────────
class _TimerRing extends StatelessWidget {
  final int timeLeft;
  final Color color;

  const _TimerRing({required this.timeLeft, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.45),
        border: Border.all(color: color.withOpacity(0.65), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.28),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$timeLeft',
            style: TextStyle(
              decoration: TextDecoration.none,
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              height: 1,
            ),
          ),
          Text(
            'sec',
            style: TextStyle(
              decoration: TextDecoration.none,
              color: color.withOpacity(0.55),
              fontSize: 9,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Game Over Card
// ─────────────────────────────────────────────────────────────────────────────
class _GameOverCard extends StatelessWidget {
  final int score;
  final int highScore;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  const _GameOverCard({
    required this.score,
    required this.highScore,
    required this.onRestart,
    required this.onExit,
  });

  String get _medal {
    if (score >= 200) return '🏆';
    if (score >= 150) return '🥇';
    if (score >= 80)  return '🥈';
    if (score >= 30)  return '🥉';
    return '😅';
  }

  bool get _isNewRecord => score > 0 && score >= highScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 310,
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2419), Color(0xFF1C4030)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.65),
            blurRadius: 50,
            spreadRadius: 12,
          ),
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.1),
            blurRadius: 35,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_medal, style: const TextStyle(fontSize: 60)),
          const SizedBox(height: 8),
          const Text(
            'GAME  OVER',
            style: TextStyle(
              decoration: TextDecoration.none,
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 5,
            ),
          ),
          const SizedBox(height: 22),
          _divider(),
          const SizedBox(height: 16),
          _ScoreRow(
            label: 'YOUR SCORE',
            value: '$score pts',
            color: const Color(0xFFFFD700),
          ),
          const SizedBox(height: 12),
          if (_isNewRecord)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.45),
                ),
              ),
              child: const Text(
                '✨  NEW RECORD!  ✨',
                textAlign: TextAlign.center,
                style: TextStyle(
                  decoration: TextDecoration.none,
                  color: Color(0xFFFFD700),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            )
          else
            _ScoreRow(
              label: 'BEST',
              value: '$highScore pts',
              color: const Color(0xFF7DF9C8),
            ),
          const SizedBox(height: 16),
          _divider(),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _GoldButton(
                  label: '🔁  Play Again',
                  onTap: onRestart,
                  primary: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GoldButton(
                  label: '🚪  Exit',
                  onTap: onExit,
                  primary: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.transparent,
            Colors.white.withOpacity(0.15),
            Colors.transparent,
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Score Row
// ─────────────────────────────────────────────────────────────────────────────
class _ScoreRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ScoreRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            decoration: TextDecoration.none,
            color: color.withOpacity(0.55),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            decoration: TextDecoration.none,
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gold Button
// ─────────────────────────────────────────────────────────────────────────────
class _GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool primary;

  const _GoldButton({
    required this.label,
    required this.onTap,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: primary
              ? const LinearGradient(
                  colors: [Color(0xFF4BFF91), Color(0xFF00C96A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: primary ? null : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: primary
                ? Colors.transparent
                : Colors.white.withOpacity(0.2),
            width: 1.2,
          ),
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: const Color(0xFF00C96A).withOpacity(0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            decoration: TextDecoration.none,
            color: primary ? const Color(0xFF0A1F12) : Colors.white60,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}