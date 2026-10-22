import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class MoodGardenGame extends FlameGame with TapCallbacks {
  Function()? onDropTap;
  Function()? onBombTap;
  final Random random = Random();
  bool _spawning = false;
  double _speedMultiplier = 1.0;
  double _elapsedTime = 0;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!_spawning && size.x > 0) {
      _spawning = true;
      spawnDrop();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsedTime += dt;
    _speedMultiplier = (1.0 + (_elapsedTime / 5) * 0.15).clamp(1.0, 3.0);
  }

  @override
  void onTapDown(TapDownEvent event) {
    final tapPos = event.localPosition;

    for (final component in children.toList().reversed) {
      if (component is FancyDrop) {
        final dist = (component.position - tapPos).length;
        if (dist <= component.radius + 16) {
          component.blast();
          return;
        }
      } else if (component is BombDrop) {
        final dist = (component.position - tapPos).length;
        if (dist <= component.radius + 16) {
          component.blast();
          return;
        }
      }
    }
  }

  void spawnDrop() {
    final isBomb = random.nextDouble() < 0.2;
    if (isBomb) {
      add(BombDrop());
    } else {
      add(FancyDrop(type: random.nextInt(4)));
    }

    final delay = (700 - (_speedMultiplier * 60)).clamp(250, 700).toInt();
    Future.delayed(Duration(milliseconds: delay), () {
      if (!paused && _spawning) spawnDrop();
    });
  }

  void triggerScreenShake() {
    add(ScreenShaker());
  }

  @override
  void pauseEngine() {
    _spawning = false;
    super.pauseEngine();
  }
}

// ─── Screen Shaker ───────────────────────────────────────────────────────────

class ScreenShaker extends Component with HasGameRef<MoodGardenGame> {
  double _time = 0;
  final double duration = 0.3;
  final double intensity = 6;

  @override
  void update(double dt) {
    _time += dt;
    final progress = (_time / duration).clamp(0.0, 1.0);
    if (progress >= 1.0) {
      gameRef.camera.viewfinder.position = Vector2.zero();
      removeFromParent();
      return;
    }
    final shake = intensity * (1 - progress);
    final dx = (gameRef.random.nextDouble() * 2 - 1) * shake;
    final dy = (gameRef.random.nextDouble() * 2 - 1) * shake;
    gameRef.camera.viewfinder.position = Vector2(dx, dy);
  }
}

// ─── Ripple Effect ───────────────────────────────────────────────────────────

class RippleEffect extends CircleComponent {
  double _life = 0.35;
  final double _maxLife = 0.35;
  final Color _baseColor;

  RippleEffect({required Vector2 pos, Color color = Colors.white})
      : _baseColor = color,
        super(
          radius: 10,
          position: pos,
          anchor: Anchor.center,
          paint: Paint()..color = color.withOpacity(0.5),
          priority: 10,
        );

  @override
  void update(double dt) {
    _life -= dt;
    if (_life <= 0) {
      removeFromParent();
      return;
    }
    final progress = (_life / _maxLife).clamp(0.0, 1.0);
    radius = 10 + (50 * (1 - progress));
    paint.color = _baseColor.withOpacity((0.5 * progress).clamp(0.0, 1.0));
  }
}

// ─── Fancy Drop ──────────────────────────────────────────────────────────────

class FancyDrop extends CircleComponent with HasGameRef<MoodGardenGame> {
  final Random random = Random();
  final int type;
  late double speed;
  bool _blasted = false;

  static const List<Color> colors = [
    Color(0xFF7DF9FF),
    Color(0xFFFFE066),
    Color(0xFFFF6B35),
    Color(0xFFB388FF),
  ];

  static const List<String> emojis = ['💧', '⭐', '🔥', '🫧'];

  FancyDrop({required this.type})
      : super(
          radius: 24,
          paint: Paint()..color = colors[type],
          priority: 5,
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    speed = (150 + random.nextDouble() * 80) * gameRef._speedMultiplier;
    position = Vector2(
      random.nextDouble() * (gameRef.size.x - 60) + 30,
      -50,
    );
  }

  @override
  void update(double dt) {
    speed *= 1.0005;
    position.y += speed * dt;
    if (position.y > gameRef.size.y + 60) removeFromParent();
  }

  void blast() {
    if (_blasted) return;
    _blasted = true;
    gameRef.onDropTap?.call();
    gameRef.add(RippleEffect(
        pos: absolutePosition.clone(), color: colors[type]));
    gameRef.triggerScreenShake();
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final dropColor = colors[type];

    final glowPaint = Paint()
      ..color = dropColor.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset.zero, radius + 10, glowPaint);
    canvas.drawCircle(Offset.zero, radius, paint);

    final tp = TextPainter(
      text: TextSpan(
        text: emojis[type],
        style: TextStyle(fontSize: radius * 1.1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  }
}

// ─── Bomb Drop ───────────────────────────────────────────────────────────────

class BombDrop extends CircleComponent with HasGameRef<MoodGardenGame> {
  final Random random = Random();
  double speed = 130;
  double _wobble = 0;
  bool _blasted = false;

  BombDrop()
      : super(
          radius: 26,
          paint: Paint()..color = const Color(0xFFFF3B30),
          priority: 5,
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    speed = (120 + random.nextDouble() * 60) * gameRef._speedMultiplier;
    position = Vector2(
      random.nextDouble() * (gameRef.size.x - 60) + 30,
      -50,
    );
  }

  @override
  void update(double dt) {
    _wobble += dt * 5;
    position.y += speed * dt;
    position.x += sin(_wobble) * 1.5;
    if (position.y > gameRef.size.y + 60) removeFromParent();
  }

  void blast() {
    if (_blasted) return;
    _blasted = true;
    gameRef.onBombTap?.call();
    gameRef.add(RippleEffect(
        pos: absolutePosition.clone(),
        color: const Color(0xFFFF3B30)));
    gameRef.triggerScreenShake();
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final glowPaint = Paint()
      ..color = const Color(0xFFFF3B30).withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawCircle(Offset.zero, radius + 12, glowPaint);
    canvas.drawCircle(Offset.zero, radius, paint);

    final tp = TextPainter(
      text: const TextSpan(text: '💣', style: TextStyle(fontSize: 28)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  }
}