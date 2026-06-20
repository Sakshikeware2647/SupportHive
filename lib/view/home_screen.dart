import 'package:flutter/material.dart';
import 'package:supporthive1/controller/home_controller.dart';
import 'package:supporthive1/model/user_profile_model.dart';
import 'package:supporthive1/service/profile_service.dart';
import 'package:supporthive1/view/screens/counselling/ai_chat_screen.dart';
import 'package:supporthive1/view/search_screen.dart';
import 'package:supporthive1/view/games_screen.dart';
import 'package:supporthive1/view/screens/counselling/counselling_screen.dart';
import 'package:supporthive1/view/widgets/app_drawer.dart';
import 'package:supporthive1/view/widgets/bottom_navigation_bar.dart';
import 'package:supporthive1/view/widgets/notification_overall.dart';
import 'package:supporthive1/view/widgets/profile_screen.dart';
import 'widgets/motivational_quote_card.dart';
import 'widgets/quiz_journal_section.dart';
import 'widgets/music_section.dart';
import 'widgets/podcast_section.dart';
import 'widgets/activities_section.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController _controller = HomeController();
  final ProfileService _profileService = ProfileService();
  UserProfileModel? _profile;

  static const Color _brandGreen = Color(0xFF4A6741);

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.createOrFetchProfile();
      if (mounted) setState(() => _profile = profile);
    } catch (_) {}

    _profileService.profileStream().listen((updated) {
      if (updated != null && mounted) setState(() => _profile = updated);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: CustomBottomNavigationBar(controller: _controller),
      floatingActionButton: _buildFAB(),
    );
  }

  // ── FAB ───────────────────────────────────────────────────────────────────
  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: _brandGreen.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        shape: BoxShape.circle,
      ),
      child: FloatingActionButton(
        backgroundColor: _brandGreen,
        tooltip: 'Chat with Hive AI',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AIChatScreen()),
        ),
        child: const Text('🐝', style: TextStyle(fontSize: 22)),
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.black87),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.spa_outlined, color: Colors.teal.shade600, size: 20),
          const SizedBox(width: 6),
          const Text(
            'SUPPORTHIVE',
            style: TextStyle(
              color: _brandGreen,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.notifications_outlined, color: Colors.black87),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(  
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NotificationOverallScreen()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () {
              if (_profile != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(initialProfile: _profile!),
                  ),
                );
              }
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _brandGreen.withOpacity(0.3), width: 2),
              ),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: _brandGreen,
                child: _profile?.photoUrl.isNotEmpty == true
                    ? ClipOval(
                        child: Image.network(
                          _profile!.photoUrl,
                          width: 34,
                          height: 34,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _profileInitials(),
                        ),
                      )
                    : _profileInitials(),
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.grey.shade100),
      ),
    );
  }

  Widget _profileInitials() {
    return Text(
      _profile?.initials ?? 'U',
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
    );
  }

  // ── Tab Router ────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _brandGreen),
      );
    }
    switch (_controller.selectedTabIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const SearchScreen();
      case 2:
        return const CounsellingScreen();
      case 3:
        return const MindfulGamesScreen();
      default:
        return _buildHomeTab();
    }
  }

  // ── Home Tab ──────────────────────────────────────────────────────────────
  Widget _buildHomeTab() {
    return RefreshIndicator(
      color: _brandGreen,
      onRefresh: _controller.refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            MotivationalQuoteCard(quote: _controller.dailyQuote),
            QuizJournalSection(
              onOpenDiary: _controller.onOpenDiary,
              onTakeQuiz: _controller.onTakeQuiz,
              onCheckStatus: () => _controller.onCheckWellnessStatus(context),
            ),
            _buildAIChatBanner(),
            MusicSection(
              musicList: _controller.musicList,
              onPlayMusic: _controller.onPlayMusic,
            ),
            const PodcastSection(),
            ActivitiesSection(
              activities: _controller.activities,
              onStartActivity: _controller.onStartActivity,
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  // ── Welcome Card ──────────────────────────────────────────────────────────
  Widget _buildWelcomeCard() {
    final greeting = _getGreeting();
    final name = _profile?.name ?? _controller.userName;
    final hour = DateTime.now().hour;
    final timeEmoji = hour < 12 ? '🌅' : hour < 17 ? '☀️' : '🌙';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade200.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(timeEmoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      greeting,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  name.isNotEmpty ? '$name 👋' : 'Welcome back 👋',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Relax, Recharge, Reflect — your wellness journey continues.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Mini wellness ring
          _WellnessMiniRing(),
        ],
      ),
    );
  }

  // ── AI Chat Banner ────────────────────────────────────────────────────────
  Widget _buildAIChatBanner() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AIChatScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2F6B2F), Color(0xFF4A8C4A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A6741).withOpacity(0.25),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text('🐝', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chat with Hive AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Ask about stress, anxiety, or find any app feature',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

// ─────────────────────────────────────────────────────────
// Wellness Mini Ring (decorative)
// ─────────────────────────────────────────────────────────
class _WellnessMiniRing extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF4A6741).withOpacity(0.2),
          width: 4,
        ),
        color: const Color(0xFF4A6741).withOpacity(0.08),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🌿', style: TextStyle(fontSize: 22)),
          ],
        ),
      ),
    );
  }
}