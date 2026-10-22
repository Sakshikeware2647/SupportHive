

import 'package:flutter/material.dart';
import '../controller/game_controller.dart';

class MindfulGamesScreen extends StatefulWidget {
  const MindfulGamesScreen({super.key});

  @override
  State<MindfulGamesScreen> createState() => _MindfulGamesScreenState();
}

class _MindfulGamesScreenState extends State<MindfulGamesScreen> {
  late GameController controller;

  @override
  void initState() {
    super.initState();
    controller = GameController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),

      body: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          return Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 20, bottom: 20),
                  children: [
                    _buildDifficultySection(),

                    const SizedBox(height: 20),

                    ///multiple games
                    ...controller
                        .getGamesByLevel(controller.selectedDifficulty)
                        .map(
                          (game) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            child: _buildGameCard(game),
                          ),
                        )
                        ,
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  ///header 
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A6741), Color(0xFF6E8B5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            /// top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  // const Icon(Icons.spa, color: Colors.white),
                  Image.asset(
                    'assets/images/logo_icon.png',
                    width: 40,
                    height: 40,

                  )
                ],
              ),
            ),

            const SizedBox(height: 10),

            ///title
            const Text(
              "Mindful Games",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              "Relax • Play • Heal",
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  ///difficulty button 
  Widget _buildDifficultySection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildDifficultyBtn("Easy"),
        _buildDifficultyBtn("Moderate"),
        _buildDifficultyBtn("High"),
      ],
    );
  }


  Widget _buildDifficultyBtn(String difficulty) {
    final selected = controller.selectedDifficulty == difficulty;

    return GestureDetector(
      onTap: () => controller.setDifficulty(difficulty),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF4A6741) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 10,
                  ),
                ]
              : [],
        ),
        child: Text(
          difficulty,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  ///game card
  Widget _buildGameCard(game) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [Colors.blue.shade100, Colors.purple.shade100],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ///icon for difficulty
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.blue.shade50,
                  child: Icon(Icons.air, size: 30, color: Colors.blue.shade400),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    game.difficulty,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// title
            Text(
              game.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            ///category
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(game.category, style: const TextStyle(fontSize: 12)),
            ),

            const SizedBox(height: 12),

            ///description
            Text(
              game.description,
              style: TextStyle(color: Colors.grey.shade700),
            ),

            const SizedBox(height: 12),

            ///duration
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 6),
                Text(game.duration),
              ],
            ),

            const SizedBox(height: 14),

            //stats
            Row(
              children: [
                _stat("😊", game.likes.toString()),
                _stat("🔥", game.streakPoints.toString()),
                _stat("⬆️", game.level.toString()),
              ],
            ),

            const SizedBox(height: 20),

            //Play button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  controller.openGame(context, game);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A6741),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Play Now",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String e, String v) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(children: [Text(e), const SizedBox(width: 4), Text(v)]),
    );
  }
}
