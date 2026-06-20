import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supporthive1/view/notes_screen.dart';
import 'package:supporthive1/view/quiz.dart';
import 'package:supporthive1/view/screens/counselling/ai_chat_screen.dart';
import 'package:supporthive1/view/sign_in_screen.dart';
import 'package:supporthive1/view/widgets/profile_screen.dart';
import 'package:supporthive1/view/widgets/wellness_status_screen.dart';
import 'package:supporthive1/service/profile_service.dart'; // 🔥 added
import 'package:supporthive1/model/user_profile_model.dart'; // 🔥 added

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  // Closes the drawer, then pushes the destination screen.
  void _navigate(BuildContext context, Widget screen) {
    Navigator.pop(context); // close the drawer first
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  // 🔥 NEW — Profile needs a real UserProfileModel, fetched from Firestore,
  // so this is async instead of a plain const navigation.
  Future<void> _navigateToProfile(BuildContext context) async {
    Navigator.pop(context); // close drawer first

    try {
      final UserProfileModel profile =
          await ProfileService().createOrFetchProfile();
      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(initialProfile: profile),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Wellness Member';
    final email = user?.email ?? '';
    final initials = displayName.isNotEmpty
        ? displayName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'U';
    final photoUrl = user?.photoURL;

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8F7F2),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _DrawerHeader(
                displayName: displayName,
                email: email,
                initials: initials,
                photoUrl: photoUrl,
              ),

              const SizedBox(height: 8),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _SectionLabel(label: 'MAIN'),
                    _DrawerItem(
                      icon: Icons.home_rounded,
                      title: 'Home',
                      selected: true,
                      // Home is the screen behind the drawer — just close it.
                      onTap: () => Navigator.pop(context),
                    ),
                    _DrawerItem(
                      icon: Icons.chat_bubble_rounded,
                      title: 'Chat with Hive AI',
                      onTap: () => _navigate(
                        context,
                        const AIChatScreen(),
                      ),
                    ),
                    _DrawerItem(
                      icon: Icons.calendar_today_rounded,
                      title: 'Schedule',
                      // TODO: replace with const ScheduleScreen()
                      onTap: () => _navigate(
                        context,
                        const _ComingSoonScreen(title: 'Schedule'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SectionLabel(label: 'WELLNESS'),
                    _DrawerItem(
                      icon: Icons.self_improvement_rounded,
                      title: 'Mindfulness',
                      onTap: () => _navigate(
                        context,
                        const WellnessStatusScreen(),
                      ),
                    ),
                    _DrawerItem(
                      icon: Icons.quiz_rounded,
                      title: 'Wellness Quiz',
                      onTap: () => _navigate(
                        context,
                        const WellnessQuizScreen(),
                      ),
                    ),
                    _DrawerItem(
                      icon: Icons.menu_book_rounded,
                      title: 'My Journal',
                      onTap: () => _navigate(
                        context,
                        const NotesScreen(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SectionLabel(label: 'ACCOUNT'),
                    _DrawerItem(
                      icon: Icons.person_rounded,
                      title: 'Profile',
                      // 🔥 fixed — was passing HomeScreen() into a
                      // UserProfileModel param; now fetches the real profile.
                      onTap: () => _navigateToProfile(context),
                    ),
                    _DrawerItem(
                      icon: Icons.settings_rounded,
                      title: 'Settings',
                      // TODO: replace with const SettingsScreen()
                      onTap: () => _navigate(
                        context,
                        const _ComingSoonScreen(title: 'Settings'),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Logout — unchanged ───────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: _LogoutButton(context: context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Placeholder destination for items not wired up yet (Schedule, Settings).
// Delete once nothing references it anymore.
// ─────────────────────────────────────────────────────────
class _ComingSoonScreen extends StatelessWidget {
  final String title;
  const _ComingSoonScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF2F6B2F),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.construction_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              '$title — coming soon',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────
class _DrawerHeader extends StatelessWidget {
  final String displayName;
  final String email;
  final String initials;
  final String? photoUrl;

  const _DrawerHeader({
    required this.displayName,
    required this.email,
    required this.initials,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2F6B2F), Color(0xFF4A8C4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(topRight: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.spa, color: Colors.white, size: 14),
                    SizedBox(width: 5),
                    Text(
                      'SUPPORTHIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: photoUrl != null && photoUrl!.isNotEmpty
                  ? Image.network(
                      photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _InitialsAvatar(initials: initials),
                    )
                  : _InitialsAvatar(initials: initials),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              email,
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.verified_rounded, color: Colors.white, size: 13),
                SizedBox(width: 5),
                Text(
                  'Wellness Member',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String initials;
  const _InitialsAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E5E1E),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Section Label
// ─────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Drawer Item
// ─────────────────────────────────────────────────────────
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF2F6B2F).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2F6B2F) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? const Color(0xFF2F6B2F) : Colors.black87,
          ),
        ),
        trailing: selected
            ? Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF2F6B2F),
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Logout Button — unchanged
// ─────────────────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  final BuildContext context;
  const _LogoutButton({required this.context});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Sign Out'),
              content: const Text('Are you sure you want to sign out?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
          if (confirmed == true && context.mounted) {
            await FirebaseAuth.instance.signOut();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const SignInScreen()),
              (route) => false,
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.red.shade600, size: 20),
              const SizedBox(width: 12),
              Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.red.shade300, size: 13),
            ],
          ),
        ),
      ),
    );
  }
}