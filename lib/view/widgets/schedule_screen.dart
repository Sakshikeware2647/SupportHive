import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:supporthive1/view/screens/counselling/expert_app_theme.dart';
import '/model/booking_model.dart';
import '/model/expert_model.dart';
import '/service/expert_firestore_service.dart';
import '/view/screens/counselling/call_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _db = FirebaseFirestore.instance;
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  late final Stream<int> _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Stream.periodic(const Duration(seconds: 30), (i) => i);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get _bookingsStream => _db
      .collection('bookings')
      .where('userId', isEqualTo: _uid)
      .orderBy('scheduledAt', descending: false)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 110,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded,
            size: 18, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.calendar_month_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My Schedule',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      Text('Upcoming & past sessions',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
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

  Widget _buildBody() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _bookingsStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(
                child: CircularProgressIndicator(color: AppTheme.primary)),
          );
        }

        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 64, color: AppTheme.primary.withOpacity(0.25)),
                  const SizedBox(height: 16),
                  const Text('No sessions booked yet',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Book a session with an expert to get started.',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          );
        }

        final now = DateTime.now();
        final upcoming = docs
            .where((d) =>
                (d.data()['scheduledAt'] as Timestamp)
                    .toDate()
                    .add(const Duration(minutes: 15))
                    .isAfter(now))
            .toList();
        final past = docs
            .where((d) =>
                !(d.data()['scheduledAt'] as Timestamp)
                    .toDate()
                    .add(const Duration(minutes: 15))
                    .isAfter(now))
            .toList();

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (upcoming.isNotEmpty) ...[
                _sectionHeader('Upcoming Sessions', Icons.upcoming_rounded),
                const SizedBox(height: 12),
                ...upcoming.map((d) => _BookingCard(
                    data: d.data(), docId: d.id, ticker: _ticker)),
                const SizedBox(height: 24),
              ],
              if (past.isNotEmpty) ...[
                _sectionHeader('Past Sessions', Icons.history_rounded),
                const SizedBox(height: 12),
                ...past.map((d) => _BookingCard(
                    data: d.data(), docId: d.id, ticker: _ticker)),
              ],
            ]),
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(title,
            style: AppTheme.titleSm
                .copyWith(fontSize: 14, color: AppTheme.textSecondary)),
      ],
    );
  }
}

// ── Booking Card ─────────────────────────────────────────────────────────────
class _BookingCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;
  final Stream<int> ticker;

  const _BookingCard(
      {required this.data, required this.docId, required this.ticker});

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  Expert? _expert;

  @override
  void initState() {
    super.initState();
    _loadExpert();
  }

  Future<void> _loadExpert() async {
    final expertId = widget.data['expertId'] as String? ?? '';
    if (expertId.isEmpty) return;
    try {
      final expert =
          await ExpertFirestoreService.instance.getExpertById(expertId);
      if (mounted) setState(() => _expert = expert);
    } catch (_) {}
  }

  DateTime get _scheduledAt =>
      (widget.data['scheduledAt'] as Timestamp).toDate();

  bool get _canJoin {
    final now = DateTime.now();
    return now.isAfter(_scheduledAt) &&
        now.isBefore(_scheduledAt.add(const Duration(minutes: 15)));
  }

  bool get _isExpired =>
      DateTime.now().isAfter(_scheduledAt.add(const Duration(minutes: 15)));

  bool get _isFuture => DateTime.now().isBefore(_scheduledAt);

  void _joinCall() {
    if (_expert == null) return;

    final d = widget.data;

    // All required Booking fields read directly from the Firestore document
    final booking = Booking(
      id: widget.docId,
      userId: d['userId'] as String? ?? '',
      expertId: d['expertId'] as String? ?? '',
      expertName: d['expertName'] as String? ?? '',
      expertSpecialization: d['expertSpecialization'] as String? ?? '',
      sessionType: (d['sessionType'] as String?) == 'video'
          ? SessionType.video
          : SessionType.audio,
      scheduledAt: _scheduledAt,
      isOnline: d['isOnline'] as bool? ?? true,
      price: (d['price'] as num?)?.toInt() ?? 0,
      platformFee: (d['platformFee'] as num?)?.toInt() ?? 0,
      gst: (d['gst'] as num?)?.toInt() ?? 0,
      totalAmount: (d['totalAmount'] as num?)?.toInt() ?? 0,
      status: BookingStatus.confirmed,
      razorpayOrderId: d['razorpayOrderId'] as String?,
      razorpayPaymentId: d['razorpayPaymentId'] as String?,
      isPaid: d['isPaid'] as bool? ?? true,
      notified1Hour: d['notified1Hour'] as bool? ?? false,
      createdAt: d['createdAt'] != null
          ? (d['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(expert: _expert!, booking: booking),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionType = widget.data['sessionType'] as String? ?? 'audio';
    final isVideo = sessionType == 'video';
    final expertName = widget.data['expertName'] as String? ?? 'Expert';
    final isOnline = widget.data['isOnline'] as bool? ?? true;
    final total = (widget.data['totalAmount'] as num?)?.toInt() ?? 0;

    return StreamBuilder<int>(
      stream: widget.ticker,
      builder: (context, _) {
        final canJoin = _canJoin;
        final expired = _isExpired;
        final future = _isFuture;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: AppTheme.cardDecoration,
          child: Column(
            children: [
              // ── Header strip ───────────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: canJoin
                      ? AppTheme.headerGradient
                      : const LinearGradient(
                          colors: [Color(0xFFF3F4F6), Color(0xFFF3F4F6)]),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isVideo
                          ? Icons.videocam_rounded
                          : Icons.phone_rounded,
                      color:
                          canJoin ? Colors.white : AppTheme.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isVideo ? 'Video Session' : 'Audio Session',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: canJoin
                              ? Colors.white
                              : AppTheme.textPrimary),
                    ),
                    const Spacer(),
                    _StatusBadge(
                        canJoin: canJoin,
                        expired: expired,
                        future: future),
                  ],
                ),
              ),

              // ── Body ───────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _infoRow(Icons.person_rounded, expertName),
                    const SizedBox(height: 8),
                    _infoRow(Icons.calendar_today_rounded,
                        _formatDateTime(_scheduledAt)),
                    const SizedBox(height: 8),
                    _infoRow(
                      isOnline
                          ? Icons.wifi_rounded
                          : Icons.location_on_rounded,
                      isOnline ? 'Online' : 'In-person',
                    ),
                    if (total > 0) ...[
                      const SizedBox(height: 8),
                      _infoRow(
                          Icons.currency_rupee_rounded, '₹$total paid'),
                    ],
                    if (canJoin) ...[
                      const SizedBox(height: 8),
                      _CountdownRow(scheduledAt: _scheduledAt),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: canJoin ? _joinCall : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            gradient:
                                canJoin ? AppTheme.headerGradient : null,
                            color: canJoin ? null : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: canJoin
                                ? [
                                    BoxShadow(
                                        color: AppTheme.primary
                                            .withOpacity(0.35),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4))
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                expired
                                    ? Icons.lock_clock_rounded
                                    : future
                                        ? Icons.hourglass_top_rounded
                                        : Icons.video_call_rounded,
                                color: canJoin
                                    ? Colors.white
                                    : Colors.grey.shade400,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                expired
                                    ? 'Session Expired'
                                    : future
                                        ? _timeUntil(_scheduledAt)
                                        : 'Join Session Now',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: canJoin
                                        ? Colors.white
                                        : Colors.grey.shade400),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
            child:
                Text(text, style: AppTheme.bodySm.copyWith(fontSize: 13))),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h =
        dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${weekdays[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]}  •  $h:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  String _timeUntil(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    if (diff.inDays > 0) return 'Starts in ${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours > 0) return 'Starts in ${diff.inHours}h ${diff.inMinutes % 60}m';
    if (diff.inMinutes > 0) return 'Starts in ${diff.inMinutes} min';
    return 'Starting soon…';
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final bool canJoin, expired, future;
  const _StatusBadge(
      {required this.canJoin, required this.expired, required this.future});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;

    if (canJoin) {
      color = Colors.white;
      label = '● LIVE';
    } else if (expired) {
      color = AppTheme.unavailable;
      label = 'Expired';
    } else {
      color = AppTheme.accent;
      label = 'Upcoming';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: canJoin
            ? Colors.white.withOpacity(0.2)
            : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: canJoin ? Colors.white : color,
              fontSize: 10,
              fontWeight: FontWeight.w700)),
    );
  }
}

// ── Countdown: time left in the 15-min grace window ──────────────────────────
class _CountdownRow extends StatefulWidget {
  final DateTime scheduledAt;
  const _CountdownRow({required this.scheduledAt});

  @override
  State<_CountdownRow> createState() => _CountdownRowState();
}

class _CountdownRowState extends State<_CountdownRow> {
  late final Stream<int> _tick;

  @override
  void initState() {
    super.initState();
    _tick = Stream.periodic(const Duration(seconds: 1), (i) => i);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _tick,
      builder: (context, _) {
        final end = widget.scheduledAt.add(const Duration(minutes: 15));
        final remaining = end.difference(DateTime.now());
        if (remaining.isNegative) return const SizedBox.shrink();
        final mins = remaining.inMinutes;
        final secs = remaining.inSeconds % 60;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_rounded,
                size: 13, color: AppTheme.warning),
            const SizedBox(width: 4),
            Text(
              'Link expires in ${mins}m ${secs.toString().padLeft(2, '0')}s',
              style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.warning,
                  fontWeight: FontWeight.w600),
            ),
          ],
        );
      },
    );
  }
}