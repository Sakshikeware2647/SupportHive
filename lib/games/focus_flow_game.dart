import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class FocusFlowGame extends ChangeNotifier {
  Offset position = const Offset(150, 300);

  final random = Random();

  int  score      = 0;
  int  highScore  = 0;
  int  timeLeft   = 30;
  bool isGameOver = false;
  bool isTouching = false;

  Timer? moveTimer;
  Timer? gameTimer;

  // ── Start ─────────────────────────────────────────────
  void startGame() {
    score      = 0;
    timeLeft   = 30;
    isGameOver = false;
    isTouching = false;
    _moveDot();
    _startTimer();
  }

  void setHighScore(int value) {
    highScore = value;
  }

  // ── Dot movement ──────────────────────────────────────
  void _moveDot() {
    moveTimer = Timer.periodic(const Duration(milliseconds: 900), (t) {
      if (isGameOver) {
        t.cancel();
        return;
      }
      // when dot moves, finger is no longer on it
      isTouching = false;
      position   = Offset(
        random.nextDouble() * 300,
        random.nextDouble() * 600,
      );
      notifyListeners();
    });
  }

  // ── Game timer + scoring ──────────────────────────────
  void _startTimer() {
    gameTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timeLeft > 0) {
        timeLeft--;
        if (isTouching) score += 5;
        notifyListeners();
      } else {
        t.cancel();
        isGameOver = true;
        notifyListeners();
      }
    });
  }

  // ── Touch ─────────────────────────────────────────────
  void setTouch(bool value) {
    isTouching = value;
    notifyListeners();
  }

  // ── Dispose ───────────────────────────────────────────
  void disposeGame() {
    moveTimer?.cancel();
    gameTimer?.cancel();
  }
}




// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/material.dart';

// class FocusFlowGame extends ChangeNotifier {
//   Offset position          = const Offset(150, 300);
//   Offset? lastTouchPosition;

//   final random = Random();

//   int  score      = 0;
//   int  highScore  = 0;
//   int  timeLeft   = 30;
//   bool isGameOver = false;
//   bool isTouching = false;

//   Timer? moveTimer;
//   Timer? gameTimer;

//   // ── Start ─────────────────────────────────────────────
//   void startGame() {
//     score             = 0;
//     timeLeft          = 30;
//     isGameOver        = false;
//     isTouching        = false;
//     lastTouchPosition = null;
//     _moveDot();
//     _startTimer();
//   }

//   void setHighScore(int value) {
//     highScore = value;
//   }

//   // ── Dot movement ──────────────────────────────────────
//   void _moveDot() {
//     moveTimer = Timer.periodic(const Duration(milliseconds: 900), (t) {
//       if (isGameOver) {
//         t.cancel();
//         return;
//       }
//       position = Offset(
//         random.nextDouble() * 300,
//         random.nextDouble() * 600,
//       );
//       notifyListeners();
//     });
//   }

//   // ── Game timer + scoring ──────────────────────────────
//   void _startTimer() {
//     gameTimer = Timer.periodic(const Duration(seconds: 1), (t) {
//       if (timeLeft > 0) {
//         timeLeft--;
//         // ✅ score only if finger is on dot right now
//         if (isTouching && _isFingerOnDot()) score += 5;
//         notifyListeners();
//       } else {
//         t.cancel();
//         isGameOver = true;
//         notifyListeners();
//       }
//     });
//   }

//   // ✅ Check finger position against dot position directly
//   // dot is 70x70, position is top-left corner
//   bool _isFingerOnDot() {
//     if (lastTouchPosition == null) return false;
//     final dotCenter = Offset(position.dx + 35, position.dy + 35);
//     final distance  = (lastTouchPosition! - dotCenter).distance;
//     return distance <= 35;
//   }

//   // ── Touch — called with screen-level local position ───
//   void setTouch(bool value, [Offset? pos]) {
//     isTouching        = value;
//     lastTouchPosition = value ? pos : null;
//     notifyListeners();
//   }

//   // ── Dispose ───────────────────────────────────────────
//   void disposeGame() {
//     moveTimer?.cancel();
//     gameTimer?.cancel();
//   }
// }