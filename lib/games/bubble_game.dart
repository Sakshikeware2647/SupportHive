import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'dart:math';

class BubbleGame extends FlameGame {
  final Random random = Random();

  /// ✅ ADD THIS
  Function()? onBubblePop;

  @override
  Future<void> onLoad() async {
    add(BubbleSpawner());
  }
}

class BubbleSpawner extends Component with HasGameRef<BubbleGame> {
  @override
  void update(double dt) {
    if (gameRef.children.length < 8) {
      gameRef.add(Bubble());
    }
  }
}

class Bubble extends CircleComponent
    with TapCallbacks, HasGameRef<BubbleGame> {
  final Random random = Random();

  Bubble()
      : super(
          radius: 25,
          paint: Paint()..color = const Color(0xFF6EC6FF),
        ) {
    position = Vector2(
      random.nextDouble() * 300,
      random.nextDouble() * 600,
    );
  }

  @override
  void update(double dt) {
    position.y -= 50 * dt;

    if (position.y < -50) {
      removeFromParent();
    }
  }

  @override
void onTapDown(TapDownEvent event) {
  gameRef.onBubblePop?.call(); // ✅ notify UI
  removeFromParent();
}
}