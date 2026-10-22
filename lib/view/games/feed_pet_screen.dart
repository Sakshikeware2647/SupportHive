// import 'package:flutter/material.dart';
// import 'package:hive_flutter/hive_flutter.dart';

// import '../../games/feed_pet_game.dart';

// class FeedPetScreen extends StatefulWidget {
//   const FeedPetScreen({super.key});

//   @override
//   State<FeedPetScreen> createState() =>
//       _FeedPetScreenState();
// }

// class _FeedPetScreenState
//     extends State<FeedPetScreen>
//     with SingleTickerProviderStateMixin {
//   late FeedPetGame game;

//   late AnimationController petController;

//   int highScore = 0;

//   @override
//   void initState() {
//     super.initState();

//     final box = Hive.box('gameBox');

//     highScore = box.get(
//       'feedPetHighScore',
//       defaultValue: 0,
//     );

//     game = FeedPetGame()
//       ..startGame();

//     game.addListener(() {
//       saveHighScore();

//       setState(() {});
//     });

//     petController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 900),
//     )..repeat(reverse: true);
//   }

//   void saveHighScore() {
//     final box = Hive.box('gameBox');

//     if (game.score > highScore) {
//       highScore = game.score;

//       box.put(
//         'feedPetHighScore',
//         highScore,
//       );
//     }
//   }

//   @override
//   void dispose() {
//     game.disposeGame();
//     petController.dispose();
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
//         color: Colors.white.withOpacity(0.08),
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

//   Color moodColor() {
//     if (game.mood > 70) {
//       return Colors.greenAccent;
//     }

//     if (game.mood > 40) {
//       return Colors.orangeAccent;
//     }

//     return Colors.redAccent;
//   }

//   String petFace() {
//     if (game.mood > 70) {
//       return "🐶";
//     }

//     if (game.mood > 40) {
//       return "🐕";
//     }

//     return "🥺";
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
//                   Color(0xFF1B4332),
//                   Color(0xFF2D6A4F),
//                   Color(0xFF40916C),
//                 ],
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//               ),
//             ),
//           ),

//           SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 children: [
//                   /// 🔝 TOP BAR
//                   Row(
//                     mainAxisAlignment:
//                         MainAxisAlignment.spaceBetween,
//                     children: [
//                       hudCard(
//                         "⭐ ${game.score}",
//                         Colors.amber,
//                       ),

//                       hudCard(
//                         "🏆 $highScore",
//                         Colors.greenAccent,
//                       ),

//                       hudCard(
//                         "⏱ ${game.timeLeft}",
//                         Colors.white,
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 40),

//                   /// 🐶 PET
//                   AnimatedBuilder(
//                     animation: petController,
//                     builder: (_, __) {
//                       return Transform.scale(
//                         scale:
//                             1 +
//                                 (petController.value *
//                                     0.05),
//                         child: Container(
//                           width: 180,
//                           height: 180,
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             color: Colors.white
//                                 .withOpacity(0.08),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: moodColor()
//                                     .withOpacity(0.4),
//                                 blurRadius: 40,
//                               ),
//                             ],
//                           ),
//                           child: Center(
//                             child: Text(
//                               petFace(),
//                               style: const TextStyle(
//                                 fontSize: 90,
//                               ),
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   ),

//                   const SizedBox(height: 30),

//                   /// 😊 MOOD
//                   Text(
//                     "Mood: ${game.mood}%",
//                     style: TextStyle(
//                       color: moodColor(),
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),

//                   const SizedBox(height: 12),

//                   ClipRRect(
//                     borderRadius:
//                         BorderRadius.circular(20),
//                     child: LinearProgressIndicator(
//                       value: game.mood / 100,
//                       minHeight: 14,
//                       backgroundColor:
//                           Colors.white24,
//                       valueColor:
//                           AlwaysStoppedAnimation(
//                         moodColor(),
//                       ),
//                     ),
//                   ),

//                   const Spacer(),

//                   /// 🍎 FOOD
//                   const Text(
//                     "Feed Your Pet",
//                     style: TextStyle(
//                       color: Colors.white70,
//                       fontSize: 20,
//                     ),
//                   ),

//                   const SizedBox(height: 20),

//                   GestureDetector(
//                     onTap: () {
//                       game.feedPet();
//                     },
//                     child: Container(
//                       width: 140,
//                       height: 140,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: Colors.white
//                             .withOpacity(0.1),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.white
//                                 .withOpacity(0.15),
//                             blurRadius: 25,
//                           ),
//                         ],
//                       ),
//                       child: Center(
//                         child: Text(
//                           game.currentFood.emoji,
//                           style: const TextStyle(
//                             fontSize: 70,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 50),
//                 ],
//               ),
//             ),
//           ),

//           /// 🛑 GAME OVER
//           if (game.isGameOver)
//             Container(
//               color: Colors.black.withOpacity(0.6),
//               child: Center(
//                 child: Container(
//                   width: 320,
//                   padding: const EdgeInsets.all(24),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF1B4332),
//                     borderRadius:
//                         BorderRadius.circular(28),
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Text(
//                         "🐶 Pet Resting",
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 28,
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
//                                   const FeedPetScreen(),
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











// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart';
// // import 'package:hive_flutter/hive_flutter.dart';

// // import '../../games/feed_pet_game.dart';

// // class FeedPetScreen extends StatefulWidget {
// //   const FeedPetScreen({super.key});

// //   @override
// //   State<FeedPetScreen> createState() => _FeedPetScreenState();
// // }

// // class _FeedPetScreenState extends State<FeedPetScreen>
// //     with TickerProviderStateMixin {
// //   late final FeedPetGame game;
// //   late final AnimationController _petController;
// //   late final AnimationController _feedController;
// //   late final AnimationController _popupController;

// //   int highScore = 0;
// //   bool _showPopup = false;

// //   @override
// //   void initState() {
// //     super.initState();

// //     final box = Hive.box('gameBox');
// //     highScore = box.get('feedPetHighScore', defaultValue: 0);

// //     game = FeedPetGame()..startGame();
// //     game.addListener(_onGameUpdate);

// //     _petController = AnimationController(
// //       vsync: this,
// //       duration: const Duration(milliseconds: 900),
// //     )..repeat(reverse: true);

// //     _feedController = AnimationController(
// //       vsync: this,
// //       duration: const Duration(milliseconds: 200),
// //     );

// //     _popupController = AnimationController(
// //       vsync: this,
// //       duration: const Duration(milliseconds: 600),
// //     );
// //   }

// //   void _onGameUpdate() {
// //     if (!mounted) return;
// //     _saveHighScore();

// //     if (game.lastResult != null && !_showPopup) {
// //       _showPopup = true;
// //       _popupController.forward(from: 0).then((_) {
// //         if (mounted) {
// //           setState(() => _showPopup = false);
// //           game.clearLastResult();
// //         }
// //       });
// //     }

// //     setState(() {});
// //   }

// //   void _saveHighScore() {
// //     if (game.score > highScore) {
// //       highScore = game.score;
// //       Hive.box('gameBox').put('feedPetHighScore', highScore);
// //     }
// //   }

// //   void _onFeedTap() {
// //     if (game.isGameOver) return;

// //     HapticFeedback.lightImpact();
// //     _feedController.forward(from: 0).then((_) => _feedController.reverse());
// //     game.feedPet();
// //   }

// //   void _restartGame() {
// //     HapticFeedback.mediumImpact();
// //     game.resetGame();
// //     setState(() {});
// //   }

// //   @override
// //   void dispose() {
// //     game.removeListener(_onGameUpdate);
// //     game.disposeGame();
// //     _petController.dispose();
// //     _feedController.dispose();
// //     _popupController.dispose();
// //     super.dispose();
// //   }

// //   Color get moodColor {
// //     if (game.mood > 70) return const Color(0xFF52FF8A);
// //     if (game.mood > 40) return const Color(0xFFFFB347);
// //     return const Color(0xFFFF5C7A);
// //   }

// //   String get petFace {
// //     if (game.isGameOver) return "😴";
// //     if (game.mood > 80) return "🥰";
// //     if (game.mood > 60) return "🐶";
// //     if (game.mood > 40) return "🐕";
// //     if (game.mood > 20) return "😟";
// //     return "🥺";
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final size = MediaQuery.of(context).size;

// //     return Scaffold(
// //       body: Stack(
// //         children: [
// //           // 🌌 Animated gradient background
// //           AnimatedContainer(
// //             duration: const Duration(milliseconds: 600),
// //             decoration: BoxDecoration(
// //               gradient: LinearGradient(
// //                 colors: game.mood > 40
// //                     ? const [
// //                         Color(0xFF1B4332),
// //                         Color(0xFF2D6A4F),
// //                         Color(0xFF40916C),
// //                       ]
// //                     : const [
// //                         Color(0xFF4A1B1B),
// //                         Color(0xFF6A2D2D),
// //                         Color(0xFF913F3F),
// //                       ],
// //                 begin: Alignment.topCenter,
// //                 end: Alignment.bottomCenter,
// //               ),
// //             ),
// //           ),

// //           SafeArea(
// //             child: SingleChildScrollView(
// //               physics: const NeverScrollableScrollPhysics(),
// //               child: ConstrainedBox(
// //                 constraints: BoxConstraints(
// //                   minHeight: size.height - MediaQuery.of(context).padding.vertical,
// //                 ),
// //                 child: Padding(
// //                   padding: const EdgeInsets.all(20),
// //                   child: Column(
// //                     children: [
// //                       _buildTopBar(),
// //                       const SizedBox(height: 30),
// //                       _buildPet(),
// //                       const SizedBox(height: 20),
// //                       _buildMoodSection(),
// //                       const SizedBox(height: 16),
// //                       if (game.combo > 1) _buildComboBadge(),
// //                       const Spacer(),
// //                       const Text(
// //                         "Tap the food to feed!",
// //                         style: TextStyle(
// //                           color: Colors.white70,
// //                           fontSize: 18,
// //                           fontWeight: FontWeight.w500,
// //                         ),
// //                       ),
// //                       const SizedBox(height: 16),
// //                       _buildFoodButton(),
// //                       const SizedBox(height: 30),
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ),

// //           if (_showPopup) _buildScorePopup(),
// //           if (game.isGameOver) _buildGameOverDialog(),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildTopBar() {
// //     return Row(
// //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //       children: [
// //         _hudCard("⭐ ${game.score}", Colors.amber),
// //         _hudCard("🏆 $highScore", Colors.greenAccent),
// //         _hudCard(
// //           "⏱ ${game.timeLeft}",
// //           game.timeLeft <= 5 ? Colors.redAccent : Colors.white,
// //         ),
// //       ],
// //     );
// //   }

// //   Widget _hudCard(String text, Color color) {
// //     return Container(
// //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
// //       decoration: BoxDecoration(
// //         color: Colors.white.withValues(alpha: 0.08),
// //         borderRadius: BorderRadius.circular(18),
// //         border: Border.all(color: color.withValues(alpha: 0.3)),
// //       ),
// //       child: Text(
// //         text,
// //         style: TextStyle(
// //           color: color,
// //           fontWeight: FontWeight.bold,
// //           fontSize: 16,
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildPet() {
// //     return AnimatedBuilder(
// //       animation: _petController,
// //       builder: (_, __) {
// //         return Transform.scale(
// //           scale: 1 + (_petController.value * 0.05),
// //           child: Container(
// //             width: 180,
// //             height: 180,
// //             decoration: BoxDecoration(
// //               shape: BoxShape.circle,
// //               color: Colors.white.withValues(alpha: 0.08),
// //               boxShadow: [
// //                 BoxShadow(
// //                   color: moodColor.withValues(alpha: 0.5),
// //                   blurRadius: 50,
// //                   spreadRadius: 5,
// //                 ),
// //               ],
// //             ),
// //             child: Center(
// //               child: Text(petFace, style: const TextStyle(fontSize: 90)),
// //             ),
// //           ),
// //         );
// //       },
// //     );
// //   }

// //   Widget _buildMoodSection() {
// //     return Column(
// //       children: [
// //         Text(
// //           "Mood: ${game.mood}%",
// //           style: TextStyle(
// //             color: moodColor,
// //             fontSize: 20,
// //             fontWeight: FontWeight.bold,
// //           ),
// //         ),
// //         const SizedBox(height: 10),
// //         ClipRRect(
// //           borderRadius: BorderRadius.circular(20),
// //           child: TweenAnimationBuilder<double>(
// //             tween: Tween(begin: 0, end: game.mood / 100),
// //             duration: const Duration(milliseconds: 300),
// //             builder: (_, value, __) => LinearProgressIndicator(
// //               value: value,
// //               minHeight: 14,
// //               backgroundColor: Colors.white24,
// //               valueColor: AlwaysStoppedAnimation(moodColor),
// //             ),
// //           ),
// //         ),
// //       ],
// //     );
// //   }

// //   Widget _buildComboBadge() {
// //     return AnimatedScale(
// //       scale: 1.0,
// //       duration: const Duration(milliseconds: 200),
// //       child: Container(
// //         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
// //         decoration: BoxDecoration(
// //           gradient: const LinearGradient(
// //             colors: [Colors.orangeAccent, Colors.deepOrange],
// //           ),
// //           borderRadius: BorderRadius.circular(20),
// //         ),
// //         child: Text(
// //           "🔥 ${game.combo}x COMBO",
// //           style: const TextStyle(
// //             color: Colors.white,
// //             fontWeight: FontWeight.bold,
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildFoodButton() {
// //     return GestureDetector(
// //       onTap: _onFeedTap,
// //       child: AnimatedBuilder(
// //         animation: _feedController,
// //         builder: (_, child) {
// //           return Transform.scale(
// //             scale: 1 - (_feedController.value * 0.15),
// //             child: child,
// //           );
// //         },
// //         child: Container(
// //           width: 140,
// //           height: 140,
// //           decoration: BoxDecoration(
// //             shape: BoxShape.circle,
// //             gradient: RadialGradient(
// //               colors: [
// //                 Colors.white.withValues(alpha: 0.2),
// //                 Colors.white.withValues(alpha: 0.05),
// //               ],
// //             ),
// //             boxShadow: [
// //               BoxShadow(
// //                 color: Colors.white.withValues(alpha: 0.2),
// //                 blurRadius: 30,
// //               ),
// //             ],
// //           ),
// //           child: Center(
// //             child: Text(
// //               game.currentFood.emoji,
// //               style: const TextStyle(fontSize: 70),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildScorePopup() {
// //     final isGood = game.lastResult == FeedResult.good;
// //     return AnimatedBuilder(
// //       animation: _popupController,
// //       builder: (_, __) {
// //         return Positioned(
// //           top: 200 - (_popupController.value * 80),
// //           left: 0,
// //           right: 0,
// //           child: Opacity(
// //             opacity: 1 - _popupController.value,
// //             child: Center(
// //               child: Text(
// //                 "${game.lastPoints > 0 ? '+' : ''}${game.lastPoints}",
// //                 style: TextStyle(
// //                   color: isGood ? Colors.greenAccent : Colors.redAccent,
// //                   fontSize: 48,
// //                   fontWeight: FontWeight.bold,
// //                   shadows: const [
// //                     Shadow(blurRadius: 10, color: Colors.black54),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ),
// //         );
// //       },
// //     );
// //   }

// //   Widget _buildGameOverDialog() {
// //     final isNewRecord = game.score >= highScore && game.score > 0;
// //     return Container(
// //       color: Colors.black.withValues(alpha: 0.7),
// //       child: Center(
// //         child: TweenAnimationBuilder<double>(
// //           tween: Tween(begin: 0, end: 1),
// //           duration: const Duration(milliseconds: 400),
// //           curve: Curves.elasticOut,
// //           builder: (_, value, child) =>
// //               Transform.scale(scale: value, child: child),
// //           child: Container(
// //             width: 320,
// //             padding: const EdgeInsets.all(24),
// //             decoration: BoxDecoration(
// //               gradient: const LinearGradient(
// //                 colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
// //                 begin: Alignment.topLeft,
// //                 end: Alignment.bottomRight,
// //               ),
// //               borderRadius: BorderRadius.circular(28),
// //               border: Border.all(
// //                 color: Colors.greenAccent.withValues(alpha: 0.3),
// //               ),
// //             ),
// //             child: Column(
// //               mainAxisSize: MainAxisSize.min,
// //               children: [
// //                 Text(
// //                   isNewRecord ? "🏆 NEW RECORD!" : "🐶 Pet Resting",
// //                   style: const TextStyle(
// //                     color: Colors.white,
// //                     fontSize: 26,
// //                     fontWeight: FontWeight.bold,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 20),
// //                 _statRow("Score", "${game.score}", Colors.amber),
// //                 _statRow("Best", "$highScore", Colors.greenAccent),
// //                 _statRow("Best Combo", "${game.bestCombo}x", Colors.orangeAccent),
// //                 const SizedBox(height: 24),
// //                 SizedBox(
// //                   width: double.infinity,
// //                   child: ElevatedButton(
// //                     style: ElevatedButton.styleFrom(
// //                       backgroundColor: Colors.greenAccent,
// //                       foregroundColor: Colors.black,
// //                       padding: const EdgeInsets.symmetric(vertical: 14),
// //                       shape: RoundedRectangleBorder(
// //                         borderRadius: BorderRadius.circular(16),
// //                       ),
// //                     ),
// //                     onPressed: _restartGame,
// //                     child: const Text(
// //                       "Play Again",
// //                       style: TextStyle(
// //                         fontSize: 18,
// //                         fontWeight: FontWeight.bold,
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //                 TextButton(
// //                   onPressed: () => Navigator.pop(context),
// //                   child: const Text(
// //                     "Exit",
// //                     style: TextStyle(color: Colors.white70),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _statRow(String label, String value, Color color) {
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(vertical: 4),
// //       child: Row(
// //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //         children: [
// //           Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
// //           Text(
// //             value,
// //             style: TextStyle(
// //               color: color,
// //               fontSize: 18,
// //               fontWeight: FontWeight.bold,
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }






import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../games/feed_pet_game.dart';

class FeedPetScreen extends StatefulWidget {
  const FeedPetScreen({super.key});

  @override
  State<FeedPetScreen> createState() => _FeedPetScreenState();
}

class _FeedPetScreenState extends State<FeedPetScreen>
    with TickerProviderStateMixin {
  late final FeedPetGame game;
  late final AnimationController _petController;
  late final AnimationController _feedController;
  late final AnimationController _popupController;

  int highScore = 0;

  @override
  void initState() {
    super.initState();

    final box = Hive.box('gameBox');
    highScore = box.get('feedPetHighScore', defaultValue: 0);

    game = FeedPetGame();
    game.addListener(_onGameUpdate);
    game.startGame();

    _petController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _feedController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _popupController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  void _onGameUpdate() {
    if (!mounted) return;
    _saveHighScore();

    if (game.lastResult != null) {
      _popupController.forward(from: 0).then((_) {
        if (mounted) game.clearLastResult();
      });
    }

    setState(() {});
  }

  void _saveHighScore() {
    if (game.score > highScore) {
      highScore = game.score;
      Hive.box('gameBox').put('feedPetHighScore', highScore);
    }
  }

  void _onFeedTap() {
    if (game.isGameOver) return;
    HapticFeedback.lightImpact();
    _feedController.forward(from: 0).then((_) => _feedController.reverse());
    game.feedPet();
  }

  void _restartGame() {
    HapticFeedback.mediumImpact();
    game.resetGame();
    setState(() {});
  }

  @override
  void dispose() {
    game.removeListener(_onGameUpdate);
    game.disposeGame();
    _petController.dispose();
    _feedController.dispose();
    _popupController.dispose();
    super.dispose();
  }

  Color get moodColor {
    if (game.mood > 70) return const Color(0xFF52FF8A);
    if (game.mood > 40) return const Color(0xFFFFB347);
    return const Color(0xFFFF5C7A);
  }

  String get petFace {
    if (game.isGameOver) return "😴";
    if (game.mood > 80) return "🥰";
    if (game.mood > 60) return "🐶";
    if (game.mood > 40) return "🐕";
    if (game.mood > 20) return "😟";
    return "🥺";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🌌 Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: game.mood > 40
                    ? const [
                        Color(0xFF1B4332),
                        Color(0xFF2D6A4F),
                        Color(0xFF40916C),
                      ]
                    : const [
                        Color(0xFF4A1B1B),
                        Color(0xFF6A2D2D),
                        Color(0xFF913F3F),
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 🎮 Main UI
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Top HUD
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _hudCard("⭐ ${game.score}", Colors.amber),
                      _hudCard("🏆 $highScore", Colors.greenAccent),
                      _hudCard(
                        "⏱ ${game.timeLeft}",
                        game.timeLeft <= 5 ? Colors.redAccent : Colors.white,
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Pet
                  AnimatedBuilder(
                    animation: _petController,
                    builder: (_, __) {
                      return Transform.scale(
                        scale: 1 + (_petController.value * 0.05),
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                            boxShadow: [
                              BoxShadow(
                                color: moodColor.withOpacity(0.5),
                                blurRadius: 40,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              petFace,
                              style: const TextStyle(fontSize: 80),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Mood
                  Text(
                    "Mood: ${game.mood}%",
                    style: TextStyle(
                      color: moodColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: game.mood / 100,
                      minHeight: 14,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation(moodColor),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Combo badge
                  if (game.combo > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.orangeAccent, Colors.deepOrange],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "🔥 ${game.combo}x COMBO",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  const Spacer(),

                  const Text(
                    "Tap the food to feed!",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Food button
                  GestureDetector(
                    onTap: _onFeedTap,
                    child: AnimatedBuilder(
                      animation: _feedController,
                      builder: (_, child) {
                        return Transform.scale(
                          scale: 1 - (_feedController.value * 0.15),
                          child: child,
                        );
                      },
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.2),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.2),
                              blurRadius: 25,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            game.currentFood.emoji,
                            style: const TextStyle(fontSize: 65),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          // Floating score popup
          if (game.lastResult != null)
            AnimatedBuilder(
              animation: _popupController,
              builder: (_, __) {
                return Positioned(
                  top: 220 - (_popupController.value * 80),
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: (1 - _popupController.value).clamp(0.0, 1.0),
                      child: Center(
                        child: Text(
                          "${game.lastPoints > 0 ? '+' : ''}${game.lastPoints}",
                          style: TextStyle(
                            color: game.lastResult == FeedResult.good
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                            shadows: const [
                              Shadow(blurRadius: 10, color: Colors.black54),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

          // Game Over dialog
          if (game.isGameOver)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  builder: (_, value, child) =>
                      Transform.scale(scale: value, child: child),
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.greenAccent.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          game.score >= highScore && game.score > 0
                              ? "🏆 NEW RECORD!"
                              : "🐶 Pet Resting",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _statRow("Score", "${game.score}", Colors.amber),
                        _statRow("Best", "$highScore", Colors.greenAccent),
                        _statRow(
                          "Best Combo",
                          "${game.bestCombo}x",
                          Colors.orangeAccent,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _restartGame,
                            child: const Text(
                              "Play Again",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Exit",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _hudCard(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _statRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}