// import 'dart:async';
// import 'dart:math';

// import 'package:flutter/material.dart';

// class FoodItem {
//   final String emoji;
//   final bool good;

//   FoodItem({
//     required this.emoji,
//     required this.good,
//   });
// }

// class FeedPetGame extends ChangeNotifier {
//   final Random random = Random();

//   int score = 0;
//   int mood = 50;
//   int timeLeft = 30;

//   bool isGameOver = false;

//   late Timer timer;

//   final List<FoodItem> foods = [
//     FoodItem(emoji: "🍎", good: true),
//     FoodItem(emoji: "🥕", good: true),
//     FoodItem(emoji: "🍓", good: true),
//     FoodItem(emoji: "🍕", good: false),
//     FoodItem(emoji: "🍔", good: false),
//     FoodItem(emoji: "🍟", good: false),
//   ];

//   late FoodItem currentFood;

//   void startGame() {
//     generateFood();

//     timer = Timer.periodic(
//       const Duration(seconds: 1),
//       (t) {
//         if (timeLeft > 0) {
//           timeLeft--;
//         } else {
//           isGameOver = true;
//           t.cancel();
//         }

//         notifyListeners();
//       },
//     );
//   }

//   void generateFood() {
//     currentFood =
//         foods[random.nextInt(foods.length)];

//     notifyListeners();
//   }

//   void feedPet() {
//     if (currentFood.good) {
//       score += 10;
//       mood += 8;
//     } else {
//       score -= 5;
//       mood -= 10;
//     }

//     if (mood > 100) mood = 100;
//     if (mood < 0) mood = 0;

//     generateFood();

//     notifyListeners();
//   }

//   void disposeGame() {
//     timer.cancel();
//   }
// }






import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

class FoodItem {
  final String emoji;
  final bool good;
  final String name;

  const FoodItem({
    required this.emoji,
    required this.good,
    required this.name,
  });
}

enum FeedResult { good, bad, missed }

class FeedPetGame extends ChangeNotifier {
  final Random _random = Random();

  // === Game State ===
  int score = 0;
  int mood = 50;
  int timeLeft = 30;
  int combo = 0;
  int bestCombo = 0;
  FeedResult? lastResult;
  int lastPoints = 0;

  bool isGameOver = false;
  bool _isStarted = false;

  Timer? _timer;
  FoodItem? _previousFood;

  static const int gameDuration = 30;
  static const int maxMood = 100;
  static const int minMood = 0;

  static const List<FoodItem> foods = [
    FoodItem(emoji: "🍎", good: true, name: "Apple"),
    FoodItem(emoji: "🥕", good: true, name: "Carrot"),
    FoodItem(emoji: "🍓", good: true, name: "Strawberry"),
    FoodItem(emoji: "🥦", good: true, name: "Broccoli"),
    FoodItem(emoji: "🍌", good: true, name: "Banana"),
    FoodItem(emoji: "🍕", good: false, name: "Pizza"),
    FoodItem(emoji: "🍔", good: false, name: "Burger"),
    FoodItem(emoji: "🍟", good: false, name: "Fries"),
    FoodItem(emoji: "🍩", good: false, name: "Donut"),
    FoodItem(emoji: "🍫", good: false, name: "Chocolate"),
  ];

  late FoodItem currentFood;

  /// Mood-based difficulty multiplier
  double get difficultyMultiplier {
    if (timeLeft < 10) return 1.5;
    if (timeLeft < 20) return 1.2;
    return 1.0;
  }

  void startGame() {
    if (_isStarted) return;
    _isStarted = true;

    score = 0;
    mood = 50;
    timeLeft = gameDuration;
    combo = 0;
    bestCombo = 0;
    isGameOver = false;
    lastResult = null;
    lastPoints = 0;

    _generateFood();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (t) {
        if (timeLeft > 0) {
          timeLeft--;
          // Mood naturally decays over time
          if (mood > 0) mood = (mood - 1).clamp(minMood, maxMood);
        }

        if (timeLeft <= 0 || mood <= 0) {
          _endGame();
          t.cancel();
        }

        notifyListeners();
      },
    );
  }

  void resetGame() {
    _timer?.cancel();
    _isStarted = false;
    startGame();
  }

  void _endGame() {
    isGameOver = true;
    _isStarted = false;
  }

  void _generateFood() {
    FoodItem next;
    // Avoid showing same food twice in a row
    do {
      next = foods[_random.nextInt(foods.length)];
    } while (foods.length > 1 && next == _previousFood);

    _previousFood = next;
    currentFood = next;
  }

  void feedPet() {
    if (isGameOver) return;

    if (currentFood.good) {
      combo++;
      if (combo > bestCombo) bestCombo = combo;

      // Combo bonus: more reward for consecutive good choices
      final bonus = (combo ~/ 3) * 5;
      lastPoints = 10 + bonus;
      score += lastPoints;
      mood = (mood + 8).clamp(minMood, maxMood);
      lastResult = FeedResult.good;
    } else {
      combo = 0;
      lastPoints = -5;
      score = (score - 5).clamp(0, 999999);
      mood = (mood - 12).clamp(minMood, maxMood);
      lastResult = FeedResult.bad;
    }

    _generateFood();
    notifyListeners();
  }

  void clearLastResult() {
    lastResult = null;
    notifyListeners();
  }

  void disposeGame() {
    _timer?.cancel();
    _timer = null;
    _isStarted = false;
  }

  @override
  void dispose() {
    disposeGame();
    super.dispose();
  }
}