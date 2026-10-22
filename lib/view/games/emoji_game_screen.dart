// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flame/game.dart';
// import '../../games/emoji_game.dart';

// class EmojiGameScreen extends StatefulWidget {
//   const EmojiGameScreen({super.key});

//   @override
//   State<EmojiGameScreen> createState() => _EmojiGameScreenState();
// }

// class _EmojiGameScreenState extends State<EmojiGameScreen> {
//   late EmojiGame game;
//   late Timer timer;

//   int score = 0;
//   int timeLeft = 30;
//   bool isGameOver = false;

//   @override
//   void initState() {
//     super.initState();

//     game = EmojiGame();

//     game.onCatch = (type) {
//       if (isGameOver) return;

//       setState(() {
//         if (type == "good") {
//           score += 10;
//         } else {
//           score -= 10;
//         }
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
//         setState(() => isGameOver = true);
//       }
//     });
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
//           /// 🌿 BACKGROUND
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

//           /// 🔝 UI
//           SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text("Score: $score",
//                       style: const TextStyle(color: Colors.white)),
//                   Text("⏱ $timeLeft",
//                       style: const TextStyle(color: Colors.white)),
//                 ],
//               ),
//             ),
//           ),

//           /// 🛑 GAME OVER
//           if (isGameOver)
//             Center(
//               child: Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Text("Game Over"),
//                     Text("Score: $score"),
//                     ElevatedButton(
//                       onPressed: () {
//                         Navigator.pop(context);
//                       },
//                       child: const Text("Exit"),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }



import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../games/emoji_game.dart';

// ─────────────────────────────────────────────────────────────────────────────
// High Score
// ─────────────────────────────────────────────────────────────────────────────
class HighScoreService {
  static const _key = 'emoji_game_high_score';
  static Future<int> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? 0;
  }
  static Future<void> save(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_key) ?? 0;
    if (score > current) await prefs.setInt(_key, score);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen — uses GameWidget.controlled so it owns the full screen
// The HUD is passed via overlayBuilderMap which Flame renders INSIDE the game
// widget on top of the canvas — guaranteed full screen, no layout issues
// ─────────────────────────────────────────────────────────────────────────────
class EmojiGameScreen extends StatefulWidget {
  const EmojiGameScreen({super.key});

  @override
  State<EmojiGameScreen> createState() => _EmojiGameScreenState();
}

class _EmojiGameScreenState extends State<EmojiGameScreen>
    with TickerProviderStateMixin {

  int score     = 0;
  int timeLeft  = 30;
  int highScore = 0;
  bool isGameOver  = false;
  bool isNewRecord = false;

  late EmojiGame _game;
  Timer? _timer;

  late AnimationController _scoreAnim;
  late Animation<double>   _scoreScale;
  late AnimationController _gameOverAnim;
  late Animation<double>   _gameOverScale;
  late AnimationController _recordAnim;
  late Animation<double>   _recordOpacity;

  @override
  void initState() {
    super.initState();

    _game = EmojiGame();

    _scoreAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _scoreScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _scoreAnim, curve: Curves.easeOut));

    _gameOverAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _gameOverScale = CurvedAnimation(parent: _gameOverAnim, curve: Curves.elasticOut);

    _recordAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _recordOpacity = Tween(begin: 0.35, end: 1.0)
        .animate(CurvedAnimation(parent: _recordAnim, curve: Curves.easeInOut));

    HighScoreService.load().then((v) => setState(() => highScore = v));

    _game.onCatch = (type) {
      if (isGameOver) return;
      setState(() {
        score += type == 'good' ? 10 : -10;
        if (score < 0) score = 0;
      });
      _scoreAnim.forward(from: 0);
    };

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timeLeft > 0) {
        setState(() => timeLeft--);
      } else {
        t.cancel();
        _game.pauseEngine();
        _endGame();
      }
    });
  }

  Future<void> _endGame() async {
  await HighScoreService.save(score);
  final newHigh = await HighScoreService.load();
  setState(() {
    isGameOver  = true;
    highScore   = newHigh;
    isNewRecord = score >= newHigh && score > 0;
  });
  _gameOverAnim.forward();

  // ✅ ADD THIS — tells Flame to show the 'gameover' overlay
  _game.overlays.add('gameover');
}

  @override
  void dispose() {
    _timer?.cancel();
    _scoreAnim.dispose();
    _gameOverAnim.dispose();
    _recordAnim.dispose();
    super.dispose();
  }

  Color get _timerColor {
    if (timeLeft > 15) return const Color(0xFF4BFF91);
    if (timeLeft > 8)  return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    /// ✅ GameWidget.controlled fills 100% of the screen by default.
    /// overlayBuilderMap renders Flutter widgets INSIDE the game's own widget
    /// tree — so they are always positioned correctly over the Flame canvas
    /// regardless of any parent layout constraints.
    return GameWidget<EmojiGame>.controlled(
      gameFactory: () => _game,
      overlayBuilderMap: {
        'hud': (context, game) => _buildHud(),
        'gameover': (context, game) => _buildGameOver(),
      },
      initialActiveOverlays: const ['hud'],
    );
  }

  Widget _buildHud() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Score
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

            // Timer
            _TimerRing(timeLeft: timeLeft, color: _timerColor),

            const Spacer(),

            // Best
            _HudChip(
              label: 'BEST',
              value: '$highScore',
              valueColor: const Color(0xFF7DF9C8),
              borderColor: const Color(0xFF00E5A0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOver() {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: ScaleTransition(
          scale: _gameOverScale,
          child: _GameOverCard(
            score: score,
            highScore: highScore,
            isNewRecord: isNewRecord,
            recordOpacity: _recordOpacity,
            onExit: () => Navigator.pop(context),
            onRestart: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const EmojiGameScreen()),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HUD Chip
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
          Text(label,
              style: TextStyle(
                decoration: TextDecoration.none, // ✅ ADD
                color: valueColor.withOpacity(0.6),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5,
              )),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                decoration: TextDecoration.none, // ✅ ADD
                color: valueColor,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                height: 1,
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Timer Ring
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
          Text('$timeLeft',
              style: TextStyle(
                decoration: TextDecoration.none, // ✅ ADD
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                height: 1,
              )),
          Text('sec',
              style: TextStyle(
                decoration: TextDecoration.none, // ✅ ADD
                color: color.withOpacity(0.55),
                fontSize: 9,
                letterSpacing: 1.5,
              )),
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
  final bool isNewRecord;
  final Animation<double> recordOpacity;
  final VoidCallback onExit;
  final VoidCallback onRestart;

  const _GameOverCard({
    required this.score,
    required this.highScore,
    required this.isNewRecord,
    required this.recordOpacity,
    required this.onExit,
    required this.onRestart,
  });

  String get _medal {
    if (score >= 200) return '🏆';
    if (score >= 150) return '🥇';
    if (score >= 80)  return '🥈';
    if (score >= 30)  return '🥉';
    return '😅';
  }

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
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.65), blurRadius: 50, spreadRadius: 12),
          BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.1), blurRadius: 35, spreadRadius: 4),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_medal, style: const TextStyle(  decoration: TextDecoration.none,fontSize: 60)),
          const SizedBox(height: 8),
          const Text('GAME  OVER',
              style: TextStyle(
                decoration: TextDecoration.none, // ✅ ADD
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 5,
              )),
          const SizedBox(height: 22),
          _divider(),
          const SizedBox(height: 16),
          _ScoreRow(label: 'YOUR SCORE', value: '$score pts', color: const Color(0xFFFFD700)),
          const SizedBox(height: 12),
          if (isNewRecord)
            FadeTransition(
              opacity: recordOpacity,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.45)),
                ),
                child: const Text('✨  NEW RECORD!  ✨',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    )),
              ),
            )
          else
            _ScoreRow(label: 'BEST', value: '$highScore pts', color: const Color(0xFF7DF9C8)),
          const SizedBox(height: 16),
          _divider(),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: _GoldButton(label: '🔁  Play Again', onTap: onRestart, primary: true)),
              const SizedBox(width: 10),
              Expanded(child: _GoldButton(label: '🚪  Exit', onTap: onExit, primary: false)),
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

class _ScoreRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ScoreRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(  decoration: TextDecoration.none,color: color.withOpacity(0.55), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2.5)),
        Text(value, style: TextStyle(  decoration: TextDecoration.none,color: color, fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
      ],
    );
  }
}


class _GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool primary;
  const _GoldButton({required this.label, required this.onTap, required this.primary});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: primary ? const LinearGradient(
            colors: [Color(0xFF4BFF91), Color(0xFF00C96A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ) : null,
          color: primary ? null : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: primary ? Colors.transparent : Colors.white.withOpacity(0.2),
            width: 1.2,
          ),
          boxShadow: primary ? [BoxShadow(color: const Color(0xFF00C96A).withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 4))] : [],
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              decoration: TextDecoration.none, // ✅ ADD
              color: primary ? const Color(0xFF0A1F12) : Colors.white60,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 0.5,
            )),
      ),
    );
  }
}

