import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Single Razorpay singleton used across the entire app.
/// Replace _key with your actual key from Razorpay Dashboard.
class RazorpayService {
  RazorpayService._();
  static final RazorpayService instance = RazorpayService._();

  // ── REPLACE THIS with your key from dashboard.razorpay.com ────────────────
  // Settings → API Keys → Generate Test Key
  // Format: rzp_test_XXXXXXXXXXXXXXXX  (must be 20+ chars after rzp_test_)
  static const String _key = 'rzp_test_T4bcn93utqElpD';

  late Razorpay _razorpay;
  bool _initialized = false;

  // ── Callbacks ─────────────────────────────────────────────────────────────
  void Function(PaymentSuccessResponse)? onSuccess;
  void Function(PaymentFailureResponse)? onError;
  void Function(ExternalWalletResponse)? onWallet;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  void init() {
    if (_initialized) return;
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleWallet);
    _initialized = true;
  }

  void dispose() {
    if (!_initialized) return;
    _razorpay.clear();
    _initialized = false;
  }

  // ── Open payment for general use (podcasts, etc.) ─────────────────────────
  void startPayment({
    required double amountInRupees,
    required String productName,
    String description = '',
    String contactNumber = '',
    String email = '',
  }) {
    _assertInitialized();
    _open(
      amountInPaise: (amountInRupees * 100).toInt(),
      name: productName,
      description: description.isEmpty ? productName : description,
      contact: contactNumber,
      email: email,
    );
  }

  // ── Open payment for expert session booking ───────────────────────────────
  void startSessionPayment({
    required int totalAmountInRupees,
    required String expertName,
    required String sessionDescription,
    BuildContext? context,
  }) {
    _assertInitialized();

    final user = FirebaseAuth.instance.currentUser;

    _open(
      amountInPaise: totalAmountInRupees * 100,
      name: 'SupportHive',
      description: sessionDescription,
      contact: user?.phoneNumber ?? '9999999999',
      email: user?.email ?? 'user@supporthive.com',
    );
  }

  // ── Internal open ─────────────────────────────────────────────────────────
  void _open({
    required int amountInPaise,
    required String name,
    required String description,
    String contact = '',
    String email = '',
  }) {
    // Validate key before opening
    if (_key.contains('REPLACE_WITH') || _key.length < 20) {
      onError?.call(PaymentFailureResponse(
        Razorpay.PAYMENT_CANCELLED,
        'Invalid Razorpay key. Please set your key in razorpay_service.dart',
        null,
      ));
      return;
    }

    final options = <String, dynamic>{
      'key': _key,
      'amount': amountInPaise,
      'name': name,
      'description': description,
      'currency': 'INR',
      'prefill': {
        'contact': contact.isEmpty ? '9999999999' : contact,
        'email': email.isEmpty ? 'user@supporthive.com' : email,
      },
      'theme': {'color': '#7C3AED'},
      'modal': {
        'confirm_close': true,   // ask user before closing
        'animation': true,
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      onError?.call(PaymentFailureResponse(
        Razorpay.PAYMENT_CANCELLED,
        'Could not open payment gateway: $e',
        null,
      ));
    }
  }

  void _assertInitialized() {
    assert(_initialized,
        'Call RazorpayService.instance.init() before making payments');
  }

  // ── Handlers ──────────────────────────────────────────────────────────────
  void _handleSuccess(PaymentSuccessResponse r) => onSuccess?.call(r);
  void _handleError(PaymentFailureResponse r)   => onError?.call(r);
  void _handleWallet(ExternalWalletResponse r)  => onWallet?.call(r);
}