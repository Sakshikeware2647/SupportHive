import 'package:flutter/material.dart';
import 'package:supporthive1/view/widgets/podcast_unlocksheet.dart';
import '../../model/podcast.dart';
import '../../service/podcast_service.dart';
import 'podcast_card.dart';
import 'podcast_player_screen.dart';

/// Self-contained podcast listing widget.
/// Handles: fetch, category filter, premium access check,
/// Razorpay unlock flow, progress tracking, and likes — all in sync.
class PodcastSection extends StatefulWidget {
  const PodcastSection({super.key});

  @override
  State<PodcastSection> createState() => _PodcastSectionState();
}

class _PodcastSectionState extends State<PodcastSection> {
  static const Color _brandGreen = Color(0xFF4A6741);

  final _service = PodcastService.instance;

  List<Podcast> _all = [];
  List<Podcast> _filtered = [];
  bool _isLoading = true;
  String? _error;

  Set<String> _unlockedIds = {};
  Set<String> _likedIds = {};
  /// podcastId → completion percentage (0–100)
  Map<String, int> _progressMap = {};

  String _activeCategory = 'All';
  final List<String> _categories = [
    'All',
    'Mental Health',
    'Mindfulness',
    'Anxiety',
    'Sleep',
    'Stress',
    'Motivation',
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // ── Data loading ────────────────────────────────────────────────────────────

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _service.fetchPodcasts(),
        _service.fetchUnlockedIds(),
        _service.fetchLikedIds(),
        _service.fetchAllProgress(),
      ]);

      if (!mounted) return;
      setState(() {
        _all = results[0] as List<Podcast>;
        _unlockedIds = results[1] as Set<String>;
        _likedIds = results[2] as Set<String>;
        _progressMap = results[3] as Map<String, int>;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    _filtered = _activeCategory == 'All'
        ? List.from(_all)
        : _all.where((p) => p.category == _activeCategory).toList();
  }

  void _selectCategory(String cat) {
    setState(() {
      _activeCategory = cat;
      _applyFilter();
    });
  }

  bool _isUnlocked(Podcast p) =>
      !p.isPremium || _unlockedIds.contains(p.id);

  // ── Card tap → unlock or play ───────────────────────────────────────────────

  Future<void> _onCardTap(Podcast podcast) async {
    if (podcast.isPremium && !_isUnlocked(podcast)) {
      await _handleUnlock(podcast);
      return;
    }
    _navigateToPlayer(podcast);
  }

  Future<void> _handleUnlock(Podcast podcast) async {
    final didUnlock = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Prevent dismiss by dragging while payment is in progress:
      isDismissible: true,
      enableDrag: true,
      builder: (_) => PodcastUnlockSheet(podcast: podcast),
    );

    if (!mounted) return;

    if (didUnlock == true) {
      // Refresh unlocked IDs from Firestore for accuracy
      final ids = await _service.fetchUnlockedIds();
      if (!mounted) return;
      setState(() => _unlockedIds = ids);

      // Small delay so the sheet dismisses cleanly before navigation
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      _navigateToPlayer(podcast);
    }
  }

  void _navigateToPlayer(Podcast podcast) {
    // Optimistic play-count increment (fire-and-forget)
    _service.incrementPlayCount(podcast.id);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PodcastPlayerScreen(
          podcast: podcast,
          onProgressUpdate: (id, seconds, duration) {
            if (duration <= 0 || !mounted) return;
            final pct =
                ((seconds / duration) * 100).round().clamp(0, 100);
            // Persist to SharedPreferences
            _service.saveProgress(id, Duration(seconds: seconds));
            // Update in-memory map so card progress bar refreshes on pop
            setState(() => _progressMap[id] = pct);
          },
        ),
      ),
    );
  }

  // ── Like toggle ─────────────────────────────────────────────────────────────

  Future<void> _toggleLike(Podcast p) async {
    final wasLiked = _likedIds.contains(p.id);
    // Optimistic update
    setState(() {
      if (wasLiked) {
        _likedIds.remove(p.id);
      } else {
        _likedIds.add(p.id);
      }
    });
    await _service.toggleLike(p.id, !wasLiked);
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildCategoryChips(),
              const SizedBox(height: 14),
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.mic_rounded, color: _brandGreen),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Podcasts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        if (_error != null)
          Tooltip(
            message: 'Some podcasts could not be loaded',
            child: Icon(Icons.warning_amber_rounded,
                color: Colors.orange.shade600, size: 18),
          ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded,
              size: 20, color: _brandGreen),
          tooltip: 'Refresh',
          onPressed: _loadAll,
        ),
      ],
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final selected = _activeCategory == cat;
          return GestureDetector(
            onTap: () => _selectCategory(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? _brandGreen : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      selected ? _brandGreen : Colors.grey.shade300,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: _brandGreen.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [],
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(color: _brandGreen),
        ),
      );
    }

    if (_filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.mic_off_rounded,
                  size: 52, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'No podcasts in $_activeCategory',
                style:
                    TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _selectCategory('All'),
                child: const Text('View all',
                    style: TextStyle(color: _brandGreen)),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _filtered.map((p) {
        return PodcastCard(
          key: ValueKey(p.id),
          podcast: p,
          isUnlocked: _isUnlocked(p),
          isLiked: _likedIds.contains(p.id),
          progressPercent: _progressMap[p.id] ?? 0,
          onLike: () => _toggleLike(p),
          onTap: () => _onCardTap(p),
        );
      }).toList(),
    );
  }
}