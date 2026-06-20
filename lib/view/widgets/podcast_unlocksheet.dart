import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../model/podcast.dart';
import '../../service/podcast_service.dart';
import '../../service/razorpay_service.dart';

/// Bottom sheet for unlocking a premium podcast via Razorpay.
///
/// Usage:
/// ```dart
/// final didUnlock = await showModalBottomSheet<bool>(
///   context: context,
///   isScrollControlled: true,
///   backgroundColor: Colors.transparent,
///   builder: (_) => PodcastUnlockSheet(podcast: podcast),
/// );
/// ```
/// Returns `true` on successful payment + Firestore unlock, `false`/`null` on cancel.
class PodcastUnlockSheet extends StatefulWidget {
  final Podcast podcast;
  const PodcastUnlockSheet({super.key, required this.podcast});

  @override
  State<PodcastUnlockSheet> createState() => _PodcastUnlockSheetState();
}

class _PodcastUnlockSheetState extends State<PodcastUnlockSheet> {
  static const Color _brandGreen = Color(0xFF4A6741);
  static const Color _gold = Color(0xFFFFB300);

  bool _isPaying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Init Razorpay and wire callbacks
    RazorpayService.instance.init();
    RazorpayService.instance.onSuccess = _onPaymentSuccess;
    RazorpayService.instance.onError = _onPaymentError;
    RazorpayService.instance.onWallet = _onExternalWallet;
  }

  @override
  void dispose() {
    // Clear callbacks — do NOT call dispose() on the singleton here;
    // it is shared. Clear only callbacks to avoid stale references.
    RazorpayService.instance.onSuccess = null;
    RazorpayService.instance.onError = null;
    RazorpayService.instance.onWallet = null;
    super.dispose();
  }

  // ── Razorpay callbacks ─────────────────────────────────────────────────────

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    final paymentId = response.paymentId ?? 'pay_unknown';
    try {
      await PodcastService.instance
          .unlockPodcast(widget.podcast.id, paymentId);
      if (mounted) {
        Navigator.pop(context, true); // signal success to parent
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPaying = false;
          _error = 'Unlock failed after payment. Contact support. ID: $paymentId';
        });
      }
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    final msg = response.code == Razorpay.PAYMENT_CANCELLED
        ? 'Payment was cancelled.'
        : 'Payment failed (code ${response.code}). Please try again.';
    setState(() {
      _isPaying = false;
      _error = msg;
    });
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    // External wallet selected — treat as pending; show info
    if (!mounted) return;
    setState(() {
      _isPaying = false;
      _error = 'External wallet selected: ${response.walletName}. '
          'Complete payment in the wallet app and return.';
    });
  }

  // ── Payment trigger ────────────────────────────────────────────────────────

  void _startPayment() {
    setState(() {
      _isPaying = true;
      _error = null;
    });

    RazorpayService.instance.startPayment(
      amountInRupees: widget.podcast.price,
      productName: 'SupportHive',
      description: widget.podcast.title,
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final p = widget.podcast;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──────────────────────────────────────────────────────
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // ── Lock icon ────────────────────────────────────────────────────
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: _gold.withOpacity(0.4), width: 2),
            ),
            child: const Icon(Icons.lock_rounded, color: _gold, size: 34),
          ),
          const SizedBox(height: 16),

          // ── Podcast title & author ───────────────────────────────────────
          Text(
            p.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'by ${p.author}',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // ── Benefits card ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "What you'll get:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 10),
                _benefit(Icons.play_circle_rounded,
                    'Full episode — ${p.duration}'),
                _benefit(Icons.download_rounded, 'Offline listening'),
                _benefit(Icons.replay_rounded, 'Unlimited replays'),
                _benefit(Icons.headset_rounded, 'Expert wellness content'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Error message ────────────────────────────────────────────────
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        color: Colors.red.shade600, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                            color: Colors.red.shade700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Pay / Unlock button ──────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isPaying ? null : _startPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandGreen,
                disabledBackgroundColor: _brandGreen.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
              child: _isPaying
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      p.price > 0
                          ? 'Unlock for ₹${p.price.toStringAsFixed(0)}'
                          : 'Unlock Free',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Cancel ───────────────────────────────────────────────────────
          TextButton(
            onPressed: _isPaying
                ? null
                : () => Navigator.pop(context, false),
            child: const Text(
              'Maybe later',
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefit(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: _brandGreen, size: 18),
          const SizedBox(width: 10),
          Text(text,
              style:
                  const TextStyle(fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }
}