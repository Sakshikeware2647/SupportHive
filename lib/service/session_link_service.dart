
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SessionLinkService {
  SessionLinkService._();
  static SessionLinkService instance = SessionLinkService._();

  //Build room / link 

  String roomName({required String expertId, required String bookingId}) =>
      'SupportHive_${expertId}_$bookingId'.replaceAll(' ', '_');

  String meetLink({required String expertId, required String bookingId}) =>
      'https://meet.jit.si/${roomName(expertId: expertId, bookingId: bookingId)}';

  //Validity window 

  static const Duration gracePeriod = Duration(minutes: 15);

  bool isLinkActive(DateTime scheduledAt) {
    final now = DateTime.now();
    return now.isAfter(scheduledAt) &&
        now.isBefore(scheduledAt.add(gracePeriod));
  }

  bool isLinkExpired(DateTime scheduledAt) =>
      DateTime.now().isAfter(scheduledAt.add(gracePeriod));

  bool isLinkFuture(DateTime scheduledAt) =>
      DateTime.now().isBefore(scheduledAt);

  //Persist link into the booking doc 

  Future<void> attachLinkToBooking({
    required String bookingId,
    required String expertId,
    required DateTime scheduledAt,
  }) async {
    final link = meetLink(expertId: expertId, bookingId: bookingId);
    final expiresAt = scheduledAt.add(gracePeriod);

    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .update({
      'meetLink': link,
      'linkExpiresAt': Timestamp.fromDate(expiresAt),
    });
  }

  //SMS to USER 

  Future<void> sendBookingConfirmationSms({
    required BuildContext context,
    required String phoneNumber,
    required String expertName,
    required DateTime scheduledAt,
    required String meetLink,
  }) async {
    final formattedTime = _formatDateTime(scheduledAt);
    final expiresAt = scheduledAt.add(gracePeriod);
    final formattedExpiry = _formatDateTime(expiresAt);

    final message = 'SupportHive ✅ Booking Confirmed!\n\n'
        'Expert: $expertName\n'
        'Time: $formattedTime\n\n'
        '🔗 Join your session:\n$meetLink\n\n'
        '⏰ Link valid until $formattedExpiry (15 min grace period).\n\n'
        'Open the link at session time — it will launch Jitsi Meet automatically.';

    await _launchSms(
      phoneNumber: phoneNumber,
      message: message,
      context: context,
      fallbackLink: meetLink,
    );
  }

  //SMS to EXPERT

  /// Called by [BookingService._onPaymentSuccess] right after payment is
  /// confirmed.  [expertPhoneNumber] is stored in the 'experts' Firestore
  /// collection under the field 'phoneNumber' (set by admin).
  ///
  /// Returns immediately if [expertPhoneNumber] is blank — no crash, no noise.
  Future<void> sendExpertNotificationSms({
    required BuildContext context,
    required String expertPhoneNumber,
    required String expertName,
    required String userName,
    required DateTime scheduledAt,
    required String meetLink,
  }) async {
    if (expertPhoneNumber.trim().isEmpty) return;

    final formattedTime = _formatDateTime(scheduledAt);
    final expiresAt = scheduledAt.add(gracePeriod);
    final formattedExpiry = _formatDateTime(expiresAt);

    final message = 'SupportHive 🔔 New Session Booked!\n\n'
        'Hi $expertName,\n'
        'A patient ($userName) has booked a session with you.\n\n'
        'Time: $formattedTime\n\n'
        '🔗 Join the session:\n$meetLink\n\n'
        '⏰ Link active from session time until $formattedExpiry.\n\n'
        'Please be available at the scheduled time.';

    await _launchSms(
      phoneNumber: expertPhoneNumber,
      message: message,
      context: context,
      fallbackLink: meetLink,
    );
  }

  //Shared SMS launcher 

  Future<void> _launchSms({
    required String phoneNumber,
    required String message,
    required BuildContext context,
    required String fallbackLink,
  }) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s'), '');
    final uri = Uri(
      scheme: 'sms',
      path: cleanPhone,
      queryParameters: {'body': message},
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SMS unavailable. Session link:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  fallbackLink,
                  style: const TextStyle(
                      color: Colors.lightBlueAccent, fontSize: 12),
                ),
              ],
            ),
            duration: const Duration(seconds: 10),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  //Deep-link launcher

  Future<void> launchMeetLink(String link, {BuildContext? context}) async {
    final uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: SelectableText('Could not open: $link'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  //Helpers 

  String _formatDateTime(DateTime dt) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${weekdays[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]}, '
        '$h:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }
}