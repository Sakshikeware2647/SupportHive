// import 'package:flutter/material.dart';
// import 'package:hive_flutter/hive_flutter.dart';

// import '../../games/hue_match_game.dart';

// class HueMatchScreen extends StatefulWidget {
//   const HueMatchScreen({super.key});

//   @override
//   State<HueMatchScreen> createState() =>
//       _HueMatchScreenState();
// }

// class _HueMatchScreenState
//     extends State<HueMatchScreen> {
//   late HueMatchGame game;

//   int highScore = 0;

//   @override
//   void initState() {
//     super.initState();

//     game = HueMatchGame();

//     final box = Hive.box('gameBox');

//     highScore = box.get(
//       'hueMatchHighScore',
//       defaultValue: 0,
//     );

//     game.addListener(() {
//       saveHighScore();

//       setState(() {});
//     });
//   }

//   void saveHighScore() {
//     final box = Hive.box('gameBox');

//     if (game.score > highScore) {
//       highScore = game.score;

//       box.put(
//         'hueMatchHighScore',
//         highScore,
//       );
//     }
//   }

//   Widget glassCard(
//     String text,
//     Color color,
//   ) {
//     return Container(
//       padding: const EdgeInsets.symmetric(
//         horizontal: 18,
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

//   Widget colorButton(Color color) {
//     return GestureDetector(
//       onTap: () {
//         game.selectColor(color);
//       },
//       child: Container(
//         width: 80,
//         height: 80,
//         decoration: BoxDecoration(
//           color: color,
//           shape: BoxShape.circle,
//           boxShadow: [
//             BoxShadow(
//               color: color.withOpacity(0.4),
//               blurRadius: 20,
//             ),
//           ],
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
//                   Color(0xFF0F172A),
//                   Color(0xFF1E293B),
//                   Color(0xFF334155),
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
//                       glassCard(
//                         "⭐ ${game.score}",
//                         Colors.amber,
//                       ),

//                       glassCard(
//                         "🏆 $highScore",
//                         Colors.greenAccent,
//                       ),

//                       glassCard(
//                         "🎯 Lv ${game.level}",
//                         Colors.cyanAccent,
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 40),

//                   /// 🎯 TARGET
//                   const Text(
//                     "Match This Color",
//                     style: TextStyle(
//                       color: Colors.white70,
//                       fontSize: 18,
//                     ),
//                   ),

//                   const SizedBox(height: 20),

//                   AnimatedContainer(
//                     duration:
//                         const Duration(milliseconds: 400),
//                     width: 140,
//                     height: 140,
//                     decoration: BoxDecoration(
//                       color: game.targetColor,
//                       shape: BoxShape.circle,
//                       boxShadow: [
//                         BoxShadow(
//                           color: game.targetColor
//                               .withOpacity(0.5),
//                           blurRadius: 40,
//                         ),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 50),

//                   /// 🧪 MIX AREA
//                   const Text(
//                     "Your Mix",
//                     style: TextStyle(
//                       color: Colors.white70,
//                       fontSize: 18,
//                     ),
//                   ),

//                   const SizedBox(height: 20),

//                   AnimatedContainer(
//                     duration:
//                         const Duration(milliseconds: 400),
//                     width: 160,
//                     height: 160,
//                     decoration: BoxDecoration(
//                       color: game.mixedColor,
//                       shape: BoxShape.circle,
//                       border: Border.all(
//                         color: Colors.white24,
//                         width: 3,
//                       ),
//                       boxShadow: [
//                         BoxShadow(
//                           color: game.mixedColor
//                               .withOpacity(0.5),
//                           blurRadius: 35,
//                         ),
//                       ],
//                     ),
//                   ),

//                   const Spacer(),

//                   /// 🎨 COLORS
//                   Row(
//                     mainAxisAlignment:
//                         MainAxisAlignment.spaceEvenly,
//                     children: [
//                       colorButton(Colors.red),
//                       colorButton(Colors.blue),
//                       colorButton(Colors.yellow),
//                     ],
//                   ),

//                   const SizedBox(height: 40),

//                   /// 🔄 RESET
//                   ElevatedButton(
//                     onPressed: () {
//                       game.resetMix();
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor:
//                           Colors.white.withOpacity(0.1),
//                       foregroundColor: Colors.white,
//                       padding:
//                           const EdgeInsets.symmetric(
//                         horizontal: 30,
//                         vertical: 14,
//                       ),
//                     ),
//                     child: const Text(
//                       "Reset Mix",
//                     ),
//                   ),

//                   const SizedBox(height: 30),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }




import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../games/hue_match_game.dart';

// ─────────────────────────────────────────────────────────────
//  HueMatchScreen
//
//  OVERFLOW FIX:
//  • Replaced the rigid Column with a SingleChildScrollView
//    wrapping a Column — no more 27px overflow on smaller screens.
//  • Replaced const SizedBox(height: N) spacers with
//    SizedBox(height: screenH * fraction) — proportional spacing
//    that scales on every device automatically.
//  • Removed the Spacer() that was pushing the color buttons
//    below the screen on short devices.
//  • All font sizes capped so nothing clips on small screens.
//
//  LOGIC IMPROVEMENTS:
//  • Shows `game.feedback` in an animated banner
//  • Shows a ✅ ring on the mix circle when isCorrect == true
//  • Color buttons highlight when already selected
//  • Reset button disabled when nothing is selected
//  • Restart Game button resets full state
//  • Streak counter displayed in the top bar
// ─────────────────────────────────────────────────────────────

class HueMatchScreen extends StatefulWidget {
  const HueMatchScreen({super.key});

  @override
  State<HueMatchScreen> createState() => _HueMatchScreenState();
}

class _HueMatchScreenState extends State<HueMatchScreen>
    with SingleTickerProviderStateMixin {
  late HueMatchGame game;
  int highScore = 0;

  // For the correct-answer pulse animation on the mix circle
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    game = HueMatchGame();

    // Load persisted high score
    final box = Hive.box('gameBox');
    highScore = box.get('hueMatchHighScore', defaultValue: 0);

    // Pulse animation (scale 1.0 → 1.12 → 1.0)
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    game.addListener(() {
      _saveHighScore();
      if (game.isCorrect) _pulseCtrl.forward(from: 0);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    game.removeListener(_saveHighScore);
    super.dispose();
  }

  void _saveHighScore() {
    if (game.score > highScore) {
      highScore = game.score;
      Hive.box('gameBox').put('hueMatchHighScore', highScore);
    }
  }

  // ── Reusable widgets ────────────────────────────────────────

  /// Glass-style stat badge in the top bar.
  Widget _glassCard(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  /// Tappable color circle button.
  /// Highlights with a white ring if the color is already selected.
  Widget _colorButton(Color color) {
    final isSelected = game.selectedColors.contains(color);
    // Count how many times this color appears in selectedColors
    final selectionCount =
        game.selectedColors.where((c) => c == color).length;

    return GestureDetector(
      onTap: () => game.selectColor(color),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          // White ring when selected
          border: isSelected
              ? Border.all(color: Colors.white, width: 3)
              : Border.all(color: Colors.transparent, width: 3),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isSelected ? 0.7 : 0.35),
              blurRadius: isSelected ? 28 : 16,
            ),
          ],
        ),
        child: selectionCount > 0
            ? Center(
                child: Text(
                  '×$selectionCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
                  ),
                ),
              )
            : null,
      ),
    );
  }

  /// Large color preview circle (target or mix).
  Widget _colorCircle({
    required Color color,
    required double size,
    bool showCorrectRing = false,
    bool animate = false,
  }) {
    Widget circle = AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: showCorrectRing
            ? Border.all(color: Colors.greenAccent, width: 4)
            : Border.all(color: Colors.white12, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(showCorrectRing ? 0.8 : 0.4),
            blurRadius: showCorrectRing ? 48 : 28,
          ),
        ],
      ),
    );

    if (animate) {
      return ScaleTransition(scale: _pulseAnim, child: circle);
    }
    return circle;
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Use screen height for proportional spacing — fixes overflow on all devices
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      // No AppBar — we draw our own top bar inside the body
      body: Stack(
        children: [
          // ── Background gradient ──────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF1E293B),
                  Color(0xFF334155),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // ── Main content ─────────────────────────────────────
          SafeArea(
            // KEY FIX: SingleChildScrollView prevents the 27px overflow
            // on shorter screens while still looking great on tall ones.
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ConstrainedBox(
                // Ensure the column is at least as tall as the safe area
                // so it doesn't look empty on very tall screens.
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      SizedBox(height: screenH * 0.02),

                      // ── Top stat bar ─────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _glassCard('⭐ ${game.score}', Colors.amber),
                          _glassCard('🏆 $highScore', Colors.greenAccent),
                          _glassCard('🎯 Lv ${game.level}', Colors.cyanAccent),
                        ],
                      ),

                      // Streak badge (only shown when streak > 1)
                      if (game.streak > 1) ...[
                        SizedBox(height: screenH * 0.01),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.orange.withOpacity(0.5)),
                          ),
                          child: Text(
                            '🔥 ${game.streak}x Streak',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],

                      SizedBox(height: screenH * 0.035),

                      // ── Target color ─────────────────────────
                      const Text(
                        'Match This Color',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      SizedBox(height: screenH * 0.018),
                      _colorCircle(
                        color: game.targetColor,
                        size: screenH * 0.15, // proportional to screen
                      ),

                      SizedBox(height: screenH * 0.03),

                      // ── Mix arrow label ───────────────────────
                      const Text(
                        '▼  Tap 2 colors below  ▼',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),

                      SizedBox(height: screenH * 0.025),

                      // ── Mixed color ───────────────────────────
                      const Text(
                        'Your Mix',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      SizedBox(height: screenH * 0.018),
                      _colorCircle(
                        color: game.mixedColor,
                        size: screenH * 0.17,
                        showCorrectRing: game.isCorrect,
                        animate: true,
                      ),

                      // ── Feedback banner ───────────────────────
                      SizedBox(height: screenH * 0.018),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: game.feedback.isEmpty
                            ? const SizedBox(height: 28, key: ValueKey('empty'))
                            : Container(
                                key: ValueKey(game.feedback),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 7),
                                decoration: BoxDecoration(
                                  color: game.isCorrect
                                      ? Colors.greenAccent.withOpacity(0.15)
                                      : Colors.redAccent.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: game.isCorrect
                                        ? Colors.greenAccent.withOpacity(0.4)
                                        : Colors.redAccent.withOpacity(0.35),
                                  ),
                                ),
                                child: Text(
                                  game.feedback,
                                  style: TextStyle(
                                    color: game.isCorrect
                                        ? Colors.greenAccent
                                        : Colors.redAccent[100],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                      ),

                      SizedBox(height: screenH * 0.035),

                      // ── Color picker buttons ──────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: game.availableColors
                            .map((c) => _colorButton(c))
                            .toList(),
                      ),

                      SizedBox(height: screenH * 0.025),

                      // ── Action buttons row ────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Reset Mix
                          ElevatedButton.icon(
                            onPressed: game.selectedColors.isEmpty
                                ? null // disabled when nothing selected
                                : game.resetMix,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Reset'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white12,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.white10,
                              disabledForegroundColor: Colors.white30,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 22, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),

                          const SizedBox(width: 14),

                          // Restart Game
                          ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  backgroundColor: const Color(0xFF1E293B),
                                  title: const Text('Restart Game?',
                                      style: TextStyle(color: Colors.white)),
                                  content: const Text(
                                    'Your score will reset to 0.',
                                    style: TextStyle(color: Colors.white60),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        game.resetGame();
                                      },
                                      child: const Text(
                                        'Restart',
                                        style:
                                            TextStyle(color: Colors.redAccent),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.replay, size: 18),
                            label: const Text('New Game'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.redAccent.withOpacity(0.15),
                              foregroundColor: Colors.redAccent[100],
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 22, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: screenH * 0.03),
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
}