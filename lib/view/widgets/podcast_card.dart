import 'package:flutter/material.dart';
import '../../model/podcast.dart';

class PodcastCard extends StatelessWidget {
  final Podcast podcast;
  final VoidCallback onTap;
  final bool isUnlocked;
  final bool isLiked;
  final int progressPercent; // 0–100
  final VoidCallback? onLike;

  const PodcastCard({
    super.key,
    required this.podcast,
    required this.onTap,
    this.isUnlocked = false,
    this.isLiked = false,
    this.progressPercent = 0,
    this.onLike,
  });

  bool get _locked => podcast.isPremium && !isUnlocked;

  static const Map<String, List<Color>> _gradients = {
    'Mental Health': [Color(0xFF4A6741), Color(0xFF7BAD6A)],
    'Mindfulness': [Color(0xFF1565C0), Color(0xFF42A5F5)],
    'Anxiety': [Color(0xFF6A1B9A), Color(0xFFBA68C8)],
    'Sleep': [Color(0xFF1A237E), Color(0xFF5C6BC0)],
    'Stress': [Color(0xFF880E4F), Color(0xFFF06292)],
    'Motivation': [Color(0xFFE65100), Color(0xFFFFB74D)],
  };

  List<Color> get _cardGradient =>
      _gradients[podcast.category] ??
      const [Color(0xFF4A6741), Color(0xFF7BAD6A)];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _cardGradient,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _cardGradient[0].withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Wave overlay
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: CustomPaint(painter: _WavePainter()),
              ),
            ),

            // Locked dim overlay
            if (_locked)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.25),
                  ),
                ),
              ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _Thumbnail(imageUrl: podcast.imageUrl, locked: _locked),
                      const SizedBox(width: 12),
                      Expanded(child: _Info(podcast: podcast)),
                      _ActionButton(
                        locked: _locked,
                        isLiked: isLiked,
                        onLike: onLike,
                        price: podcast.price,
                      ),
                    ],
                  ),
                  // Progress bar
                  if (progressPercent > 0 && !_locked) ...[
                    const SizedBox(height: 10),
                    _ProgressRow(percent: progressPercent),
                  ],
                ],
              ),
            ),

            // Badges
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                children: [
                  if (podcast.isNew) _badge('NEW', Colors.red.shade600),
                  if (podcast.isPremium) ...[
                    const SizedBox(width: 4),
                    _badge('PRO', Colors.amber.shade700),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Thumbnail extends StatelessWidget {
  final String imageUrl;
  final bool locked;
  const _Thumbnail({required this.imageUrl, required this.locked});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: 68,
                height: 68,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.mic_rounded,
                  color: Colors.white70,
                  size: 32,
                ),
              ),
            )
          else
            const Icon(Icons.mic_rounded, color: Colors.white70, size: 32),
          if (locked)
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.lock_rounded,
                  color: Colors.white, size: 24),
            ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final Podcast podcast;
  const _Info({required this.podcast});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          podcast.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          podcast.author,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75), fontSize: 11),
        ),
        const SizedBox(height: 6),
        Row(children: [
          _chip(Icons.folder_outlined, podcast.category),
          const SizedBox(width: 8),
          _chip(Icons.access_time_rounded, podcast.duration),
          const SizedBox(width: 8),
          _chip(Icons.play_arrow_rounded, '${podcast.playCount}'),
        ]),
        if (podcast.isPremium && podcast.price > 0) ...[
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.5)),
            ),
            child: Text(
              '₹${podcast.price.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _chip(IconData icon, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.white60, size: 11),
      const SizedBox(width: 3),
      Text(label,
          style: const TextStyle(color: Colors.white60, fontSize: 10)),
    ]);
  }
}

class _ActionButton extends StatelessWidget {
  final bool locked;
  final bool isLiked;
  final double price;
  final VoidCallback? onLike;

  const _ActionButton({
    required this.locked,
    required this.isLiked,
    required this.price,
    this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    if (locked) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.25),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber, width: 1.5),
            ),
            child: const Icon(Icons.lock_rounded,
                color: Colors.amber, size: 20),
          ),
          const SizedBox(height: 4),
          const Text(
            'Unlock',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.play_arrow_rounded,
              color: Colors.white, size: 26),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onLike,
          child: Icon(
            isLiked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: isLiked ? Colors.red.shade400 : Colors.white60,
            size: 18,
          ),
        ),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final int percent;
  const _ProgressRow({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent / 100,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor:
                const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$percent% completed',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7), fontSize: 10),
        ),
      ],
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.45,
          size.width * 0.5, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.75,
          size.width, size.height * 0.6)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter _) => false;
}