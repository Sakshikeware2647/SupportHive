import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Razorpay payment service — singleton with proper lifecycle management.
/// Use [init] once (e.g. in main widget's initState) and [dispose] in dispose().
/// Wire [onSuccess], [onError], [onWallet] callbacks before calling [startPayment].
class RazorpayService {
  RazorpayService._();
  static final RazorpayService instance = RazorpayService._();

  // ── Use your real Razorpay TEST key here (starts with rzp_test_) ──────────
  // In production swap to your rzp_live_ key from Razorpay Dashboard.
  static const String _testKey = 'rzp_test_T3QaCznB2XrrBM';

  late Razorpay _razorpay;
  bool _initialized = false;

  // Callbacks — set these before calling startPayment
  void Function(PaymentSuccessResponse)? onSuccess;
  void Function(PaymentFailureResponse)? onError;
  void Function(ExternalWalletResponse)? onWallet;

  /// Call once in the parent widget's initState.
  void init() {
    if (_initialized) return;
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleWallet);
    _initialized = true;
  }

  /// Call in the parent widget's dispose().
  void dispose() {
    if (!_initialized) return;
    _razorpay.clear();
    _initialized = false;
  }

  /// Opens the Razorpay checkout sheet.
  ///
  /// [amountInRupees] — e.g. 99 → ₹99 (converted to paise internally).
  /// [productName]    — shown on checkout sheet.
  /// [description]    — e.g. podcast title.
  /// [contactNumber]  — optional pre-fill.
  /// [email]          — optional pre-fill.
  void startPayment({
    required double amountInRupees,
    required String productName,
    String description = '',
    String contactNumber = '',
    String email = '',
  }) {
    assert(_initialized,
        'Call RazorpayService.instance.init() before startPayment()');

    final options = <String, dynamic>{
      'key': _testKey,
      'amount': (amountInRupees * 100).toInt(), // paise
      'name': productName,
      'description': description.isEmpty ? productName : description,
      'currency': 'INR',
      'prefill': {
        'contact': contactNumber.isEmpty ? '9999999999' : contactNumber,
        'email': email.isEmpty ? 'test@supporthive.com' : email,
      },
      // Dummy theme colour matching app brand
      'theme': {'color': '#4A6741'},
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

  // ── Internal handlers ──────────────────────────────────────────────────────

  void _handleSuccess(PaymentSuccessResponse response) =>
      onSuccess?.call(response);

  void _handleError(PaymentFailureResponse response) =>
      onError?.call(response);

  void _handleWallet(ExternalWalletResponse response) =>
      onWallet?.call(response);
}