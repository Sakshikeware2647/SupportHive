// import 'package:flutter/material.dart';
// import '../../games/focus_flow_game.dart';
// import 'package:hive_flutter/hive_flutter.dart';

// class FocusFlowScreen extends StatefulWidget {
//   const FocusFlowScreen({super.key});

//   @override
//   State<FocusFlowScreen> createState() => _FocusFlowScreenState();
// }

// class _FocusFlowScreenState extends State<FocusFlowScreen>
//     with SingleTickerProviderStateMixin {
//   late FocusFlowGame game;
//   late AnimationController controller;

//   @override
//   void initState() {
//     super.initState();

//     /// ✅ INIT GAME FIRST
//     game = FocusFlowGame()..startGame();

//     /// ✅ LOAD HIGH SCORE
//     final box = Hive.box('gameBox');
//     game.setHighScore(box.get('focusHighScore', defaultValue: 0));

//     /// 🔄 UI LISTENER
//     game.addListener(() {
//       setState(() {});
//     });

//     /// 🎯 ANIMATION
//     controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 800),
//     )..repeat();
//   }

//   @override
//   void dispose() {
//     game.disposeGame();
//     controller.dispose();
//     super.dispose();
//   }

//   /// ✅ SAVE HIGH SCORE
//   void saveHighScore() {
//     final box = Hive.box('gameBox');

//     if (game.score > game.highScore) {
//       game.highScore = game.score;
//       box.put('focusHighScore', game.highScore);
//     }
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
//                   Color(0xFF0D1F17),
//                   Color(0xFF1A3828),
//                   Color(0xFF2E6046),
//                 ],
//               ),
//             ),
//           ),

//           /// 🎯 DOT
//           AnimatedPositioned(
//             duration: const Duration(milliseconds: 700),
//             left: game.position.dx,
//             top: game.position.dy,
//             child: GestureDetector(
//               onPanStart: (_) => game.setTouch(true),
//               onPanEnd: (_) => game.setTouch(false),
//               child: AnimatedBuilder(
//                 animation: controller,
//                 builder: (_, __) {
//                   return Container(
//                     width: 70,
//                     height: 70,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: Colors.greenAccent,
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.greenAccent.withOpacity(0.6),
//                           blurRadius: 30,
//                           spreadRadius: 10,
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),

//           /// 🔝 UI (UPDATED WITH HIGH SCORE)
//           SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     "Score: ${game.score}",
//                     style: const TextStyle(color: Colors.white),
//                   ),
//                   Text(
//                     "Best: ${game.highScore}",
//                     style: const TextStyle(color: Colors.greenAccent),
//                   ),
//                   Text(
//                     "⏱ ${game.timeLeft}",
//                     style: const TextStyle(color: Colors.white),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           /// 🛑 GAME OVER
//           /// 🛑 GAME OVER
//           if (game.isGameOver)
//             Builder(
//               builder: (_) {
//                 saveHighScore();

//                 return Container(
//                   color: Colors.black.withOpacity(0.65),
//                   child: Center(
//                     child: Container(
//                       width: 310,
//                       padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
//                       decoration: BoxDecoration(
//                         gradient: const LinearGradient(
//                           colors: [Color(0xFF0F2419), Color(0xFF1C4030)],
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                         ),
//                         borderRadius: BorderRadius.circular(28),
//                         border: Border.all(
//                           color: const Color(0xFF4BFF91).withOpacity(0.3),
//                           width: 1.5,
//                         ),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.65),
//                             blurRadius: 50,
//                             spreadRadius: 12,
//                           ),
//                           BoxShadow(
//                             color: const Color(0xFF4BFF91).withOpacity(0.08),
//                             blurRadius: 35,
//                             spreadRadius: 4,
//                           ),
//                         ],
//                       ),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           const Text('🎯', style: TextStyle(fontSize: 52)),
//                           const SizedBox(height: 10),
//                           const Text(
//                             'GAME OVER',
//                             style: TextStyle(
//                               decoration: TextDecoration.none,
//                               color: Colors.white,
//                               fontSize: 17,
//                               fontWeight: FontWeight.w900,
//                               letterSpacing: 3,
//                             ),
//                           ),
//                           const SizedBox(height: 20),

//                           // ── Divider ──
//                           Container(
//                             height: 1,
//                             decoration: BoxDecoration(
//                               gradient: LinearGradient(
//                                 colors: [
//                                   Colors.transparent,
//                                   Colors.white.withOpacity(0.15),
//                                   Colors.transparent,
//                                 ],
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 16),

//                           // ── Score row ──
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 'SCORE',
//                                 style: TextStyle(
//                                   decoration: TextDecoration.none,
//                                   color: const Color(
//                                     0xFF4BFF91,
//                                   ).withOpacity(0.55),
//                                   fontSize: 11,
//                                   fontWeight: FontWeight.w700,
//                                   letterSpacing: 2.5,
//                                 ),
//                               ),
//                               Text(
//                                 '${game.score}',
//                                 style: const TextStyle(
//                                   decoration: TextDecoration.none,
//                                   color: Color(0xFF4BFF91),
//                                   fontSize: 24,
//                                   fontWeight: FontWeight.w900,
//                                   fontFamily: 'monospace',
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 10),

//                           // ── Best row ──
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 'BEST SCORE',
//                                 style: TextStyle(
//                                   decoration: TextDecoration.none,
//                                   color: const Color(
//                                     0xFF7DF9C8,
//                                   ).withOpacity(0.55),
//                                   fontSize: 11,
//                                   fontWeight: FontWeight.w700,
//                                   letterSpacing: 2.5,
//                                 ),
//                               ),
//                               Text(
//                                 '${game.highScore}',
//                                 style: const TextStyle(
//                                   decoration: TextDecoration.none,
//                                   color: Color(0xFF7DF9C8),
//                                   fontSize: 24,
//                                   fontWeight: FontWeight.w900,
//                                   fontFamily: 'monospace',
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 16),

//                           // ── Divider ──
//                           Container(
//                             height: 1,
//                             decoration: BoxDecoration(
//                               gradient: LinearGradient(
//                                 colors: [
//                                   Colors.transparent,
//                                   Colors.white.withOpacity(0.15),
//                                   Colors.transparent,
//                                 ],
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 22),

//                           // ── Buttons ──
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: GestureDetector(
//                                   onTap: () => Navigator.pushReplacement(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (_) => const FocusFlowScreen(),
//                                     ),
//                                   ),
//                                   child: Container(
//                                     padding: const EdgeInsets.symmetric(
//                                       vertical: 14,
//                                     ),
//                                     decoration: BoxDecoration(
//                                       gradient: const LinearGradient(
//                                         colors: [
//                                           Color(0xFF4BFF91),
//                                           Color(0xFF00C96A),
//                                         ],
//                                         begin: Alignment.topLeft,
//                                         end: Alignment.bottomRight,
//                                       ),
//                                       borderRadius: BorderRadius.circular(14),
//                                       boxShadow: [
//                                         BoxShadow(
//                                           color: const Color(
//                                             0xFF00C96A,
//                                           ).withOpacity(0.4),
//                                           blurRadius: 18,
//                                           offset: const Offset(0, 4),
//                                         ),
//                                       ],
//                                     ),
//                                     child: const Text(
//                                       '🔁  Again',
//                                       textAlign: TextAlign.center,
//                                       style: TextStyle(
//                                         decoration: TextDecoration.none,
//                                         color: Color(0xFF0A1F12),
//                                         fontWeight: FontWeight.w800,
//                                         fontSize: 13,
//                                         letterSpacing: 0.5,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 10),
//                               Expanded(
//                                 child: GestureDetector(
//                                   onTap: () => Navigator.pop(context),
//                                   child: Container(
//                                     padding: const EdgeInsets.symmetric(
//                                       vertical: 14,
//                                     ),
//                                     decoration: BoxDecoration(
//                                       color: Colors.white.withOpacity(0.07),
//                                       borderRadius: BorderRadius.circular(14),
//                                       border: Border.all(
//                                         color: Colors.white.withOpacity(0.2),
//                                         width: 1.2,
//                                       ),
//                                     ),
//                                     child: const Text(
//                                       '🚪  Exit',
//                                       textAlign: TextAlign.center,
//                                       style: TextStyle(
//                                         decoration: TextDecoration.none,
//                                         color: Colors.white60,
//                                         fontWeight: FontWeight.w800,
//                                         fontSize: 13,
//                                         letterSpacing: 0.5,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import '../../games/focus_flow_game.dart';
import 'package:hive_flutter/hive_flutter.dart';

class FocusFlowScreen extends StatefulWidget {
  const FocusFlowScreen({super.key});

  @override
  State<FocusFlowScreen> createState() => _FocusFlowScreenState();
}

class _FocusFlowScreenState extends State<FocusFlowScreen>
    with TickerProviderStateMixin {
  late FocusFlowGame game;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late Animation<double> _pulseOpacity;
  late AnimationController _countdownController;

  bool _showStartCard = true;
  int _countdown = 3;

  @override
  void initState() {
    super.initState();

    game = FocusFlowGame();

    final box = Hive.box('gameBox');
    game.setHighScore(box.get('focusHighScore', defaultValue: 0));

    game.addListener(() => setState(() {}));

    // ── Pulse glow on dot ──
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.55,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
    _pulseOpacity = Tween<double>(
      begin: 0.5,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));

    // ── Countdown animation ──
    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    game.disposeGame();
    _pulseController.dispose();
    _countdownController.dispose();
    super.dispose();
  }

  void saveHighScore() {
    final box = Hive.box('gameBox');
    if (game.score > game.highScore) {
      game.highScore = game.score;
      box.put('focusHighScore', game.highScore);
    }
  }

  // ── Countdown then start ──
  Future<void> _beginCountdown() async {
    setState(() {
      _showStartCard = false;
      _countdown = 3;
    });

    for (int i = 3; i >= 1; i--) {
      setState(() => _countdown = i);
      _countdownController.forward(from: 0);
      await Future.delayed(const Duration(seconds: 1));
    }

    setState(() => _countdown = 0);
    await Future.delayed(const Duration(milliseconds: 200));
    game.startGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Background ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0D1F17),
                  Color(0xFF1A3828),
                  Color(0xFF2E6046),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // ── Dot ──
          // ── Dot ──
          if (!_showStartCard && _countdown == 0)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 700),
              left: game.position.dx,
              top: game.position.dy,
              child: GestureDetector(
                onPanStart: (_) => game.setTouch(true), // ✅
                onPanUpdate: (_) => game.setTouch(true), // ✅
                onPanEnd: (_) => game.setTouch(false), // ✅
                onPanCancel: () => game.setTouch(false), // ✅
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) => SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulse ring
                        Opacity(
                          opacity: _pulseOpacity.value,
                          child: Container(
                            width: 70 * _pulseAnim.value,
                            height: 70 * _pulseAnim.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF4BFF91),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        // Main dot
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [
                                Color(0xFF9DFFCC),
                                Color(0xFF4BFF91),
                                Color(0xFF00C96A),
                              ],
                              stops: [0.0, 0.5, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF4BFF91,
                                ).withOpacity(0.55),
                                blurRadius: 28,
                                spreadRadius: 6,
                              ),
                              BoxShadow(
                                color: const Color(0xFF00C96A).withOpacity(0.3),
                                blurRadius: 50,
                                spreadRadius: 12,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('🎯', style: TextStyle(fontSize: 28)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── Frosted score chips ──
          if (!_showStartCard && _countdown == 0)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ScoreChip(
                      icon: Icons.sports_esports_rounded,
                      label: 'SCORE',
                      value: '${game.score}',
                      color: const Color(0xFF4BFF91),
                    ),
                    _ScoreChip(
                      icon: Icons.emoji_events_rounded,
                      label: 'BEST',
                      value: '${game.highScore}',
                      color: const Color(0xFF7DF9C8),
                    ),
                    _ScoreChip(
                      icon: Icons.timer_outlined,
                      label: 'TIME',
                      value: '${game.timeLeft}',
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
            ),

          // ── Countdown overlay ──
          if (!_showStartCard && _countdown > 0)
            Center(
              child: AnimatedBuilder(
                animation: _countdownController,
                builder: (_, __) {
                  final scale = Tween<double>(begin: 1.4, end: 0.85)
                      .animate(
                        CurvedAnimation(
                          parent: _countdownController,
                          curve: Curves.easeOut,
                        ),
                      )
                      .value;
                  final opacity = Tween<double>(begin: 1.0, end: 0.0)
                      .animate(
                        CurvedAnimation(
                          parent: _countdownController,
                          curve: Curves.easeIn,
                        ),
                      )
                      .value;
                  return Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: Text(
                        '$_countdown',
                        style: const TextStyle(
                          decoration: TextDecoration.none,
                          color: Color(0xFF4BFF91),
                          fontSize: 100,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // ── Start card ──
          if (_showStartCard)
            Container(
              color: Colors.black.withOpacity(0.45),
              child: Center(
                child: Container(
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
                      color: const Color(0xFF4BFF91).withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.65),
                        blurRadius: 50,
                        spreadRadius: 12,
                      ),
                      BoxShadow(
                        color: const Color(0xFF4BFF91).withOpacity(0.08),
                        blurRadius: 35,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎯', style: TextStyle(fontSize: 52)),
                      const SizedBox(height: 10),
                      const Text(
                        'FOCUS FLOW',
                        style: TextStyle(
                          decoration: TextDecoration.none,
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Hold the dot as long as you can',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          decoration: TextDecoration.none,
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 12,
                          letterSpacing: 0.5,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Divider
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.15),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Best score
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'BEST',
                            style: TextStyle(
                              decoration: TextDecoration.none,
                              color: const Color(0xFF7DF9C8).withOpacity(0.55),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.5,
                            ),
                          ),
                          Text(
                            '${game.highScore}',
                            style: const TextStyle(
                              decoration: TextDecoration.none,
                              color: Color(0xFF7DF9C8),
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Divider
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.15),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Begin button
                      GestureDetector(
                        onTap: _beginCountdown,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4BFF91), Color(0xFF00C96A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00C96A).withOpacity(0.4),
                                blurRadius: 18,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Begin',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              decoration: TextDecoration.none,
                              color: Color(0xFF0A1F12),
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Exit button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.2,
                            ),
                          ),
                          child: const Text(
                            '🚪  Exit',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              decoration: TextDecoration.none,
                              color: Colors.white60,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Game over card ──
          if (game.isGameOver)
            Builder(
              builder: (_) {
                saveHighScore();
                return Container(
                  color: Colors.black.withOpacity(0.65),
                  child: Center(
                    child: Container(
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
                          color: const Color(0xFF4BFF91).withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.65),
                            blurRadius: 50,
                            spreadRadius: 12,
                          ),
                          BoxShadow(
                            color: const Color(0xFF4BFF91).withOpacity(0.08),
                            blurRadius: 35,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🎯', style: TextStyle(fontSize: 52)),
                          const SizedBox(height: 10),
                          const Text(
                            'GAME OVER',
                            style: TextStyle(
                              decoration: TextDecoration.none,
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _divider(),
                          const SizedBox(height: 16),
                          _statRow(
                            'SCORE',
                            '${game.score}',
                            const Color(0xFF4BFF91),
                          ),
                          const SizedBox(height: 10),
                          _statRow(
                            'BEST',
                            '${game.highScore}',
                            const Color(0xFF7DF9C8),
                          ),
                          const SizedBox(height: 16),
                          _divider(),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const FocusFlowScreen(),
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF4BFF91),
                                          Color(0xFF00C96A),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF00C96A,
                                          ).withOpacity(0.4),
                                          blurRadius: 18,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      '🔁  Again',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        decoration: TextDecoration.none,
                                        color: Color(0xFF0A1F12),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.07),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: const Text(
                                      '🚪  Exit',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        decoration: TextDecoration.none,
                                        color: Colors.white60,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    height: 1,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.15),
          Colors.transparent,
        ],
      ),
    ),
  );

  Widget _statRow(String label, String value, Color color) => Row(
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
          fontSize: 24,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Frosted Score Chip
// ─────────────────────────────────────────────────────────────────────────────
class _ScoreChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ScoreChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color.withOpacity(0.6), size: 13),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  decoration: TextDecoration.none,
                  color: color.withOpacity(0.45),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  decoration: TextDecoration.none,
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
