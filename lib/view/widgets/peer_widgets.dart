// ─────────────────────────────────────────────────────────────────────────────
// view/widgets/peer_widgets.dart
// Shared UI components used across the peer support screens
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
class PeerTheme {
  static const seaBlue   = Color(0xFF3A7BD5);
  static const seaLight  = Color(0xFFEBF2FF);
  static const seaDark   = Color(0xFF185FA5);
  static const sage      = Color(0xFF4A6741);
  static const sageLight = Color(0xFFEEF5EA);
  static const mist      = Color(0xFFF4F6F8);
  static const warning   = Color(0xFFE8A020);

  static const List<Color> avatarBg = [
    Color(0xFFEBF2FF), Color(0xFFEEF5EA),
    Color(0xFFEEEDFE), Color(0xFFFAEEDA),
  ];
  static const List<Color> avatarFg = [
    Color(0xFF185FA5), Color(0xFF3B6D11),
    Color(0xFF534AB7), Color(0xFF854F0B),
  ];
}

// ── Avatar ───────────────────────────────────────────────────────────────────
class PeerAvatar extends StatelessWidget {
  final String username;
  final double radius;
  final bool showOnlineDot;

  const PeerAvatar({
    super.key,
    required this.username,
    this.radius = 22,
    this.showOnlineDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final idx = username.hashCode.abs() % PeerTheme.avatarBg.length;
    final initial = username.startsWith('@') && username.length > 1
        ? username[1].toUpperCase()
        : username[0].toUpperCase();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: PeerTheme.avatarBg[idx],
          child: Text(
            initial,
            style: TextStyle(
              fontSize: radius * 0.65,
              fontWeight: FontWeight.bold,
              color: PeerTheme.avatarFg[idx],
            ),
          ),
        ),
        if (showOnlineDot)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: radius * 0.5,
              height: radius * 0.5,
              decoration: BoxDecoration(
                color: PeerTheme.sage,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Anonymity Banner ─────────────────────────────────────────────────────────
class AnonymityBanner extends StatelessWidget {
  const AnonymityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: PeerTheme.seaLight,
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.lock_outline, size: 13, color: PeerTheme.seaDark),
          SizedBox(width: 6),
          Text(
            '🔒  This chat is anonymous — no personal data is shared',
            style: TextStyle(fontSize: 11, color: PeerTheme.seaDark),
          ),
        ],
      ),
    );
  }
}

// ── Chat Bubble ──────────────────────────────────────────────────────────────
class ChatBubble extends StatelessWidget {
  final String text;
  final String time;
  final String peerUsername;
  final bool isMe;
  final bool isRead;
  final bool isBlocked;

  const ChatBubble({
    super.key,
    required this.text,
    required this.time,
    required this.peerUsername,
    required this.isMe,
    this.isRead = false,
    this.isBlocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isBlocked
            ? Colors.orange.shade50
            : isMe
                ? PeerTheme.seaBlue
                : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 18),
        ),
        border: isBlocked
            ? Border.all(color: Colors.orange.shade200)
            : null,
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: isBlocked
                  ? Colors.orange.shade800
                  : isMe
                      ? Colors.white
                      : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontSize: 10,
                  color: isMe
                      ? Colors.white.withOpacity(0.7)
                      : Colors.black38,
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 3),
                Icon(
                  isRead ? Icons.done_all : Icons.done,
                  size: 13,
                  color: isRead
                      ? Colors.lightBlueAccent
                      : Colors.white.withOpacity(0.75),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: isMe
            ? [bubble]
            : [
                PeerAvatar(username: peerUsername, radius: 14),
                const SizedBox(width: 6),
                bubble,
              ],
      ),
    );
  }
}

// ── Typing Bubble ─────────────────────────────────────────────────────────────
class TypingBubble extends StatefulWidget {
  final String username;
  const TypingBubble({super.key, required this.username});

  @override
  State<TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          PeerAvatar(username: widget.username, radius: 14),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 1))
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children:
                  List.generate(3, (i) => _BounceDot(ctrl: _ctrl, index: i)),
            ),
          ),
        ]),
      );
}

class _BounceDot extends StatelessWidget {
  final AnimationController ctrl;
  final int index;
  const _BounceDot({required this.ctrl, required this.index});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: ctrl,
        builder: (_, __) {
          final t = (ctrl.value - index * 0.15).clamp(0.0, 1.0);
          final b = Curves.easeInOut
              .transform((t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.0, 1.0));
          return Container(
            width: 7,
            height: 7,
            margin: EdgeInsets.only(right: index < 2 ? 4 : 0, bottom: b * 5),
            decoration: BoxDecoration(
                color: Colors.grey.shade400, shape: BoxShape.circle),
          );
        },
      );
}

// ── Date Divider ─────────────────────────────────────────────────────────────
class DateDivider extends StatelessWidget {
  final String label;
  const DateDivider({super.key, this.label = 'Today'});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          const Expanded(child: Divider(color: Colors.black12)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(label,
                style:
                    const TextStyle(fontSize: 11, color: Colors.black38)),
          ),
          const Expanded(child: Divider(color: Colors.black12)),
        ]),
      );
}

// ── Star Rating Widget ────────────────────────────────────────────────────────
class StarRating extends StatefulWidget {
  final int initialRating;
  final ValueChanged<int> onRated;

  const StarRating({
    super.key,
    this.initialRating = 0,
    required this.onRated,
  });

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final star = i + 1;
        return GestureDetector(
          onTap: () {
            setState(() => _current = star);
            widget.onRated(star);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              star <= _current ? Icons.star_rounded : Icons.star_border_rounded,
              size: 36,
              color: star <= _current
                  ? const Color(0xFFF4C430)
                  : Colors.grey.shade300,
            ),
          ),
        );
      }),
    );
  }
}

// ── Guideline Tile ────────────────────────────────────────────────────────────
class GuidelineTile extends StatelessWidget {
  final String text;
  const GuidelineTile(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          const Icon(Icons.check_circle_outline,
              size: 15, color: PeerTheme.sage),
          const SizedBox(width: 7),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 12, color: Colors.black87)),
          ),
        ]),
      );
}