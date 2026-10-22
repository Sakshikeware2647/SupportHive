import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class EmojiGame extends FlameGame with DragCallbacks {
  Function(String type)? onCatch;

  late Bucket bucket;
  final random = Random();

  /// ✅ FIX 1: Moved outside spawnEmoji — now a proper class-level override
  @override
  Color backgroundColor() => const Color(0xFF1A3828);

  @override
  Future<void> onLoad() async {
    bucket = Bucket();
    add(bucket);
    spawnEmoji();
  }

  void spawnEmoji() {
    add(FallingEmoji());
    Future.delayed(const Duration(milliseconds: 600), () {
      spawnEmoji();
    });
  }
}

/// 🪣 BUCKET (PLAYER)
class Bucket extends PositionComponent
    with DragCallbacks, HasGameRef<EmojiGame> {
  
  static const double _w = 140;
  static const double _h = 36;

  // Rim highlight
  static final Paint _rimPaint = Paint()
    ..color = const Color(0xFFFFD700)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;

  // Main body gradient simulation (two-layer fill)
  static final Paint _bodyPaint = Paint()
    ..color = const Color(0xFF8B5E3C);

  static final Paint _bodyHighlight = Paint()
    ..color = const Color(0xFFB8874A);

  static final Paint _bodyShade = Paint()
    ..color = const Color(0xFF5C3A1E);

  // Sheen overlay
  static final Paint _sheenPaint = Paint()
    ..color = const Color(0x33FFD700);

  // Rim top strip
  static final Paint _rimFill = Paint()
    ..color = const Color(0xFF4A2E0E);

  // Glint on rim
  static final Paint _glintPaint = Paint()
    ..color = const Color(0xCCFFECB3);

  Bucket() : super(size: Vector2(_w, _h));

  @override
  Future<void> onLoad() async {
    position = Vector2(
      gameRef.size.x / 2 - _w / 2,
      gameRef.size.y - 90,
    );
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, _w, _h);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    // ── Shadow beneath ──────────────────────────────────────
    final shadowPaint = Paint()
      ..color = const Color(0x55000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.translate(0, 4),
        const Radius.circular(8),
      ),
      shadowPaint,
    );

    // ── Shade (bottom-left darker wedge) ────────────────────
    canvas.drawRRect(rrect, _bodyShade);

    // ── Main body (top-right lighter) ───────────────────────
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(4, 0, _w - 4, _h - 4),
      const Radius.circular(6),
    );
    canvas.drawRRect(bodyRect, _bodyHighlight);

    // ── Middle fill blend ───────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 2, _w - 4, _h - 4),
        const Radius.circular(6),
      ),
      _bodyPaint,
    );

    // ── Gold sheen diagonal strip ───────────────────────────
    final sheenPath = Path()
      ..moveTo(16, 0)
      ..lineTo(48, 0)
      ..lineTo(32, _h)
      ..lineTo(0, _h)
      ..close();
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawPath(sheenPath, _sheenPaint);
    canvas.restore();

    // ── Rim top bar ─────────────────────────────────────────
    final rimRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, _w, 8),
      const Radius.circular(8),
    );
    canvas.drawRRect(rimRect, _rimFill);

    // ── Gold rim stroke ──────────────────────────────────────
    canvas.drawRRect(rrect, _rimPaint);

    // ── Glint on rim (bright highlight) ─────────────────────
    final glintPaint = _glintPaint;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(12, 1, 40, 4),
        const Radius.circular(2),
      ),
      glintPaint,
    );

    // ── Two vertical rivets ─────────────────────────────────
    final rivetPaint = Paint()..color = const Color(0xFFFFD700);
    final rivetShadow = Paint()..color = const Color(0x66000000);
    for (final rx in [24.0, _w - 24.0]) {
      canvas.drawCircle(Offset(rx, _h / 2 + 4), 4, rivetShadow);
      canvas.drawCircle(Offset(rx, _h / 2 + 4), 3.5, rivetPaint);
      canvas.drawCircle(
        Offset(rx - 1, _h / 2 + 3),
        1.2,
        Paint()..color = const Color(0xFFFFFFCC),
      );
    }

    // ── Engraved center line ─────────────────────────────────
    final engravePaint = Paint()
      ..color = const Color(0x44000000)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(52, _h / 2 + 4),
      Offset(_w - 52, _h / 2 + 4),
      engravePaint,
    );
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position.x += event.localDelta.x;
    position.x = position.x.clamp(0, gameRef.size.x - size.x);
  }
}

/// 😄 FALLING EMOJI
class FallingEmoji extends TextComponent with HasGameRef<EmojiGame> {
  final random = Random();
  late String type;

  FallingEmoji()
      : super(
          textRenderer: TextPaint(
            style: const TextStyle(fontSize: 28),
          ),
        );

  @override
  Future<void> onLoad() async {
    final emojis = [
      {"emoji": "😊", "type": "good"},
      {"emoji": "😄", "type": "good"},
      {"emoji": "😢", "type": "bad"},
      {"emoji": "😡", "type": "bad"},
      {"emoji": "😌", "type": "good"},
    ];

    final selected = emojis[random.nextInt(emojis.length)];

    text = selected["emoji"]!;
    type = selected["type"]!;

    position = Vector2(
      random.nextDouble() * gameRef.size.x,
      0,
    );
  }

  @override
  void update(double dt) {
    position.y += 200 * dt;

    /// 🎯 COLLISION WITH BUCKET
    if (toRect().overlaps(gameRef.bucket.toRect())) {
      gameRef.onCatch?.call(type);
      removeFromParent();
    }

    /// ❌ MISS
    if (position.y > gameRef.size.y) {
      removeFromParent();
    }
  }
}


