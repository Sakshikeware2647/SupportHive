import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  Constants
// ─────────────────────────────────────────────
const double _kTileWidth = 90.0;
const double _kTileHeight = 140.0;
const double _kBaseSpeed = 320.0;
const double _kMaxSpeedBonus = 220.0;
const double _kSpawnInterval = 0.55; // seconds
const double _kBorderRadius = 22.0;
const double _kGlowBlur = 18.0;
const Color _kTileColor = Color(0xFF00F5D4);

/// Lane X-positions (left edge of each tile).
const List<double> _kLanes = [30.0, 140.0, 250.0];

// ─────────────────────────────────────────────
//  Game
// ─────────────────────────────────────────────
class MusicTilesGame extends FlameGame with TapCallbacks {
  /// Called with `true` on a successful tap, `false` when a tile escapes.
  Function(bool hit)? onTileTap;

  /// Shared RNG — no need for each tile to construct its own.
  final Random random = Random();

  /// Tracks elapsed game time so we can ramp up difficulty.
  double _elapsed = 0;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    // ✅ Flame-native repeating timer — fully respects pause / resume.
    add(
      TimerComponent(
        period: _kSpawnInterval,
        repeat: true,
        onTick: _spawnTile,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
  }

  void _spawnTile() {
    // Progressive difficulty: speed grows with elapsed time, capped.
    final speed =
        _kBaseSpeed + (_elapsed * 8).clamp(0, _kMaxSpeedBonus);
    add(MusicTile(speed: speed));
  }

  /// Call this to fully reset the game for a replay without
  /// destroying and recreating the widget tree.
  void resetGame() {
    removeWhere((c) => c is MusicTile);
    _elapsed = 0;
    resumeEngine();
  }
}

// ─────────────────────────────────────────────
//  Tile
// ─────────────────────────────────────────────
class MusicTile extends RectangleComponent
    with TapCallbacks, HasGameRef<MusicTilesGame> {
  final double speed;

  MusicTile({required this.speed})
      : super(
          size: Vector2(_kTileWidth, _kTileHeight),
          paint: Paint()..color = _kTileColor,
        );

  @override
  Future<void> onLoad() async {
    position = Vector2(
      _kLanes[gameRef.random.nextInt(_kLanes.length)],
      -_kTileHeight, // start fully off-screen above
    );
  }

  @override
  void update(double dt) {
    position.y += speed * dt;

    // ✅ Fire miss only after the tile fully exits the bottom.
    if (position.y > gameRef.size.y + _kTileHeight) {
      gameRef.onTileTap?.call(false);
      removeFromParent();
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    gameRef.onTileTap?.call(true);

    // ✅ Quick scale-pop feedback before removal.
    add(
      ScaleEffect.to(
        Vector2.all(1.18),
        EffectController(
          duration: 0.07,
          reverseDuration: 0.07,
          onMax: removeFromParent,
        ),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(_kBorderRadius),
    );

    // Glow layer
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = _kTileColor.withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          _kGlowBlur,
        ),
    );

    // Solid tile
    canvas.drawRRect(rrect, paint);

    // Subtle inner highlight for depth
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(6, 6, size.x - 12, size.y * 0.35),
        const Radius.circular(_kBorderRadius - 6),
      ),
      Paint()
        ..color = Colors.white.withOpacity(0.12)
        ..style = PaintingStyle.fill,
    );
  }
}