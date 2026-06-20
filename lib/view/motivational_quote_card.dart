import 'package:flutter/material.dart';
import 'package:supporthive1/model/quote.dart';
import 'package:supporthive1/service/quote_service.dart';

/// Drop-in replacement for the old MotivationalQuoteCard.
/// Fetches today's quote from ZenQuotes (cached for the day, no repeats).
/// Falls back to a curated offline list if network is unavailable.
class MotivationalQuoteCard extends StatefulWidget {
  /// [quote] is kept as an optional param so the existing call-site in
  /// home_screen.dart still compiles with zero changes — just pass null or
  /// omit it and the widget will self-fetch.
  final Quote? quote;

  const MotivationalQuoteCard({super.key, this.quote});

  @override
  State<MotivationalQuoteCard> createState() => _MotivationalQuoteCardState();
}

class _MotivationalQuoteCardState extends State<MotivationalQuoteCard>
    with SingleTickerProviderStateMixin {
  Quote? _quote;
  bool _loading = true;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    // If a quote was passed (legacy usage), use it immediately
    if (widget.quote != null) {
      _quote   = widget.quote;
      _loading = false;
      _animCtrl.forward();
    } else {
      _loadQuote();
    }
  }

  Future<void> _loadQuote() async {
    final q = await QuoteService.getDailyQuote();
    if (mounted) {
      setState(() {
        _quote   = q;
        _loading = false;
      });
      _animCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E5D2E), Color(0xFF4A8040), Color(0xFF3A6B3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E5D2E).withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -20, right: -20,
              child: _decorCircle(80, Colors.white.withOpacity(0.07)),
            ),
            Positioned(
              bottom: -30, left: -10,
              child: _decorCircle(100, Colors.white.withOpacity(0.05)),
            ),
            Positioned(
              top: 30, right: 40,
              child: _decorCircle(30, Colors.white.withOpacity(0.06)),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: _loading ? _buildShimmer() : _buildQuoteContent(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quote content ─────────────────────────────────────────────────────────
  Widget _buildQuoteContent() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.amber, size: 13),
                      SizedBox(width: 5),
                      Text(
                        'Quote of the Day',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Refresh icon (manual refresh for the day)
                GestureDetector(
                  onTap: _loading ? null : () {
                    setState(() => _loading = true);
                    _animCtrl.reset();
                    _loadQuote();
                  },
                  child: Icon(
                    Icons.refresh_rounded,
                    color: Colors.white.withOpacity(0.5),
                    size: 18,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Opening quote mark
            Text(
              '\u201C',
              style: TextStyle(
                fontSize: 48,
                color: Colors.white.withOpacity(0.25),
                height: 0.7,
                fontFamily: 'Georgia',
              ),
            ),

            const SizedBox(height: 4),

            // Quote text
            Text(
              _quote!.text.replaceAll(RegExp(r'^"|"$'), ''),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.55,
                letterSpacing: 0.2,
              ),
            ),

            const SizedBox(height: 14),

            // Divider + author
            if (_quote!.author.isNotEmpty) ...[
              Row(
                children: [
                  Container(
                    height: 1,
                    width: 28,
                    color: Colors.white.withOpacity(0.35),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '— ${_quote!.author}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Shimmer loading placeholder ───────────────────────────────────────────
  Widget _buildShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _shimmerBar(80, 16),
        const SizedBox(height: 20),
        _shimmerBar(double.infinity, 14),
        const SizedBox(height: 8),
        _shimmerBar(double.infinity, 14),
        const SizedBox(height: 8),
        _shimmerBar(160, 14),
        const SizedBox(height: 16),
        _shimmerBar(100, 12),
      ],
    );
  }

  Widget _shimmerBar(double width, double height) {
    return _AnimatedShimmerBar(width: width, height: height);
  }

  // ── Decorative circle helper ──────────────────────────────────────────────
  Widget _decorCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

// ── Animated shimmer bar ──────────────────────────────────────────────────────
class _AnimatedShimmerBar extends StatefulWidget {
  final double width;
  final double height;
  const _AnimatedShimmerBar({required this.width, required this.height});

  @override
  State<_AnimatedShimmerBar> createState() => _AnimatedShimmerBarState();
}

class _AnimatedShimmerBarState extends State<_AnimatedShimmerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.25, end: 0.55).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(_anim.value),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}