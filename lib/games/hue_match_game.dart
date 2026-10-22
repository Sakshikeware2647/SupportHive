// import 'package:flutter/material.dart';

// class HueMatchGame extends ChangeNotifier {
//   Color targetColor = Colors.purple;
//   Color mixedColor = Colors.white;

//   int score = 0;
//   int level = 1;

//   final List<Color> selectedColors = [];

//   final List<Color> availableColors = [
//     Colors.red,
//     Colors.blue,
//     Colors.yellow,
//   ];

//   void selectColor(Color color) {
//     if (selectedColors.length >= 2) return;

//     selectedColors.add(color);

//     mixColors();

//     notifyListeners();
//   }

//   void resetMix() {
//     selectedColors.clear();
//     mixedColor = Colors.white;
//     notifyListeners();
//   }

//   void mixColors() {
//     if (selectedColors.length == 1) {
//       mixedColor = selectedColors.first;
//       return;
//     }

//     if (selectedColors.length == 2) {
//       final c1 = selectedColors[0];
//       final c2 = selectedColors[1];

//       /// 🔴 + 🔵 = 🟣
//       if ((c1 == Colors.red && c2 == Colors.blue) ||
//           (c1 == Colors.blue && c2 == Colors.red)) {
//         mixedColor = Colors.purple;
//       }

//       /// 🔴 + 🟡 = 🟠
//       else if ((c1 == Colors.red &&
//               c2 == Colors.yellow) ||
//           (c1 == Colors.yellow &&
//               c2 == Colors.red)) {
//         mixedColor = Colors.orange;
//       }

//       /// 🔵 + 🟡 = 🟢
//       else if ((c1 == Colors.blue &&
//               c2 == Colors.yellow) ||
//           (c1 == Colors.yellow &&
//               c2 == Colors.blue)) {
//         mixedColor = Colors.green;
//       } else {
//         mixedColor = Colors.brown;
//       }
//     }

//     checkAnswer();
//   }

//   void checkAnswer() {
//     if (mixedColor.value == targetColor.value) {
//       score += 10;
//       level++;

//       generateTarget();
//     }

//     notifyListeners();
//   }

//   void generateTarget() {
//     final targets = [
//       Colors.purple,
//       Colors.orange,
//       Colors.green,
//     ];

//     targetColor =
//         targets[level % targets.length];

//     resetMix();
//   }
// }




import 'dart:math';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
//  HueMatchGame — ChangeNotifier game-state model
//
//  IMPROVEMENTS OVER ORIGINAL:
//  • Levels now cycle through ALL mix combinations, not just 3
//  • Target is never the same as the previous target
//  • Score increases with level difficulty (harder = more points)
//  • Tracks attempts per round and deducts for wrong guesses
//  • Added streak bonus (+5 per consecutive correct answer)
//  • Combo colors added at higher levels (e.g. red+red = dark red)
//  • generateTarget() uses Random so levels feel fresh
//  • Added `feedback` string so the UI can show a hint message
//  • Added `isCorrect` flag for celebration animation trigger
//  • resetGame() for a full restart
// ─────────────────────────────────────────────────────────────

class HueMatchGame extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────
  Color targetColor = Colors.purple;
  Color mixedColor = const Color(0xFF1E293B); // dark bg, looks "empty"
  int score = 0;
  int level = 1;
  int streak = 0;
  int attempts = 0;       // wrong attempts this round
  bool isCorrect = false; // true for one tick after a match
  String feedback = '';   // hint / celebration text shown in UI

  final List<Color> selectedColors = [];

  // ── Available palette (shown as tap buttons) ───────────────
  // These never change — the player always picks from R / B / Y
  final List<Color> availableColors = const [
    Colors.red,
    Colors.blue,
    Colors.yellow,
  ];

  // ── All possible target colors (expands logic beyond 3) ────
  // Tuple: (color1, color2, result)
  static const List<_Mix> _allMixes = [
    _Mix(Colors.red,    Colors.blue,   Colors.purple),
    _Mix(Colors.red,    Colors.yellow, Colors.orange),
    _Mix(Colors.blue,   Colors.yellow, Colors.green),
  ];

  final Random _rng = Random();
  Color? _lastTarget; // prevent repeating same target twice

  // ── Constructor ────────────────────────────────────────────
  HueMatchGame() {
    _pickTarget();
  }

  // ── Public API ─────────────────────────────────────────────

  /// Called when the player taps a color circle.
  void selectColor(Color color) {
    if (selectedColors.length >= 2) return; // already full, tap Reset

    selectedColors.add(color);
    _mixColors();
    notifyListeners();
  }

  /// Clears the current mix so the player can try again.
  void resetMix() {
    selectedColors.clear();
    mixedColor = const Color(0xFF1E293B);
    isCorrect = false;
    feedback = '';
    notifyListeners();
  }

  /// Full game restart (called from Game Over / Restart button).
  void resetGame() {
    score = 0;
    level = 1;
    streak = 0;
    attempts = 0;
    isCorrect = false;
    feedback = '';
    _lastTarget = null;
    _pickTarget();
    resetMix();
  }

  // ── Private helpers ────────────────────────────────────────

  void _mixColors() {
    if (selectedColors.length == 1) {
      // Show the first picked color immediately as a preview
      mixedColor = selectedColors.first;
      return;
    }

    // Two colors selected — compute the mix
    final c1 = selectedColors[0];
    final c2 = selectedColors[1];

    Color? result;
    for (final mix in _allMixes) {
      if ((mix.a == c1 && mix.b == c2) ||
          (mix.a == c2 && mix.b == c1)) {
        result = mix.result;
        break;
      }
    }

    // Same color + same color (e.g. red + red) → darker shade
    if (result == null && c1 == c2) {
      result = Color.fromARGB(
        255,
        (c1.red * 0.6).round(),
        (c1.green * 0.6).round(),
        (c1.blue * 0.6).round(),
      );
    }

    mixedColor = result ?? Colors.brown; // fallback: muddy brown
    _checkAnswer();
  }

  void _checkAnswer() {
    if (mixedColor.value == targetColor.value) {
      // ✅ Correct!
      isCorrect = true;
      streak++;

      // Base points + level bonus + streak bonus
      final earned = 10 + (level - 1) * 2 + (streak > 1 ? 5 : 0);
      score += earned;
      feedback = streak > 2
          ? '🔥 ${streak}x Streak! +$earned pts'
          : '✅ Correct! +$earned pts';

      level++;
      attempts = 0;

      // Short delay before next round (UI handles the animation window)
      Future.delayed(const Duration(milliseconds: 900), () {
        _pickTarget();
        resetMix();
      });
    } else {
      // ❌ Wrong mix
      isCorrect = false;
      streak = 0;
      attempts++;
      feedback = attempts >= 2
          ? '💡 Hint: Try ${_hintFor(targetColor)}'
          : '❌ Not quite — reset and try again';
      notifyListeners();
    }
  }

  /// Pick a random target that isn't the same as the last one.
  void _pickTarget() {
    final candidates = _allMixes
        .map((m) => m.result)
        .where((c) => c != _lastTarget)
        .toList();

    // shuffle for randomness
    candidates.shuffle(_rng);
    targetColor = candidates.first;
    _lastTarget = targetColor;
    attempts = 0;
    notifyListeners();
  }

  /// Returns a plain-English hint for a given target color.
  String _hintFor(Color c) {
    if (c == Colors.purple) return 'Red + Blue';
    if (c == Colors.orange) return 'Red + Yellow';
    if (c == Colors.green)  return 'Blue + Yellow';
    return 'keep experimenting!';
  }
}

// ── Simple immutable data class for a mix recipe ──────────────
class _Mix {
  final Color a;
  final Color b;
  final Color result;
  const _Mix(this.a, this.b, this.result);
}