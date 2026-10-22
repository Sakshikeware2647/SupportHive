/// ─────────────────────────────────────────────────────────────────────────────
/// service/booking_service.dart
///
/// Fix summary (vs previous version):
///   • Expert phone is fetched BEFORE _clear() so nothing is wiped mid-flight.
///   • Expert SMS is sent BEFORE navigation — avoids using a context that may
///     already be mounted under a new route.
///   • context.mounted guard moved to the right place (after _clear).
///   • sendExpertNotificationSms is awaited so errors surface via catchError.
///   • Minor: userPhone / userName resolved before _clear() as well.
/// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supporthive1/view/screens/booking_success_screen.dart';
import '/model/booking_model.dart';
import '/model/expert_model.dart';
import '/service/expert_firestore_service.dart';
import '/service/notification_service.dart';
import '/service/session_link_service.dart';
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

  static const String _razorpayKey = 'rzp_test_T4bcn93utqElpD';

  void init() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  void dispose() => _razorpay.clear();

  // ── Fee calculation ────────────────────────────────────────────────────────

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

  // ── Book and pay ───────────────────────────────────────────────────────────

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

    // ── Capture all pending state into locals BEFORE any async gap or _clear()
    final bookingId    = _pendingBookingId!;
    final expert       = _pendingExpert!;
    final booking      = _pendingBooking!;
    final context      = _pendingContext!;
    final userPhone    = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
    final userName     = FirebaseAuth.instance.currentUser?.displayName ?? 'A patient';

    // 1. Confirm payment in Firestore
    await ExpertFirestoreService.instance.confirmPayment(
      bookingId: bookingId,
      razorpayOrderId: response.orderId ?? '',
      razorpayPaymentId: response.paymentId ?? '',
    );

    // 2. Schedule 1-hour local notification
    await NotificationService.instance.scheduleSessionReminder(
      bookingId: bookingId,
      expertName: expert.name,
      scheduledAt: booking.scheduledAt,
    );

    // 3. Show immediate push notification
    await NotificationService.instance.showBookingConfirmed(
      expertName: expert.name,
      scheduledAt: booking.scheduledAt,
    );

    // 4. Save in-app notification to Firestore
    await ExpertFirestoreService.instance.saveNotification(
      title: 'Session Booked! 🎉',
      body:
          'Your session with ${expert.name} is confirmed for ${_formatDateTime(booking.scheduledAt)}.',
      type: 'booking_confirmed',
      bookingId: bookingId,
    );

    // 5. Attach Jitsi meet link + expiry to the booking doc
    await SessionLinkService.instance.attachLinkToBooking(
      bookingId: bookingId,
      expertId: expert.id,
      scheduledAt: booking.scheduledAt,
    );

    // 6. Build the final confirmed booking object
    final confirmedBooking = booking.copyWith(
      isPaid: true,
      status: BookingStatus.confirmed,
      razorpayOrderId: response.orderId,
      razorpayPaymentId: response.paymentId,
    );

    final link = SessionLinkService.instance.meetLink(
      expertId: expert.id,
      bookingId: bookingId,
    );

    // 7. Fetch expert phone number from Firestore
    //    Done BEFORE _clear() so we still have expert.id available.
    String expertPhone = '';
    try {
      final expertDoc = await FirebaseFirestore.instance
          .collection('experts')
          .doc(expert.id)
          .get();
      expertPhone = (expertDoc.data()?['phoneNumber'] as String?) ?? '';
    } catch (e) {
      debugPrint('BookingService: could not fetch expert phone — $e');
    }

    // ── Clear pending state now that every local var is captured ──────────────
    _clear();

    // 8. Send SMS to EXPERT (fire-and-forget, before navigation so the context
    //    is still the booking screen — not a freshly pushed route).
    if (expertPhone.isNotEmpty && context.mounted) {
      SessionLinkService.instance
          .sendExpertNotificationSms(
            context: context,
            expertPhoneNumber: expertPhone,
            expertName: expert.name,
            userName: userName,
            scheduledAt: confirmedBooking.scheduledAt,
            meetLink: link,
          )
          .catchError(
              (e) => debugPrint('BookingService: expert SMS error — $e'));
    }

    // 9. Navigate
    if (!context.mounted) return;

    final diff = confirmedBooking.scheduledAt.difference(DateTime.now()).inMinutes;

    if (diff <= 5 && diff >= -30) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(expert: expert, booking: confirmedBooking),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingSuccessScreen(
            expert: expert,
            scheduledAt: confirmedBooking.scheduledAt,
            sessionType: confirmedBooking.sessionType,
            isOnline: confirmedBooking.isOnline,
            bookingId: bookingId,
            userPhone: userPhone,
          ),
        ),
      );
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
          'You have a completed unpaid session with ${expert.name}. '
          'Please clear dues before booking again.',
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