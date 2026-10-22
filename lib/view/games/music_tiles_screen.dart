import 'dart:async';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../games/music_tiles_game.dart';

// ─────────────────────────────────────────────
//  Constants
// ─────────────────────────────────────────────
const int _kGameDuration = 30;
const String _kHiveBox = 'gameBox';
const String _kHighScoreKey = 'musicTilesHighScore';

// ─────────────────────────────────────────────
//  Screen
// ─────────────────────────────────────────────
class MusicTilesScreen extends StatefulWidget {
  const MusicTilesScreen({super.key});

  @override
  State<MusicTilesScreen> createState() => _MusicTilesScreenState();
}

class _MusicTilesScreenState extends State<MusicTilesScreen>
    with SingleTickerProviderStateMixin {
  late MusicTilesGame _game;
  Timer? _timer;

  int _score = 0;
  int _combo = 0;
  int _highScore = 0;
  int _timeLeft = _kGameDuration;
  bool _isGameOver = false;

  /// Animation controller for the game-over overlay fade-in.
  late final AnimationController _overlayController;
  late final Animation<double> _overlayFade;

  // ── Lifecycle ──────────────────────────────

  @override
  void initState() {
    super.initState();

    _overlayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _overlayFade = CurvedAnimation(
      parent: _overlayController,
      curve: Curves.easeOut,
    );

    _loadHighScore();
    _initGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _overlayController.dispose();
    super.dispose();
  }

  // ── Initialisation ─────────────────────────

  void _loadHighScore() {
    if (!Hive.isBoxOpen(_kHiveBox)) return;
    _highScore = Hive.box(_kHiveBox).get(
      _kHighScoreKey,
      defaultValue: 0,
    ) as int;
  }

  void _initGame() {
    _game = MusicTilesGame();
    _game.onTileTap = _handleTileTap;
    _startTimer();
  }

  // ── Timer ──────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        t.cancel();
        _endGame();
      }
    });
  }

  // ── Game logic ─────────────────────────────

  void _handleTileTap(bool hit) {
    if (_isGameOver) return;
    setState(() {
      if (hit) {
        _combo++;
        _score += 10 + _combo;
      } else {
        _combo = 0;
        // ✅ Score never goes below zero.
        _score = max(0, _score - 5);
      }
    });
  }

  void _endGame() {
    _game.pauseEngine();
    _saveHighScore();
    setState(() => _isGameOver = true);
    _overlayController.forward(); // animate the overlay in
  }

  void _saveHighScore() {
    if (!Hive.isBoxOpen(_kHiveBox)) return;
    if (_score > _highScore) {
      _highScore = _score;
      Hive.box(_kHiveBox).put(_kHighScoreKey, _highScore);
    }
  }

  /// ✅ Resets everything in-place — no Navigator rebuild required.
  void _restartGame() {
    _timer?.cancel();
    _overlayController.reset();

    setState(() {
      _score = 0;
      _combo = 0;
      _timeLeft = _kGameDuration;
      _isGameOver = false;
    });

    _game.resetGame();
    _startTimer();
  }

  // ── Build ──────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🌌 Background gradient
          const _Background(),

          // 🎮 Flame game canvas
          GameWidget(game: _game),

          // 🔝 Top HUD row
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  HudCard(label: '⭐ $_score', color: Colors.cyanAccent),
                  HudCard(label: '🔥 $_combo', color: Colors.orangeAccent),
                  HudCard(label: '⏱ $_timeLeft', color: Colors.white),
                ],
              ),
            ),
          ),

          // 🏆 Best score (below top bar)
          Positioned(
            top: 90,
            left: 16,
            child: HudCard(label: '🏆 $_highScore', color: Colors.greenAccent),
          ),

          // 🛑 Game-over overlay (animated)
          if (_isGameOver)
            FadeTransition(
              opacity: _overlayFade,
              child: _GameOverOverlay(
                score: _score,
                highScore: _highScore,
                onRestart: _restartGame,
                onExit: () => Navigator.pop(context),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Sub-widgets
// ─────────────────────────────────────────────

/// Dark translucent pill used in the HUD.
///
/// Extracted as a [StatelessWidget] so it doesn't rebuild on
/// every [setState] call in the parent screen.
class HudCard extends StatelessWidget {
  const HudCard({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.2), blurRadius: 20),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Dark gradient that fills the screen behind the game.
class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF030712),
            Color(0xFF111827),
            Color(0xFF1E293B),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

/// Semi-transparent overlay shown at game end.
class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({
    required this.score,
    required this.highScore,
    required this.onRestart,
    required this.onExit,
  });

  final int score;
  final int highScore;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final isNewBest = score >= highScore && score > 0;

    return Container(
      color: Colors.black.withOpacity(0.65),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.cyanAccent),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.15),
                blurRadius: 40,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🎵 Rhythm Complete',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Score: $score',
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                isNewBest ? '🎉 New Best: $highScore' : 'Best: $highScore',
                style: TextStyle(
                  color: isNewBest ? Colors.yellowAccent : Colors.greenAccent,
                  fontSize: 18,
                  fontWeight:
                      isNewBest ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRestart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Play Again',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onExit,
                child: const Text(
                  'Exit',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}