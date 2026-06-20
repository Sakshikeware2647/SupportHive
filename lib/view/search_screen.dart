import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

// ─── Real screen imports ─────────────────────────────────────────────────────
// ⚠️  IMPORTANT: Adjust these paths to match your actual project folder structure.
// The class names below are correct — only the folder paths may need updating.

// AI Chat (from: view/screens/counselling/ai_chat_screen.dart)
import 'package:supporthive1/view/screens/counselling/ai_chat_screen.dart';

// Music Library (check your actual folder — common paths below, uncomment the right one)
import 'package:supporthive1/view/widgets/music_library_screen.dart';
// import 'package:supporthive1/view/music_library_screen.dart';

// Notes / Diary (from: view/screens/notes/notes_screen.dart)
import 'package:supporthive1/view/notes_screen.dart';
// import 'package:supporthive1/view/notes_screen.dart';

// Quiz (from: view/quiz.dart)
import 'package:supporthive1/view/quiz.dart';
import 'package:supporthive1/view/widgets/podcast_section.dart';

// Wellness Status (check your actual folder)
import 'package:supporthive1/view/widgets/wellness_status_screen.dart';
// import 'package:supporthive1/view/wellness_status_screen.dart';

// ─── Route keys — map each item title to its destination ────────────────────
enum _Destination {
  natureSounds,
  sleepSounds,
  meditationMusic,
  anxietyRelief,
  stressManagement,
  mindfulnessPodcast,
  dailyJournal,
  moodTracker,
  gratitudeLog,
  anxietyQuiz,
  wellnessCheck,
  stressTest,
  aiChat,
  breathingExercise,
  bodyScan,
  mindfulnessGame,
}

// ─── Data model ──────────────────────────────────────────────────────────────
class _SearchItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String category;
  final _Destination destination;
  final String tag; // hero tag

  const _SearchItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.category,
    required this.destination,
    required this.tag,
  });
}

// ─── Navigation helper ───────────────────────────────────────────────────────
// Maps every destination to its real screen widget.
Widget _screenFor(_Destination dest) {
  switch (dest) {
    // ── AI ──────────────────────────────────────────────────────────────────
    case _Destination.aiChat:
      return const AIChatScreen();

    // ── Music — all three items open MusicLibraryScreen ─────────────────────
    case _Destination.natureSounds:
    case _Destination.sleepSounds:
    case _Destination.meditationMusic:
      return const MusicLibraryScreen();

    // ── Podcast — replace _PlaceholderScreen with your podcast screen ────────
    case _Destination.anxietyRelief:
    case _Destination.stressManagement:
    case _Destination.mindfulnessPodcast:
      return const PodcastSection();

    // ── Diary — all diary items open NotesScreen ─────────────────────────────
    case _Destination.dailyJournal:
    case _Destination.moodTracker:
    case _Destination.gratitudeLog:
      return const NotesScreen();

    // ── Quiz — all quiz items open WellnessQuizScreen ───────────────────────
    case _Destination.anxietyQuiz:
    case _Destination.wellnessCheck:
    case _Destination.stressTest:
      return const WellnessQuizScreen();

    // ── Activity — opens WellnessStatusScreen ────────────────────────────────
    case _Destination.breathingExercise:
    case _Destination.bodyScan:
      return const WellnessStatusScreen();

    // ── Game — replace _PlaceholderScreen with your game screen ──────────────
    case _Destination.mindfulnessGame:
      return const _PlaceholderScreen(title: 'Mindfulness Game');
  }
}

// ─── Placeholder — only for screens not yet built (Podcast & Game) ───────────
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title, super.key});

  static const Color _green = Color(0xFF4A6741);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _green, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title,
            style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: 17)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.construction_rounded,
                  color: _green, size: 36),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 8),
            const Text('Coming soon — connect your screen here',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ─── Main SearchScreen ────────────────────────────────────────────────────────
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────────────────────────────
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // ── Animation controllers ────────────────────────────────────────────────
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  // ── Theme ────────────────────────────────────────────────────────────────
  static const Color _brandGreen = Color(0xFF4A6741);
  static const Color _bgColor = Color(0xFFF5F5F0);
  static const Color _cardColor = Colors.white;

  // ── All searchable items ─────────────────────────────────────────────────
  static const List<_SearchItem> _allItems = [
    _SearchItem(
      title: 'Nature Sounds',
      subtitle: 'Calming audio for relaxation',
      icon: Icons.forest_rounded,
      color: Color(0xFF7B1FA2),
      category: 'Music',
      destination: _Destination.natureSounds,
      tag: 'nature_sounds',
    ),
    _SearchItem(
      title: 'Sleep Sounds',
      subtitle: 'Deep sleep audio tracks',
      icon: Icons.bedtime_rounded,
      color: Color(0xFF5E35B1),
      category: 'Music',
      destination: _Destination.sleepSounds,
      tag: 'sleep_sounds',
    ),
    _SearchItem(
      title: 'Meditation Music',
      subtitle: 'Focus and calm your mind',
      icon: Icons.self_improvement_rounded,
      color: Color(0xFF8E24AA),
      category: 'Music',
      destination: _Destination.meditationMusic,
      tag: 'meditation_music',
    ),
    _SearchItem(
      title: 'Anxiety Relief',
      subtitle: 'Expert podcast on managing anxiety',
      icon: Icons.mic_rounded,
      color: Color(0xFF1565C0),
      category: 'Podcast',
      destination: _Destination.anxietyRelief,
      tag: 'anxiety_relief',
    ),
    _SearchItem(
      title: 'Stress Management',
      subtitle: 'Weekly wellness podcast',
      icon: Icons.headphones_rounded,
      color: Color(0xFF0277BD),
      category: 'Podcast',
      destination: _Destination.stressManagement,
      tag: 'stress_mgmt',
    ),
    _SearchItem(
      title: 'Mindfulness Podcast',
      subtitle: 'Daily mindfulness practices',
      icon: Icons.podcasts_rounded,
      color: Color(0xFF0288D1),
      category: 'Podcast',
      destination: _Destination.mindfulnessPodcast,
      tag: 'mindfulness_pod',
    ),
    _SearchItem(
      title: 'Daily Journal',
      subtitle: 'Write and reflect on your day',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF2E7D32),
      category: 'Diary',
      destination: _Destination.dailyJournal,
      tag: 'daily_journal',
    ),
    _SearchItem(
      title: 'Mood Tracker',
      subtitle: 'Track your emotional patterns',
      icon: Icons.mood_rounded,
      color: Color(0xFF388E3C),
      category: 'Diary',
      destination: _Destination.moodTracker,
      tag: 'mood_tracker',
    ),
    _SearchItem(
      title: 'Gratitude Log',
      subtitle: 'Daily gratitude practice',
      icon: Icons.favorite_rounded,
      color: Color(0xFF43A047),
      category: 'Diary',
      destination: _Destination.gratitudeLog,
      tag: 'gratitude_log',
    ),
    _SearchItem(
      title: 'Anxiety Quiz',
      subtitle: 'Assess your anxiety levels',
      icon: Icons.quiz_rounded,
      color: Color(0xFFE65100),
      category: 'Quiz',
      destination: _Destination.anxietyQuiz,
      tag: 'anxiety_quiz',
    ),
    _SearchItem(
      title: 'Wellness Check',
      subtitle: 'Full mental wellness assessment',
      icon: Icons.health_and_safety_rounded,
      color: Color(0xFFF57C00),
      category: 'Quiz',
      destination: _Destination.wellnessCheck,
      tag: 'wellness_check',
    ),
    _SearchItem(
      title: 'Stress Test',
      subtitle: 'Measure your stress levels',
      icon: Icons.psychology_rounded,
      color: Color(0xFFEF6C00),
      category: 'Quiz',
      destination: _Destination.stressTest,
      tag: 'stress_test',
    ),
    _SearchItem(
      title: 'Chat with Hive AI',
      subtitle: 'Your personal wellness assistant',
      icon: Icons.smart_toy_rounded,
      color: Color(0xFF4A6741),
      category: 'AI',
      destination: _Destination.aiChat,
      tag: 'hive_ai',
    ),
    _SearchItem(
      title: 'Breathing Exercise',
      subtitle: '4-7-8 breathing technique',
      icon: Icons.air_rounded,
      color: Color(0xFF00695C),
      category: 'Activity',
      destination: _Destination.breathingExercise,
      tag: 'breathing',
    ),
    _SearchItem(
      title: 'Body Scan',
      subtitle: 'Progressive muscle relaxation',
      icon: Icons.accessibility_new_rounded,
      color: Color(0xFF00838F),
      category: 'Activity',
      destination: _Destination.bodyScan,
      tag: 'body_scan',
    ),
    _SearchItem(
      title: 'Mindfulness Game',
      subtitle: 'Play your way to calm & focus',
      icon: Icons.videogame_asset_rounded,
      color: Color(0xFFD81B60),
      category: 'Game',
      destination: _Destination.mindfulnessGame,
      tag: 'mindfulness_game',
    ),
  ];

  List<_SearchItem> _filteredItems = [];
  List<String> _recentSearches = [];
  String _activeCategory = 'All';
  bool _isLoading = false;
  Timer? _debounce;

  final List<Map<String, dynamic>> _categories = [
    {'label': 'All', 'icon': Icons.apps_rounded, 'color': Color(0xFF4A6741)},
    {'label': 'Music', 'icon': Icons.music_note_rounded, 'color': Color(0xFF7B1FA2)},
    {'label': 'Podcast', 'icon': Icons.mic_rounded, 'color': Color(0xFF1565C0)},
    {'label': 'Diary', 'icon': Icons.menu_book_rounded, 'color': Color(0xFF2E7D32)},
    {'label': 'Quiz', 'icon': Icons.quiz_rounded, 'color': Color(0xFFE65100)},
    {'label': 'Activity', 'icon': Icons.directions_run_rounded, 'color': Color(0xFF00695C)},
    {'label': 'AI', 'icon': Icons.smart_toy_rounded, 'color': Color(0xFF4A6741)},
    {'label': 'Game', 'icon': Icons.videogame_asset_rounded, 'color': Color(0xFFD81B60)},
  ];

  // ── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(_allItems);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();

    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onSearchChanged);
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // ── Logic ────────────────────────────────────────────────────────────────
  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      _filterItems();
    });
  }

  void _filterItems() {
    final query = _controller.text.toLowerCase().trim();
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      setState(() {
        _filteredItems = _allItems.where((item) {
          final matchesQuery = query.isEmpty ||
              item.title.toLowerCase().contains(query) ||
              item.subtitle.toLowerCase().contains(query) ||
              item.category.toLowerCase().contains(query);
          final matchesCategory =
              _activeCategory == 'All' || item.category == _activeCategory;
          return matchesQuery && matchesCategory;
        }).toList();
        _isLoading = false;
      });
    });
  }

  void _selectCategory(String category) {
    HapticFeedback.selectionClick();
    setState(() => _activeCategory = category);
    _filterItems();
  }

  void _submitSearch(String query) {
    if (query.trim().isEmpty) return;
    setState(() {
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 6) {
        _recentSearches = _recentSearches.sublist(0, 6);
      }
    });
  }

  void _clearSearch() {
    HapticFeedback.lightImpact();
    _controller.clear();
    setState(() => _activeCategory = 'All');
    _filterItems();
    _focusNode.unfocus();
  }

  void _tapRecentSearch(String query) {
    _controller.text = query;
    _controller.selection =
        TextSelection.collapsed(offset: query.length);
    _filterItems();
  }

  void _removeRecent(String query) {
    HapticFeedback.lightImpact();
    setState(() => _recentSearches.remove(query));
  }

  void _onItemTap(_SearchItem item) {
    HapticFeedback.mediumImpact();
    _submitSearch(item.title);
    _focusNode.unfocus();

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => _screenFor(item.destination),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bool isSearching = _controller.text.isNotEmpty;

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              children: [
                _buildHeader(),
                _buildSearchBar(),
                _buildCategoryChips(),
                const SizedBox(height: 4),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.04),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: isSearching
                        ? _buildResults(key: const ValueKey('results'))
                        : _buildEmptyState(key: const ValueKey('empty')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Search',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Find your wellness tools',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const Spacer(),
          AnimatedOpacity(
            opacity: _controller.text.isNotEmpty ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: _clearSearch,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _brandGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Clear',
                  style: TextStyle(
                    color: _brandGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Bar ───────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          textInputAction: TextInputAction.search,
          onSubmitted: _submitSearch,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: 'Music, podcasts, breathing…',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(Icons.search_rounded,
                  color: _controller.text.isNotEmpty
                      ? _brandGreen
                      : Colors.grey.shade400,
                  size: 22),
            ),
            suffixIcon: _controller.text.isNotEmpty
                ? GestureDetector(
                    onTap: _clearSearch,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded,
                          color: Colors.grey.shade500, size: 16),
                    ),
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade100, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _brandGreen, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  // ── Category Chips ───────────────────────────────────────────────────────
  Widget _buildCategoryChips() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final isSelected = _activeCategory == cat['label'];
          final color = cat['color'] as Color;

          return GestureDetector(
            onTap: () => _selectCategory(cat['label'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade200,
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        )
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat['icon'] as IconData,
                    size: 14,
                    color: isSelected ? Colors.white : color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Empty State ──────────────────────────────────────────────────────────
  Widget _buildEmptyState({Key? key}) {
    return SingleChildScrollView(
      key: key,
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentSearches.isNotEmpty) ...[
            _buildSectionHeader('Recent Searches', onClearAll: () {
              setState(() => _recentSearches.clear());
            }),
            const SizedBox(height: 8),
            ..._recentSearches.map((q) => _recentSearchTile(q)).toList(),
            const SizedBox(height: 24),
          ],

          _buildSectionHeader('Browse Categories'),
          const SizedBox(height: 12),
          _buildCategoryGrid(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String text, {VoidCallback? onClearAll}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            letterSpacing: -0.2,
          ),
        ),
        const Spacer(),
        if (onClearAll != null)
          GestureDetector(
            onTap: onClearAll,
            child: Text(
              'Clear all',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _recentSearchTile(String query) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        dense: true,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              Icon(Icons.history_rounded, size: 17, color: Colors.grey.shade500),
        ),
        title: Text(
          query,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87),
        ),
        trailing: GestureDetector(
          onTap: () => _removeRecent(query),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.close_rounded,
                size: 14, color: Colors.grey.shade400),
          ),
        ),
        onTap: () => _tapRecentSearch(query),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final displayCats = _categories.skip(1).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayCats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (_, i) {
        final cat = displayCats[i];
        final color = cat['color'] as Color;
        return _CategoryGridTile(
          label: cat['label'] as String,
          icon: cat['icon'] as IconData,
          color: color,
          onTap: () {
            _selectCategory(cat['label'] as String);
            _focusNode.requestFocus();
          },
        );
      },
    );
  }

  // ── Results ──────────────────────────────────────────────────────────────
  Widget _buildResults({Key? key}) {
    if (_isLoading) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(
          color: _brandGreen,
          strokeWidth: 2.5,
        ),
      );
    }

    if (_filteredItems.isEmpty) {
      return Center(
        key: key,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_off_rounded,
                  size: 34, color: Colors.grey.shade300),
            ),
            const SizedBox(height: 16),
            Text(
              'No results for',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              '"${_controller.text}"',
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different keyword or category',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _clearSearch,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _brandGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Clear search',
                  style: TextStyle(
                    color: _brandGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      key: key,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: _filteredItems.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${_filteredItems.length} result${_filteredItems.length == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }
        return _buildResultTile(_filteredItems[i - 1], animated: true, index: i - 1);
      },
    );
  }

  Widget _buildResultTile(_SearchItem item,
      {bool animated = false, int index = 0}) {
    return _AnimatedTile(
      delay: animated ? Duration(milliseconds: index * 40) : Duration.zero,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _ResultCard(
          item: item,
          onTap: () => _onItemTap(item),
        ),
      ),
    );
  }
}

// ─── Animated Tile wrapper ────────────────────────────────────────────────────
class _AnimatedTile extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _AnimatedTile({required this.child, required this.delay});

  @override
  State<_AnimatedTile> createState() => _AnimatedTileState();
}

class _AnimatedTileState extends State<_AnimatedTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fade =
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ─── Category Grid Tile ───────────────────────────────────────────────────────
class _CategoryGridTile extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryGridTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_CategoryGridTile> createState() => _CategoryGridTileState();
}

class _CategoryGridTileState extends State<_CategoryGridTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.04,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(widget.icon, color: widget.color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Result Card ──────────────────────────────────────────────────────────────
class _ResultCard extends StatefulWidget {
  final _SearchItem item;
  final VoidCallback onTap;

  const _ResultCard({required this.item, required this.onTap});

  @override
  State<_ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<_ResultCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: item.color.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: item.color, size: 24),
              ),
              const SizedBox(width: 14),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Category badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item.category,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: item.color,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 11, color: Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }
}