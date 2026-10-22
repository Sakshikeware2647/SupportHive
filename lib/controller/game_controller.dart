import 'package:flutter/material.dart';
import 'package:supporthive1/view/games/balloon_game_screen.dart';
import 'package:supporthive1/view/games/feed_pet_screen.dart';
import 'package:supporthive1/view/games/hue_match_screen.dart';
import 'package:supporthive1/view/games/mood_garden_screen.dart';
import 'package:supporthive1/view/games/music_tiles_screen.dart';
import 'package:supporthive1/view/games/sand_garden_screen.dart';
import 'package:supporthive1/view/games/smash_game_screen.dart';
import '/model/game.dart';
import '/view/games/bubble_game_screen.dart';
import '/view/games/emoji_game_screen.dart';
import '/view/games/guided_breathing_screen.dart';
import '/view/games/focus_flow_screen.dart';

class GameController extends ChangeNotifier {
  String selectedDifficulty = "Easy";

  final List<Game> _games = [
    /// 🟢 EASY (Quick Mood Boost)
    Game(
      title: "Bubble Breathing",
      category: "Breathing",
      description: "Follow gentle bubbles rising as you breathe.",
      duration: "2-5 min",
      difficulty: "Easy",
      likes: 150,
      streakPoints: 450,
      level: 3,
    ),
    Game(
      title: "Balloon Messages",
      category: "Relax",
      description: "Pop balloons and receive uplifting messages.",
      duration: "1-3 min",
      difficulty: "Easy",
      likes: 120,
      streakPoints: 300,
      level: 2,
    ),
    Game(
      title: "Emoji Catch",
      category: "Fun",
      description: "Catch happy emojis and avoid sad ones.",
      duration: "2-4 min",
      difficulty: "Easy",
      likes: 180,
      streakPoints: 400,
      level: 3,
    ),
    Game(
      title: "hue Match",
      category: "Puzzle",
      description: "Mix colors to match the target hue.",
      duration: "1-2 min",
      difficulty: "Easy",
      likes: 90,
      streakPoints: 200,
      level: 1,
    ),
    

    /// 🟡 MODERATE (Engaging)
    Game(
      title: "Smash Thoughts",
      category: "Stress Relief",
      description: "Destroy negative thoughts by tapping them.",
      duration: "3-6 min",
      difficulty: "Moderate",
      likes: 200,
      streakPoints: 600,
      level: 5,
    ),
    Game(
      title: "Feed the Pet",
      category: "Emotional",
      description: "Feed your pet and make it happy.",
      duration: "3-5 min",
      difficulty: "Moderate",
      likes: 220,
      streakPoints: 650,
      level: 4,
    ),
    Game(
      title: "Sand Garden",
      category: "Brain",
      description: "Match pairs in a relaxing environment.",
      duration: "4-6 min",
      difficulty: "Moderate",
      likes: 160,
      streakPoints: 500,
      level: 4,
    ),
    Game(
      title: "Breathing Sync",
      category: "Meditation",
      description: "Tap in sync with breathing rhythm.",
      duration: "3-5 min",
      difficulty: "Moderate",
      likes: 190,
      streakPoints: 550,
      level: 5,
    ),

    /// 🔴 HIGH (Deep Relaxation)
    Game(
      title: "Guided Breathing",
      category: "Meditation",
      description: "Deep breathing with guided animation.",
      duration: "5-10 min",
      difficulty: "High",
      likes: 300,
      streakPoints: 900,
      level: 7,
    ),
    Game(
      title: "Mood Garden",
      category: "Growth",
      description: "Grow your garden as you relax.",
      duration: "3-5 min",
      difficulty: "High",
      likes: 280,
      streakPoints: 850,
      level: 6,
    ),
    Game(
      title: "Focus Flow",
      category: "Focus",
      description: "Follow the moving dot with precision.",
      duration: "6-10 min",
      difficulty: "High",
      likes: 260,
      streakPoints: 800,
      level: 6,
    ),
    Game(
      title: "Music Tiles",
      category: "Rhythm",
      description: "Tap tiles to calming music beats.",
      duration: "5-9 min",
      difficulty: "High",
      likes: 310,
      streakPoints: 950,
      level: 8,
    ),
  ];

  void setDifficulty(String difficulty) {
    selectedDifficulty = difficulty;
    notifyListeners();
  }

  void openGame(BuildContext context, Game game) {
    switch (game.title) {
      case "Bubble Breathing":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BubbleGameScreen()),
        );
        break;

      case "Smash Thoughts":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SmashGameScreen()),
        );
        break;

      case "Emoji Catch":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EmojiGameScreen()),
        );
        break;
      case "Guided Breathing":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GuidedBreathingScreen()),
        );
        break;
      case "Focus Flow":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FocusFlowScreen()),
        );
        break;
      case "Mood Garden":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MoodGardenScreen()),
        );
        break;
      case "Music Tiles":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MusicTilesScreen()),
        );
        break;
      case "Sand Garden":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SandGardenScreen()),
        );
        break;
      case "hue Match":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HueMatchScreen()),
        );
        break;
      case "Feed the Pet":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FeedPetScreen()),
        );
        break;
      case "Balloon Messages":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BalloonGameScreen()),
        );
        break;

      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("${game.title} coming soon")));
    }
  }

  List<Game> getGamesByLevel(String level) {
    return _games.where((game) => game.difficulty == level).toList();
  }

  Game get selectedGame {
    return _games.firstWhere(
      (g) => g.difficulty == selectedDifficulty,
      orElse: () => _games.first,
    );
  }
}
