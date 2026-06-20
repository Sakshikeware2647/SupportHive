import 'package:flutter/material.dart';
import '/model/expert_model.dart';
import '/service/expert_firestore_service.dart';
import '/view/screens/counselling/expert_app_theme.dart';
import '/view/screens/counselling/booking_screen.dart';
import '/view/screens/counselling/expert_chat_screen.dart';
import '/view/screens/add_expert_screen.dart';
import '/view/screens/expert_detail_screen.dart';

class ExpertsScreen extends StatefulWidget {
  const ExpertsScreen({super.key});

  @override
  State<ExpertsScreen> createState() => _ExpertsScreenState();
}

class _ExpertsScreenState extends State<ExpertsScreen>
    with SingleTickerProviderStateMixin {
  String _selectedCategory = 'all';
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  late AnimationController _fadeCtrl;

  final List<_Category> _categories = [
    _Category('all', 'All', Icons.grid_view_rounded),
    _Category('anxiety', 'Anxiety', Icons.psychology_rounded),
    _Category('depression', 'Depression', Icons.mood_bad_rounded),
    _Category('sleep', 'Sleep', Icons.bedtime_rounded),
    _Category('child', 'Child', Icons.child_care_rounded),
    _Category('medical', 'Medical', Icons.medical_services_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeCtrl.forward();
    ExpertFirestoreService.instance.seedExperts();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildFreeBanner()),
          SliverToBoxAdapter(child: _buildSearch()),
          SliverToBoxAdapter(child: _buildCategories()),
          _buildExpertsList(),
        ],
      ),
      floatingActionButton: _buildAdminFab(),
    );
  }

  // ── App bar ──────────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.headerGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Licensed Experts',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              )),
                          Text('Professional psychiatric consultation',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              )),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Free banner ──────────────────────────────────────────────────────────────
  Widget _buildFreeBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: AppTheme.freeBannerGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.trending_up_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('First 30 Minutes FREE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      )),
                  Text('Try a free chat session with any new expert (one-time offer)',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search ───────────────────────────────────────────────────────────────────
  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: AppTheme.primary.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 2)),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Search by name or specialization…',
            hintStyle: AppTheme.bodySm,
            prefixIcon: Icon(Icons.search_rounded,
                color: AppTheme.primary.withOpacity(0.5)),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    })
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // ── Category chips ───────────────────────────────────────────────────────────
  Widget _buildCategories() {
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final selected = _selectedCategory == cat.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: selected
                    ? [
                        BoxShadow(
                            color: AppTheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(cat.icon,
                      size: 14,
                      color: selected ? Colors.white : AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text(cat.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                            selected ? Colors.white : AppTheme.textSecondary,
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Experts list ─────────────────────────────────────────────────────────────
  Widget _buildExpertsList() {
    return StreamBuilder<List<Expert>>(
      stream: ExpertFirestoreService.instance
          .expertsStream(category: _selectedCategory),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          );
        }

        var experts = snap.data ?? Expert.seedExperts;

        // Filter by search
        if (_searchQuery.isNotEmpty) {
          experts = experts
              .where((e) =>
                  e.name.toLowerCase().contains(_searchQuery) ||
                  e.specialization.toLowerCase().contains(_searchQuery) ||
                  e.tags
                      .any((t) => t.toLowerCase().contains(_searchQuery)))
              .toList();
        }

        if (experts.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded,
                      size: 64, color: AppTheme.primary.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text('No experts found',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _ExpertCard(expert: experts[i]),
              childCount: experts.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdminFab() {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddExpertScreen()),
      ),
      backgroundColor: AppTheme.primary,
      icon: const Icon(Icons.person_add_rounded, color: Colors.white),
      label: const Text('Add Expert',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Expert Card ──────────────────────────────────────────────────────────────
class _ExpertCard extends StatelessWidget {
  final Expert expert;
  const _ExpertCard({required this.expert});

  Color get _avatarColor {
    if (expert.avatarColor != null) {
      try {
        return Color(
            int.parse(expert.avatarColor!.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }
    return AppTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          _tags(),
          _clinicRow(),
          _freeTrialBanner(),
          _actionButtons(context),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _avatarColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: _avatarColor.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Center(
              child: Text(expert.avatarInitials,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(expert.name,
                          style: AppTheme.titleSm
                              .copyWith(fontSize: 15)),
                    ),
                    _availabilityBadge(),
                  ],
                ),
                const SizedBox(height: 2),
                Text(expert.specialization, style: AppTheme.bodySm),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFF59E0B), size: 14),
                    const SizedBox(width: 3),
                    Text('${expert.rating}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: AppTheme.textPrimary)),
                    Text(' (${expert.reviewCount})',
                        style: AppTheme.bodySm
                            .copyWith(fontSize: 11)),
                    const SizedBox(width: 8),
                    Container(
                        width: 1, height: 12, color: AppTheme.divider),
                    const SizedBox(width: 8),
                    Text('${expert.experienceYears} yrs exp',
                        style: AppTheme.bodySm.copyWith(fontSize: 11)),
                    const Spacer(),
                    Text('₹${expert.price}',
                        style: TextStyle(
                            color: _avatarColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _availabilityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: expert.isAvailable
            ? AppTheme.available.withOpacity(0.12)
            : AppTheme.unavailable.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: expert.isAvailable
                  ? AppTheme.available
                  : AppTheme.unavailable,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            expert.isAvailable ? 'Available' : 'Busy',
            style: TextStyle(
              color: expert.isAvailable
                  ? AppTheme.available
                  : AppTheme.unavailable,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tags() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: expert.tags
            .map((t) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: AppTheme.chipDecoration(_avatarColor),
                  child: Text(t,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _avatarColor)),
                ))
            .toList(),
      ),
    );
  }

  Widget _clinicRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Icon(Icons.location_on_rounded,
              size: 13, color: AppTheme.textSecondary.withOpacity(0.7)),
          const SizedBox(width: 4),
          Text(expert.clinic,
              style: AppTheme.bodySm.copyWith(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _freeTrialBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppTheme.accent.withOpacity(0.25), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎉',
                style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Text(
              'First 30 minutes FREE with this expert',
              style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _ActionBtn(
            label: 'Chat',
            icon: Icons.chat_bubble_rounded,
            color: const Color(0xFF0EA5E9),
            onTap: expert.offersChat
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ExpertChatScreen(expert: expert)))
                : null,
          ),
          const SizedBox(width: 8),
          _ActionBtn(
            label: 'Call',
            icon: Icons.call_rounded,
            color: AppTheme.accent,
            onTap: expert.offersAudio && expert.isAvailable
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => BookingScreen(
                            expert: expert,
                            initialType: 'audio')))
                : null,
          ),
          const SizedBox(width: 8),
          _ActionBtn(
            label: 'Video',
            icon: Icons.videocam_rounded,
            color: const Color(0xFF8B5CF6),
            onTap: expert.offersVideo && expert.isAvailable
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => BookingScreen(
                            expert: expert,
                            initialType: 'video')))
                : null,
          ),
          const SizedBox(width: 8),
          _BookBtn(
            onTap: expert.isAvailable
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            BookingScreen(expert: expert)))
                : null,
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: disabled ? Colors.grey.shade100 : color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18,
                color: disabled ? Colors.grey.shade400 : color),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: disabled ? Colors.grey.shade400 : color)),
          ],
        ),
      ),
    );
  }
}

class _BookBtn extends StatelessWidget {
  final VoidCallback? onTap;
  const _BookBtn({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: onTap != null
                ? AppTheme.headerGradient
                : const LinearGradient(
                    colors: [Color(0xFFD1D5DB), Color(0xFFD1D5DB)]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: onTap != null
                ? [
                    BoxShadow(
                        color: AppTheme.primary.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_month_rounded,
                  size: 14,
                  color: onTap != null ? Colors.white : Colors.grey.shade400),
              const SizedBox(width: 6),
              Text('Book',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color:
                          onTap != null ? Colors.white : Colors.grey.shade400)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Category {
  final String id;
  final String label;
  final IconData icon;
  _Category(this.id, this.label, this.icon);
}
