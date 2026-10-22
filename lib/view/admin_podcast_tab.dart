/// ─────────────────────────────────────────────────────────────────────────────
/// view/screens/admin/admin_podcast_tab.dart
///
/// Admin tab that lists all podcasts with inline controls:
///   • Add new podcast (FAB → AdminPodcastForm)
///   • Edit existing podcast (tap row → AdminPodcastForm in edit mode)
///   • Toggle Premium on/off without opening the form
///   • Toggle isNew badge
///   • Delete with confirmation dialog
/// ─────────────────────────────────────────────────────────────────────────────

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '/model/podcast.dart';
import '/service/admin_firestore_service.dart';
import 'admin_podcast_form.dart';

class AdminPodcastTab extends StatelessWidget {
  const AdminPodcastTab({super.key});

  static const Color _primary = Color(0xFF7C3AED);
  // static const String _adminEmail = 'admin@supporthive.com';

  // bool get _isMainAdmin =>
  //     FirebaseAuth.instance.currentUser?.email?.toLowerCase() == _adminEmail;

  // ── Delete confirmation ──────────────────────────────────────────────────────

  Future<void> _confirmDelete(BuildContext context, Podcast p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Podcast'),
        content: Text(
            'Are you sure you want to permanently delete "${p.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await AdminFirestoreService.instance.deletePodcast(p.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${p.title}" deleted.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  // ── Navigate to form ─────────────────────────────────────────────────────────

  Future<void> _openForm(BuildContext context, {Podcast? podcast}) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminPodcastForm(podcast: podcast),
      ),
    );
    // Stream auto-updates — nothing extra needed.
  }

  // ── Toggle helpers ───────────────────────────────────────────────────────────

  Future<void> _togglePremium(
      BuildContext context, Podcast p) async {
    try {
      await AdminFirestoreService.instance
          .setPremium(p.id, isPremium: !p.isPremium);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _toggleNew(BuildContext context, Podcast p) async {
    try {
      await AdminFirestoreService.instance
          .setIsNew(p.id, isNew: !p.isNew);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Podcast',
            style: TextStyle(fontWeight: FontWeight.w600)),
        onPressed: () => _openForm(context),
      ),
      body: StreamBuilder<List<Podcast>>(
        stream: AdminFirestoreService.instance.podcastsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _primary),
            );
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final podcasts = snap.data ?? [];

          if (podcasts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mic_off_rounded,
                      size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No podcasts yet.',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 15)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _openForm(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add First Podcast'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding:
                const EdgeInsets.fromLTRB(16, 16, 16, 100), // FAB clearance
            itemCount: podcasts.length,
            itemBuilder: (_, i) => _PodcastAdminCard(
              podcast: podcasts[i],
              onEdit: () => _openForm(context, podcast: podcasts[i]),
              onDelete: () => _confirmDelete(context, podcasts[i]),
              onTogglePremium: () =>
                  _togglePremium(context, podcasts[i]),
              onToggleNew: () => _toggleNew(context, podcasts[i]),
            ),
          );
        },
      ),
    );
  }
}

// ── Individual card ───────────────────────────────────────────────────────────

class _PodcastAdminCard extends StatelessWidget {
  final Podcast podcast;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePremium;
  final VoidCallback onToggleNew;

  const _PodcastAdminCard({
    required this.podcast,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePremium,
    required this.onToggleNew,
  });

  static const Color _primary = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    final p = podcast;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 14, 8, 0),
            child: Row(
              children: [
                // Thumbnail / icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: p.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            p.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.mic_rounded,
                                color: Color(0xFF7C3AED),
                                size: 24),
                          ),
                        )
                      : const Icon(Icons.mic_rounded,
                          color: _primary, size: 24),
                ),
                const SizedBox(width: 12),

                // Title + author
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${p.author}  ·  ${p.duration}  ·  ${p.category}',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 11),
                      ),
                    ],
                  ),
                ),

                // Edit / delete menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: Colors.black54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_rounded, size: 18),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_rounded,
                            size: 18, color: Colors.red.shade600),
                        const SizedBox(width: 10),
                        Text('Delete',
                            style:
                                TextStyle(color: Colors.red.shade600)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Stats row ────────────────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _stat(Icons.play_arrow_rounded, '${p.playCount} plays'),
                const SizedBox(width: 16),
                _stat(Icons.favorite_rounded, '${p.likeCount} likes'),
                if (p.isPremium) ...[
                  const SizedBox(width: 16),
                  _stat(Icons.currency_rupee_rounded,
                      p.price.toStringAsFixed(0)),
                ],
              ],
            ),
          ),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // ── Toggle row ───────────────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                // Premium toggle
                Expanded(
                  child: _ToggleChip(
                    label: 'Premium',
                    icon: Icons.lock_rounded,
                    active: p.isPremium,
                    activeColor: Colors.amber.shade700,
                    onTap: onTogglePremium,
                  ),
                ),
                const SizedBox(width: 8),
                // New badge toggle
                Expanded(
                  child: _ToggleChip(
                    label: 'NEW badge',
                    icon: Icons.new_releases_rounded,
                    active: p.isNew,
                    activeColor: Colors.red.shade600,
                    onTap: onToggleNew,
                  ),
                ),
                const SizedBox(width: 8),
                // Edit shortcut
                Expanded(
                  child: _ToggleChip(
                    label: 'Edit',
                    icon: Icons.edit_rounded,
                    active: false,
                    activeColor: _primary,
                    inactiveColor: _primary,
                    onTap: onEdit,
                    alwaysColored: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade400),
        const SizedBox(width: 4),
        Text(label,
            style:
                TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }
}

// ── Small inline toggle chip ─────────────────────────────────────────────────

class _ToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final Color? inactiveColor;
  final VoidCallback onTap;
  final bool alwaysColored;

  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onTap,
    this.inactiveColor,
    this.alwaysColored = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = (active || alwaysColored)
        ? (alwaysColored ? activeColor : activeColor)
        : (inactiveColor ?? Colors.grey.shade400);
    final bg = (active || alwaysColored)
        ? color.withOpacity(0.12)
        : Colors.grey.shade100;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: (active || alwaysColored)
                ? color.withOpacity(0.4)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}