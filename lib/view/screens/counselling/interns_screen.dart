// ─────────────────────────────────────────────────────────────────────────────
// view/screens/intern/interns_screen.dart  (USER SIDE)
//
// Changes vs previous version:
//   • Lock button on _InternCard now opens Razorpay via RazorpayService
//   • After payment success → PaymentSuccessScreen → credits 5 calls
//   • RazorpayService is init/disposed here (single owner)
//   • onCall guard: consumeCall() before navigating to InternCallScreen
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supporthive1/view/screens/payment_success_screen.dart';

import '../../../model/intern_model.dart';
import '../../../service/call_usage_service.dart';
import '../../../service/intern_service.dart';
import '../../../service/razorpay_service.dart';
import 'intern_call_screen.dart';
import 'intern_chat_screen.dart';
import 'intern_theme.dart';


class InternsScreen extends StatefulWidget {
  const InternsScreen({super.key});

  @override
  State<InternsScreen> createState() => _InternsScreenState();
}

class _InternsScreenState extends State<InternsScreen>
    with SingleTickerProviderStateMixin {

  String _selectedFilter = 'All';
  int  _remainingCalls   = 3;
  bool _limitExceeded    = false;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  static const List<String> _filters = [
    'All', 'Anxiety', 'Stress', 'CBT', 'Depression'
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // Initialise Razorpay and wire callbacks
    RazorpayService.instance.init();
    RazorpayService.instance.onSuccess = _onPaymentSuccess;
    RazorpayService.instance.onError   = _onPaymentError;

    _loadCallCount();
  }

  // ── Call count ─────────────────────────────────────────────────────────────
  Future<void> _loadCallCount() async {
    await CallUsageService.ensureInitialised();
    final r        = await CallUsageService.remainingFreeCalls();
    final exceeded = await CallUsageService.isLimitExceeded();
    if (mounted) {
      setState(() {
        _remainingCalls = r;
        _limitExceeded  = exceeded;
      });
    }
  }

  // ── Razorpay: open payment ─────────────────────────────────────────────────
  void _openPayment() {
    RazorpayService.instance.startSessionPayment(
      totalAmountInRupees: 99,
      expertName:          'SupportHive Intern',
      sessionDescription:  'Unlock 5 audio call sessions with interns',
      context:             context,
    );
  }

  // ── Razorpay: success handler ──────────────────────────────────────────────
  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    // Navigate to success screen; it will credit the calls internally.
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const PaymentSuccessScreen(callsUnlocked: 5),
        fullscreenDialog: true,
      ),
    );

    // Refresh counts whether the credit succeeded or not
    if (mounted) _loadCallCount();
  }

  // ── Razorpay: error / cancel handler ──────────────────────────────────────
  void _onPaymentError(PaymentFailureResponse response) {
    if (!mounted) return;

    // code 0 = user cancelled — show a mild message
    final isCancelled = response.code == Razorpay.PAYMENT_CANCELLED;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isCancelled
              ? 'Payment cancelled.'
              : 'Payment failed: ${response.message ?? "Please try again."}',
        ),
        backgroundColor:
            isCancelled ? InternTheme.textMid : InternTheme.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Filters ────────────────────────────────────────────────────────────────
  List<Intern> _applyFilter(List<Intern> all) {
    if (_selectedFilter == 'All') return all;
    return all
        .where((i) => i.specialization
            .toLowerCase()
            .contains(_selectedFilter.toLowerCase()))
        .toList();
  }

  // ── Quick connect ──────────────────────────────────────────────────────────
  void _quickConnect(List<Intern> allInterns) {
    final available = allInterns.where((i) => i.isAvailable).toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No interns available right now.')),
      );
      return;
    }
    Navigator.push(context, _route(InternChatScreen(intern: available.first)));
  }

  PageRoute<void> _route(Widget page) => PageRouteBuilder<void>(
        pageBuilder:        (_, a, __) => page,
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      );

  @override
  void dispose() {
    _fadeCtrl.dispose();
    RazorpayService.instance.onSuccess = null;
    RazorpayService.instance.onError   = null;
    RazorpayService.instance.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InternTheme.surface,
      body: StreamBuilder<List<Intern>>(
        stream: InternService.instance.internsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: InternTheme.primary));
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style:
                        const TextStyle(color: InternTheme.danger)));
          }

          final allInterns = snapshot.data ?? [];
          final filtered   = _applyFilter(allInterns);

          return FadeTransition(
            opacity: _fadeAnim,
            child: CustomScrollView(
              slivers: [
                _buildSliverHeader(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildQuickConnectCard(allInterns),
                        const SizedBox(height: 24),
                        _buildCallBanner(),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Our Interns'),
                        const SizedBox(height: 14),
                        _buildFilterRow(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                _buildInternList(filtered),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Sliver header ──────────────────────────────────────────────────────────
  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: InternTheme.primary,
      leading: const BackButton(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration:
              const BoxDecoration(gradient: InternTheme.headerGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('PEER SUPPORT',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4)),
                  ),
                  const SizedBox(height: 10),
                  const Text('Student Interns',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          height: 1.2)),
                  const SizedBox(height: 6),
                  Text('Trained psychology interns, ready to listen',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13.5)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Quick connect card ─────────────────────────────────────────────────────
  Widget _buildQuickConnectCard(List<Intern> allInterns) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: InternTheme.headerGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: InternTheme.primary.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Need someone right now?',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
              const SizedBox(height: 4),
              Text('Connect with an available intern instantly.',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12.5)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () => _quickConnect(allInterns),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: InternTheme.primary,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: const Text('Quick Chat',
              style:
                  TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        ),
      ]),
    );
  }

  // ── Call banner ────────────────────────────────────────────────────────────
  Widget _buildCallBanner() {
    final isLow = _remainingCalls <= 1;
    return GestureDetector(
      // Tapping the banner when limit exceeded also triggers payment
      onTap: _limitExceeded ? _openPayment : null,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _limitExceeded
              ? const Color(0xFFFFEDED)
              : isLow
                  ? const Color(0xFFFEF3C7)
                  : InternTheme.primary.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _limitExceeded
                ? InternTheme.danger.withOpacity(0.4)
                : isLow
                    ? const Color(0xFFF59E0B).withOpacity(0.4)
                    : InternTheme.primary.withOpacity(0.15),
          ),
        ),
        child: Row(children: [
          Icon(
            _limitExceeded
                ? Icons.lock_outline_rounded
                : isLow
                    ? Icons.warning_amber_rounded
                    : Icons.phone_in_talk_rounded,
            size: 20,
            color: _limitExceeded
                ? InternTheme.danger
                : isLow
                    ? const Color(0xFFD97706)
                    : InternTheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _limitExceeded
                ? RichText(
                    text: const TextSpan(
                      style: TextStyle(
                          fontSize: 13, color: InternTheme.danger),
                      children: [
                        TextSpan(
                            text: 'Call limit reached. ',
                            style:
                                TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(
                            text: 'Tap to pay ₹99 & unlock 5 more calls.',
                            style:
                                TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )
                : RichText(
                    text: TextSpan(
                      style: TextStyle(
                          fontSize: 13,
                          color: isLow
                              ? const Color(0xFF92400E)
                              : InternTheme.textMid),
                      children: [
                        TextSpan(
                            text:
                                '$_remainingCalls free ${_remainingCalls == 1 ? 'call' : 'calls'} remaining. ',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                        TextSpan(
                            text: isLow
                                ? 'Top up ₹99 for 5 more sessions.'
                                : 'Audio calls, no video, always private.'),
                      ],
                    ),
                  ),
          ),
          if (_limitExceeded)
            const Icon(Icons.chevron_right_rounded,
                color: InternTheme.danger, size: 18),
        ]),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            color: InternTheme.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w800));
  }

  // ── Filter row ─────────────────────────────────────────────────────────────
  Widget _buildFilterRow() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f        = _filters[i];
          final selected = _selectedFilter == f;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? InternTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? InternTheme.primary
                      : InternTheme.textLight.withOpacity(0.4),
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                            color: InternTheme.primary.withOpacity(0.25),
                            blurRadius: 8)
                      ]
                    : null,
              ),
              child: Text(f,
                  style: TextStyle(
                      color: selected
                          ? Colors.white
                          : InternTheme.textMid,
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500)),
            ),
          );
        },
      ),
    );
  }

  // ── Intern list ────────────────────────────────────────────────────────────
  Widget _buildInternList(List<Intern> list) {
    if (list.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(children: [
            Icon(Icons.search_off_rounded,
                size: 42, color: InternTheme.textLight),
            const SizedBox(height: 12),
            Text('No interns found for "$_selectedFilter"',
                style: const TextStyle(
                    color: InternTheme.textLight, fontSize: 14)),
          ]),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) {
          final intern = list[i];
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: _InternCard(
              intern:        intern,
              limitExceeded: _limitExceeded,
              onChat: () => Navigator.push(
                  context, _route(InternChatScreen(intern: intern))),
              onCall: () async {
                await Navigator.push(
                    context, _route(InternCallScreen(intern: intern)));
                _loadCallCount(); // refresh after returning
              },
              // Pass the payment opener so the card can trigger it
              onUnlock: _openPayment,
            ),
          );
        },
        childCount: list.length,
      ),
    );
  }
}

// ── Intern card ────────────────────────────────────────────────────────────────

class _InternCard extends StatelessWidget {
  final Intern       intern;
  final VoidCallback onChat;
  final VoidCallback onCall;
  final VoidCallback onUnlock;   // ← called when locked button is tapped
  final bool         limitExceeded;

  const _InternCard({
    required this.intern,
    required this.onChat,
    required this.onCall,
    required this.onUnlock,
    required this.limitExceeded,
  });

  static const List<List<Color>> _palettes = [
    [Color(0xFF0A9E8A), Color(0xFF38EF7D)],
    [Color(0xFF7C3AED), Color(0xFFC4B5FD)],
    [Color(0xFFEA580C), Color(0xFFFBBF24)],
    [Color(0xFF0369A1), Color(0xFF38BDF8)],
  ];

  @override
  Widget build(BuildContext context) {
    final palette = _palettes[intern.name.length % _palettes.length];

    // Call button states:
    //   limitExceeded           → show lock, tapping opens payment
    //   !intern.isAvailable     → greyed out, not tappable
    //   available & not exceeded → normal call
    final bool internOffline = !intern.isAvailable;

    return Container(
      decoration: InternTheme.cardDecoration,
      child: Column(children: [
        // Colour accent strip
        Container(
          height: 5,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: palette),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────────
              Row(children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: palette),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(intern.avatarInitials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(intern.name,
                          style: const TextStyle(
                              color: InternTheme.textDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                      const SizedBox(height: 3),
                      Text(intern.specialization,
                          style: const TextStyle(
                              color: InternTheme.textMid,
                              fontSize: 12.5)),
                      if (intern.phone.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(children: [
                          const Icon(Icons.phone_outlined,
                              size: 12,
                              color: InternTheme.textLight),
                          const SizedBox(width: 4),
                          Text(intern.phone,
                              style: const TextStyle(
                                  color: InternTheme.textLight,
                                  fontSize: 11.5)),
                        ]),
                      ],
                    ],
                  ),
                ),
                // Availability pill
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: intern.isAvailable
                        ? InternTheme.available.withOpacity(0.1)
                        : InternTheme.unavailable.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        color: intern.isAvailable
                            ? InternTheme.available
                            : InternTheme.unavailable,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      intern.isAvailable ? 'Online' : 'Away',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: intern.isAvailable
                              ? InternTheme.available
                              : InternTheme.textLight),
                    ),
                  ]),
                ),
              ]),

              if (intern.bio.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(intern.bio,
                    style: const TextStyle(
                        color: InternTheme.textMid,
                        fontSize: 12.5,
                        height: 1.5)),
              ],

              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.star_rounded,
                    size: 15, color: Color(0xFFF59E0B)),
                const SizedBox(width: 3),
                Text('${intern.rating}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: InternTheme.textDark)),
                const SizedBox(width: 12),
                Text('${intern.sessionCount} sessions',
                    style: const TextStyle(
                        fontSize: 12,
                        color: InternTheme.textLight)),
              ]),

              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFEEF2F2)),
              const SizedBox(height: 14),

              // ── Action buttons ──────────────────────────────────────────────
              Row(children: [
                Expanded(
                  child: _ActionButton(
                    icon:     Icons.chat_bubble_outline_rounded,
                    label:    'Chat',
                    onTap:    onChat,
                    filled:   true,
                    showLock: false,
                    isLocked: false,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: limitExceeded
                      // ── LOCKED: tappable, opens payment ──────────────────
                      ? _ActionButton(
                          icon:     Icons.phone_rounded,
                          label:    'Audio Call',
                          onTap:    onUnlock,   // ← payment trigger
                          filled:   false,
                          showLock: true,
                          isLocked: true,
                        )
                      // ── NORMAL: disabled when intern is offline ───────────
                      : _ActionButton(
                          icon:     Icons.phone_rounded,
                          label:    'Audio Call',
                          onTap:    internOffline ? null : onCall,
                          filled:   false,
                          showLock: false,
                          isLocked: false,
                        ),
                ),
              ]),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Action button ──────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData      icon;
  final String        label;
  final VoidCallback? onTap;
  final bool          filled;
  final bool          showLock;
  final bool          isLocked;   // locked = styled differently but still tappable

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.filled,
    required this.showLock,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    // disabled = not tappable AND not locked (i.e. intern offline, no limit issue)
    final disabled = onTap == null && !isLocked;

    Color bgColor;
    Color fgColor;
    Border? border;
    List<BoxShadow>? shadows;

    if (isLocked) {
      // Lock state: danger-tinted, still tappable
      bgColor = InternTheme.danger.withOpacity(0.08);
      fgColor = InternTheme.danger;
      border  = Border.all(color: InternTheme.danger.withOpacity(0.35), width: 1.5);
    } else if (disabled) {
      bgColor = const Color(0xFFF1F5F5);
      fgColor = InternTheme.textLight;
    } else if (filled) {
      bgColor = InternTheme.primary;
      fgColor = Colors.white;
      shadows = [
        BoxShadow(
            color:  InternTheme.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3))
      ];
    } else {
      bgColor = Colors.white;
      fgColor = InternTheme.primary;
      border  = Border.all(
          color: InternTheme.primary.withOpacity(0.5), width: 1.5);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color:        bgColor,
          borderRadius: BorderRadius.circular(12),
          border:       border,
          boxShadow:    shadows,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              showLock ? Icons.lock_open_rounded : icon,
              size:  16,
              color: fgColor,
            ),
            const SizedBox(width: 6),
            Text(
              showLock ? 'Unlock ₹99' : label,
              style: TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w700,
                  color:      fgColor),
            ),
          ],
        ),
      ),
    );
  }
}