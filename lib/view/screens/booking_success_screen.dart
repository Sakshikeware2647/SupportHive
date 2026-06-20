import 'package:flutter/material.dart';
import 'package:supporthive1/view/screens/counselling/expert_app_theme.dart';
import '/model/expert_model.dart';
import '/model/booking_model.dart';
import '/view/screens/counselling/experts_screen.dart';
import '/view/screens/counselling/call_screen.dart';
import '/service/expert_firestore_service.dart';


class BookingSuccessScreen extends StatefulWidget {
  final Expert expert;
  final DateTime scheduledAt;
  final SessionType sessionType;
  final bool isOnline;

  const BookingSuccessScreen({
    super.key,
    required this.expert,
    required this.scheduledAt,
    required this.sessionType,
    required this.isOnline,
  });

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${weekdays[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} at $h:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  // ── Navigate back to ExpertsScreen WITHOUT popping to root ──────────────────
  void _goBackToExperts() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ExpertsScreen()),
      // Keep everything below ExpertsScreen intact (home/dashboard stays)
      (route) => route.settings.name == '/home' || route.isFirst == false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Prevent back button from going to booking/payment screen
      canPop: false,
      onPopInvoked: (_) => _goBackToExperts(),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 60),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text('Booking Confirmed!',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                      'Your session has been successfully booked.\nA reminder will be sent 1 hour before your session.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          _detailRow(Icons.person_rounded, widget.expert.name),
                          const SizedBox(height: 12),
                          _detailRow(
                            widget.sessionType == SessionType.video
                                ? Icons.videocam_rounded
                                : Icons.phone_rounded,
                            '${widget.sessionType.name[0].toUpperCase()}${widget.sessionType.name.substring(1)} Call',
                          ),
                          const SizedBox(height: 12),
                          _detailRow(Icons.calendar_today_rounded,
                              _formatDateTime(widget.scheduledAt)),
                          const SizedBox(height: 12),
                          _detailRow(
                            widget.isOnline
                                ? Icons.wifi_rounded
                                : Icons.location_on_rounded,
                            widget.isOnline ? 'Online' : 'In-person',
                          ),
                          const SizedBox(height: 12),
                          _detailRow(Icons.notifications_active_rounded,
                              'Reminder set 1 hour before'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Back to Experts (safe navigation) ──────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _goBackToExperts,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Back to Experts',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14)),
        ),
      ],
    );
  }
}
