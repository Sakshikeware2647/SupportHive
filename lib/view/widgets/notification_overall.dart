import 'package:flutter/material.dart';
import 'package:supporthive1/service/wellness_service.dart';

/// Real-time notification inbox powered by Firestore.
/// All notifications from every feature (quiz, journal, podcast, AI chat,
/// bookings, streaks) flow into here automatically via WellnessService.
class NotificationOverallScreen extends StatefulWidget {
  const NotificationOverallScreen({super.key});

  @override
  State<NotificationOverallScreen> createState() => _NotificationOverallScreenState();
}

class _NotificationOverallScreenState extends State<NotificationOverallScreen>
    with SingleTickerProviderStateMixin {
  final _svc = WellnessService();
  late final TabController _tabCtrl;

  static const _green = Color(0xFF4A6741);

  static const _tabs = ['All', 'Rewards', 'Reminders', 'Streaks', 'System'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: StreamBuilder<List<AppNotification>>(
              stream: _svc.notificationsStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: _green));
                }
                if (snap.hasError) {
                  return _buildEmpty('Error loading notifications.\nPlease try again.');
                }

                final all = snap.data ?? [];
                final filtered = _filter(all, _tabCtrl.index);

                if (filtered.isEmpty) return _buildEmpty(_emptyMessage(_tabCtrl.index));

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _NotifCard(
                    notif: filtered[i],
                    onTap: () => _svc.markRead(filtered[i].id),
                    onDelete: () => _deleteWithUndo(filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.black87, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Notifications',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 17)),
      actions: [
        TextButton(
          onPressed: () async {
            await _svc.markAllRead();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All marked as read'), duration: Duration(seconds: 2)),
              );
            }
          },
          child: const Text('Mark all read', style: TextStyle(color: _green, fontSize: 12)),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.grey.shade100),
      ),
    );
  }

  // ─── Tab Bar ──────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabCtrl,
        isScrollable: true,
        labelColor: _green,
        unselectedLabelColor: Colors.grey,
        indicatorColor: _green,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  // ─── Filter by tab ────────────────────────────────────────────────────────
  List<AppNotification> _filter(List<AppNotification> all, int tab) {
    switch (tab) {
      case 1: return all.where((n) => n.type == 'reward').toList();
      case 2: return all.where((n) => n.type == 'reminder').toList();
      case 3: return all.where((n) => n.type == 'streak').toList();
      case 4: return all.where((n) => n.type == 'system' || n.type == 'booking').toList();
      default: return all;
    }
  }

  String _emptyMessage(int tab) {
    switch (tab) {
      case 1: return 'No reward notifications yet.\nComplete daily tasks to earn points!';
      case 2: return 'No reminders yet.\nOpen the app daily to receive them.';
      case 3: return 'No streak notifications yet.\nBuild a streak by coming back daily!';
      case 4: return 'No system notifications yet.';
      default: return 'No notifications yet.\nComplete tasks and activities to get started!';
    }
  }

  // ─── Empty State ─────────────────────────────────────────────────────────
  Widget _buildEmpty(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ─── Delete with undo ────────────────────────────────────────────────────
  void _deleteWithUndo(AppNotification notif) {
    _svc.deleteNotification(notif.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notification deleted'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Re-push the same notification
            _svc.pushNotification(
              title: notif.title,
              body: notif.body,
              type: notif.type,
              meta: notif.meta,
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification Card
// ─────────────────────────────────────────────────────────────────────────────
class _NotifCard extends StatelessWidget {
  final AppNotification notif;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotifCard({required this.notif, required this.onTap, required this.onDelete});

  static const _green = Color(0xFF4A6741);

  @override
  Widget build(BuildContext context) {
    final config = _typeConfig(notif.type);

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notif.isRead ? Colors.white : config.bgColor,
            borderRadius: BorderRadius.circular(16),
            border: notif.isRead
                ? null
                : Border.all(color: config.accentColor.withOpacity(0.25), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(notif.isRead ? 0.03 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon badge
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: config.accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(config.emoji, style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.bold,
                              fontSize: 13.5,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (!notif.isRead)
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(color: config.accentColor, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.body,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: config.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            config.label,
                            style: TextStyle(fontSize: 10, color: config.accentColor, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _timeAgo(notif.createdAt),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _NotifConfig _typeConfig(String type) {
    switch (type) {
      case 'reward':
        return _NotifConfig('🏅', 'Reward', const Color(0xFF4A6741), const Color(0xFFEEF7EE));
      case 'reminder':
        return _NotifConfig('🔔', 'Reminder', Colors.blue.shade600, Colors.blue.shade50);
      case 'streak':
        return _NotifConfig('🔥', 'Streak', Colors.deepOrange, Colors.orange.shade50);
      case 'booking':
        return _NotifConfig('📅', 'Booking', Colors.purple.shade600, Colors.purple.shade50);
      case 'system':
      default:
        return _NotifConfig('📢', 'System', Colors.grey.shade600, Colors.grey.shade50);
    }
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return 'Just now';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60)  return 'Just now';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)    return '${diff.inHours}h ago';
    if (diff.inDays < 7)      return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _NotifConfig {
  final String emoji;
  final String label;
  final Color accentColor;
  final Color bgColor;
  const _NotifConfig(this.emoji, this.label, this.accentColor, this.bgColor);
}