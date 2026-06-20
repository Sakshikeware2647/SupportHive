import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supporthive1/view/screens/booking_success_screen.dart';
import '/model/booking_model.dart';
import '/model/expert_model.dart';
import '/service/expert_firestore_service.dart';
import '/service/notification_service.dart';
import '/view/screens/counselling/call_screen.dart';


class BookingService {
  BookingService._();
  static final BookingService instance = BookingService._();

  late Razorpay _razorpay;
  String? _pendingBookingId;
  Expert? _pendingExpert;
  Booking? _pendingBooking;
  BuildContext? _pendingContext;
  VoidCallback? _onFailure;

  static const String _razorpayKey = 'rzp_test_YOUR_KEY_HERE';

  void init() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  // ── Fee calculation ──────────────────────────────────────────────────────────
  static Map<String, int> calculateFees(int basePrice) {
    const int platformFee = 0;
    final int gst = ((basePrice + platformFee) * 0.18).round();
    final int total = basePrice + platformFee + gst;
    return {
      'price': basePrice,
      'platformFee': platformFee,
      'gst': gst,
      'total': total,
    };
  }

  // ── Book and pay ─────────────────────────────────────────────────────────────
  Future<void> bookAndPay({
    required Expert expert,
    required SessionType sessionType,
    required DateTime scheduledAt,
    required bool isOnline,
    required BuildContext context,
    required VoidCallback onFailure,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Block if unpaid session exists
    final hasUnpaid =
        await ExpertFirestoreService.instance.hasUnpaidSession(expert.id);
    if (hasUnpaid) {
      _showUnpaidDialog(context, expert);
      return;
    }

    final fees = calculateFees(expert.price);

    final booking = Booking(
      id: '',
      userId: user.uid,
      expertId: expert.id,
      expertName: expert.name,
      expertSpecialization: expert.specialization,
      sessionType: sessionType,
      scheduledAt: scheduledAt,
      isOnline: isOnline,
      price: fees['price']!,
      platformFee: fees['platformFee']!,
      gst: fees['gst']!,
      totalAmount: fees['total']!,
      status: BookingStatus.pending,
      isPaid: false,
      createdAt: DateTime.now(),
    );

    final bookingId =
        await ExpertFirestoreService.instance.createBooking(booking);

    // Store everything we need for post-payment navigation
    _pendingBookingId = bookingId;
    _pendingExpert = expert;
    _pendingBooking = Booking(
      id: bookingId,
      userId: booking.userId,
      expertId: booking.expertId,
      expertName: booking.expertName,
      expertSpecialization: booking.expertSpecialization,
      sessionType: booking.sessionType,
      scheduledAt: booking.scheduledAt,
      isOnline: booking.isOnline,
      price: booking.price,
      platformFee: booking.platformFee,
      gst: booking.gst,
      totalAmount: booking.totalAmount,
      status: booking.status,
      isPaid: false,
      createdAt: booking.createdAt,
    );
    _pendingContext = context;
    _onFailure = onFailure;

    _openRazorpay(
      amount: fees['total']! * 100,
      name: expert.name,
      description:
          '${sessionType.name.toUpperCase()} session – ${_formatDateTime(scheduledAt)}',
      email: user.email ?? '',
      phone: user.phoneNumber ?? '',
    );
  }

  void _openRazorpay({
    required int amount,
    required String name,
    required String description,
    required String email,
    required String phone,
  }) {
    final options = {
      'key': _razorpayKey,
      'amount': amount,
      'name': 'SupportHive',
      'description': description,
      'prefill': {
        'contact': phone.isNotEmpty ? phone : '9999999999',
        'email': email.isNotEmpty ? email : 'user@supporthive.com',
      },
      'theme': {'color': '#7C3AED'},
    };
    _razorpay.open(options);
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    if (_pendingBookingId == null ||
        _pendingExpert == null ||
        _pendingBooking == null ||
        _pendingContext == null) return;

    // 1. Confirm payment in Firestore
    await ExpertFirestoreService.instance.confirmPayment(
      bookingId: _pendingBookingId!,
      razorpayOrderId: response.orderId ?? '',
      razorpayPaymentId: response.paymentId ?? '',
    );

    // 2. Schedule 1-hour local notification
    await NotificationService.instance.scheduleSessionReminder(
      bookingId: _pendingBookingId!,
      expertName: _pendingExpert!.name,
      scheduledAt: _pendingBooking!.scheduledAt,
    );

    // 3. Show immediate push notification
    await NotificationService.instance.showBookingConfirmed(
      expertName: _pendingExpert!.name,
      scheduledAt: _pendingBooking!.scheduledAt,
    );

    // 4. Save in-app notification to Firestore
    await ExpertFirestoreService.instance.saveNotification(
      title: 'Session Booked! 🎉',
      body:
          'Your session with ${_pendingExpert!.name} is confirmed for ${_formatDateTime(_pendingBooking!.scheduledAt)}.',
      type: 'booking_confirmed',
      bookingId: _pendingBookingId,
    );

    final confirmedBooking = _pendingBooking!.copyWith(
      isPaid: true,
      status: BookingStatus.confirmed,
      razorpayOrderId: response.orderId,
      razorpayPaymentId: response.paymentId,
    );

    final expert = _pendingExpert!;
    final context = _pendingContext!;

    // Clear state before navigation
    _clear();

    // 5. Check if session is NOW (within 5 min) → go to call directly
    final now = DateTime.now();
    final diff = confirmedBooking.scheduledAt.difference(now).inMinutes;

    if (context.mounted) {
      if (diff <= 5 && diff >= -30) {
        // Session is happening now → launch Jitsi
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CallScreen(
              expert: expert,
              booking: confirmedBooking,
            ),
          ),
        );
      } else {
        // Future session → show success screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BookingSuccessScreen(
              expert: expert,
              scheduledAt: confirmedBooking.scheduledAt,
              sessionType: confirmedBooking.sessionType,
              isOnline: confirmedBooking.isOnline,
            ),
          ),
        );
      }
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    _onFailure?.call();
    _clear();
  }

  void _onExternalWallet(ExternalWalletResponse response) {}

  void _clear() {
    _pendingBookingId = null;
    _pendingExpert = null;
    _pendingBooking = null;
    _pendingContext = null;
    _onFailure = null;
  }

  void _showUnpaidDialog(BuildContext context, Expert expert) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Payment Required'),
        content: Text(
          'You have a completed unpaid session with ${expert.name}. Please clear dues before booking again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]}, $h:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }
}
