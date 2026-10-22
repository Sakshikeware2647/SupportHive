// ─────────────────────────────────────────────────────────────────────────────
// view/screens/intern/payment_success_screen.dart
//
// Shown after a successful Razorpay payment for intern call top-up.
// Credits 5 calls via CallUsageService then lets user return to InternScreen.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:supporthive1/view/screens/counselling/intern_theme.dart';

import '../../../service/call_usage_service.dart';


class PaymentSuccessScreen extends StatefulWidget {
  /// How many calls were just unlocked (always 5 in current flow).
  final int callsUnlocked;

  const PaymentSuccessScreen({
    super.key,
    this.callsUnlocked = 5,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scaleAnim;
  late Animation<double>   _fadeAnim;

  bool _crediting = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    _creditAndAnimate();
  }

  Future<void> _creditAndAnimate() async {
    try {
      await CallUsageService.creditPaidCalls();
    } catch (e) {
      if (mounted) setState(() => _errorMsg = e.toString());
    } finally {
      if (mounted) setState(() => _crediting = false);
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Prevent back-swipe so user must tap the button
      canPop: false,
      child: Scaffold(
        backgroundColor: InternTheme.surface,
        body: SafeArea(
          child: _crediting
              ? const Center(
                  child: CircularProgressIndicator(color: InternTheme.primary),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ── Animated tick circle ──────────────────────────
                        ScaleTransition(
                          scale: _scaleAnim,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              gradient: InternTheme.headerGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: InternTheme.primary.withOpacity(0.35),
                                  blurRadius: 28,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 58,
                            ),
                          ),
                        ),

                        const SizedBox(height: 36),

                        // ── Headline ──────────────────────────────────────
                        const Text(
                          'Payment Successful!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: InternTheme.textDark,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ── Sub-text ──────────────────────────────────────
                        Text(
                          _errorMsg != null
                              ? 'Payment received but we had trouble '
                                'crediting your calls.\nPlease contact support.'
                              : 'You\'ve unlocked ${widget.callsUnlocked} more '
                                'audio call sessions with our interns.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _errorMsg != null
                                ? InternTheme.danger
                                : InternTheme.textMid,
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── Calls unlocked pill ───────────────────────────
                        if (_errorMsg == null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                            decoration: BoxDecoration(
                              color: InternTheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: InternTheme.primary.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.phone_in_talk_rounded,
                                    color: InternTheme.primary, size: 22),
                                const SizedBox(width: 10),
                                Text(
                                  '+${widget.callsUnlocked} calls added to your account',
                                  style: TextStyle(
                                    color: InternTheme.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // ── Amount row ────────────────────────────────────
                        _InfoRow(
                          label: 'Amount paid',
                          value: '₹99',
                        ),
                        const SizedBox(height: 6),
                        _InfoRow(
                          label: 'Sessions unlocked',
                          value: '${widget.callsUnlocked} audio calls',
                        ),

                        const SizedBox(height: 48),

                        // ── CTA button ────────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: InternTheme.headerGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: InternTheme.primary.withOpacity(0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(true), // true = success
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text(
                                'Start Calling',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Small helper widget ────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$label: ',
            style: const TextStyle(
                color: InternTheme.textLight,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        Text(value,
            style: const TextStyle(
                color: InternTheme.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}