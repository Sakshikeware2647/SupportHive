/// ─────────────────────────────────────────────────────────────────────────────
/// view/screens/admin/admin_dashboard_screen.dart
///
/// Root screen of the admin panel. Shows a stats overview and hosts the
/// bottom nav for Experts / Bookings tabs.
/// ─────────────────────────────────────────────────────────────────────────────

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:supporthive1/view/admin_booking_tab.dart';
import 'package:supporthive1/view/admin_expert_tab.dart';
import 'package:supporthive1/view/admin_podcast_tab.dart';
import 'package:supporthive1/view/screens/counselling/Intern_dashboard_screen.dart';
import '/service/admin_firestore_service.dart';


class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _tab = 0;

  static const _primary = Color(0xFF7C3AED);
  static const _bg = Color(0xFF0F0A1E);
  static const _surface = Color(0xFF1A1033);

  final _tabs = const [
    AdminExpertsTab(),
    AdminBookingsTab(),
    AdminPodcastTab(),
    InternDashboardScreen(internId: 'Intern-001', internName: 'Kartik Deshmukh')
  ];

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out',
            style: TextStyle(color: Colors.white)),
        content: const Text('Sign out of the admin panel?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Sign Out',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _StatsBar(),
          Expanded(child: _tabs[_tab]),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('SupportHive Admin',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white70),
          tooltip: 'Sign out',
          onPressed: _logout,
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        boxShadow: [
          BoxShadow(
              color: _primary.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: _primary,
        unselectedItemColor: Colors.white38,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_rounded),
            label: 'Experts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.podcasts_outlined),
            label: 'Podcast',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.interests_outlined),
            label: 'Intern',
          ),
        ],
      ),
    );
  }
}

// ── Stats bar ────────────────────────────────────────────────────────────────

class _StatsBar extends StatefulWidget {
  @override
  State<_StatsBar> createState() => _StatsBarState();
}

class _StatsBarState extends State<_StatsBar> {
  Map<String, int> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await AdminFirestoreService.instance.fetchStats();
      if (mounted) setState(() { _stats = s; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 90,
        child: Center(
            child: CircularProgressIndicator(
                color: Color(0xFF7C3AED), strokeWidth: 2)),
      );
    }

    return Container(
      color: const Color(0xFF1A1033),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Stat(label: 'Experts', value: _stats['totalExperts'] ?? 0,
              icon: Icons.people_rounded, color: const Color(0xFF7C3AED)),
          _Stat(label: 'Available', value: _stats['availableExperts'] ?? 0,
              icon: Icons.check_circle_rounded, color: const Color(0xFF10B981)),
          _Stat(label: 'Bookings', value: _stats['totalBookings'] ?? 0,
              icon: Icons.calendar_today_rounded, color: const Color(0xFF0EA5E9)),
          _Stat(label: 'Paid', value: _stats['paidBookings'] ?? 0,
              icon: Icons.currency_rupee_rounded, color: const Color(0xFFF59E0B)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _Stat(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 5),
        Text('$value',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16)),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }
}