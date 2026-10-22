/// ─────────────────────────────────────────────────────────────────────────────
/// view/screens/admin/admin_experts_tab.dart
///
/// Admin tab that lists all experts from Firestore and provides:
///   • Add new expert (FAB)
///   • Toggle availability inline
///   • Edit expert (full form bottom-sheet)
///   • Delete expert (with confirmation)
/// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '/model/admin_expert_model.dart';
import '/service/admin_firestore_service.dart';
import 'admin_expert_form.dart';

class AdminExpertsTab extends StatelessWidget {
  const AdminExpertsTab({super.key});

  static const _primary = Color(0xFF7C3AED);
  static const _bg = Color(0xFF0F0A1E);
  static const _surface = Color(0xFF1A1033);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Add Expert',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        onPressed: () => _openForm(context, null),
      ),
      body: StreamBuilder<List<AdminExpert>>(
        stream: AdminFirestoreService.instance.expertsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _primary));
          }

          final experts = snap.data ?? [];

          if (experts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline_rounded,
                      size: 64, color: Colors.white.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  const Text('No experts yet. Tap + to add one.',
                      style: TextStyle(color: Colors.white54)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: experts.length,
            itemBuilder: (_, i) =>
                _ExpertTile(expert: experts[i], onEdit: () => _openForm(context, experts[i])),
          );
        },
      ),
    );
  }

  void _openForm(BuildContext context, AdminExpert? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdminExpertForm(existing: existing),
    );
  }
}

// ── Expert tile ──────────────────────────────────────────────────────────────

class _ExpertTile extends StatelessWidget {
  final AdminExpert expert;
  final VoidCallback onEdit;

  const _ExpertTile({required this.expert, required this.onEdit});

  static const _surface = Color(0xFF1A1033);
  static const _primary = Color(0xFF7C3AED);

  Color get _avatarColor {
    if (expert.avatarColor != null) {
      try {
        return Color(
            int.parse(expert.avatarColor!.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }
    return _primary;
  }

  Future<void> _toggleAvailability() async {
    await AdminFirestoreService.instance.setAvailability(
      expert.id,
      available: !expert.isAvailable,
    );
  }

  Future<void> _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Expert',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove ${expert.name} permanently? This cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
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
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AdminFirestoreService.instance.deleteExpert(expert.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────────
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 26,
                backgroundColor: _avatarColor,
                child: Text(expert.avatarInitials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expert.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(expert.specialization,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 4),
                    // Availability badge
                    _badge(expert.isAvailable),
                  ],
                ),
              ),
              // Actions
              Column(
                children: [
                  // Toggle availability
                  Switch.adaptive(
                    value: expert.isAvailable,
                    onChanged: (_) => _toggleAvailability(),
                    activeColor: const Color(0xFF10B981),
                    inactiveThumbColor: Colors.grey,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _iconBtn(Icons.edit_rounded, _primary, onEdit),
                      const SizedBox(width: 4),
                      _iconBtn(Icons.delete_rounded, Colors.redAccent,
                          () => _delete(context)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.white12),
          const SizedBox(height: 6),
          // ── Info grid ───────────────────────────────────────────────────
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _infoChip(Icons.currency_rupee_rounded,
                  '₹${expert.price}/session'),
              _infoChip(Icons.work_rounded,
                  '${expert.experienceYears} yrs exp'),
              _infoChip(Icons.phone_rounded,
                  expert.phoneNumber.isNotEmpty
                      ? expert.phoneNumber
                      : 'No phone'),
              _infoChip(Icons.label_rounded,
                  expert.category[0].toUpperCase() +
                      expert.category.substring(1)),
            ],
          ),
          if (expert.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: expert.tags
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _avatarColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(t,
                            style: TextStyle(
                                fontSize: 11,
                                color: _avatarColor,
                                fontWeight: FontWeight.w500)),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _badge(bool available) {
    final color =
        available ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(available ? 'Available' : 'Unavailable',
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white38),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}