import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'expert_sessions',
    'Expert Sessions',
    channelDescription: 'Reminders for your booked expert sessions',
    importance: Importance.max,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    color: Color(0xFF7C3AED),
    playSound: true,
    enableVibration: true,
  );

  static const NotificationDetails _details =
      NotificationDetails(android: _androidDetails);

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    // v22: initialize() takes a single named param 'settings'
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      ),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    _initialized = true;
  }

  // ── Schedule 1-hour reminder ──────────────────────────────────────────────
  Future<void> scheduleSessionReminder({
    required String bookingId,
    required String expertName,
    required DateTime scheduledAt,
  }) async {
    if (!_initialized) await init();

    final now = DateTime.now();
    final reminderTime = scheduledAt.subtract(const Duration(hours: 1));

    if (reminderTime.isBefore(now)) {
      final fiveMin = scheduledAt.subtract(const Duration(minutes: 5));
      if (fiveMin.isAfter(now)) {
        await _scheduleAt(
          id: bookingId.hashCode.abs() % 100000,
          title: '⏰ Session in 5 Minutes!',
          body: 'Your session with $expertName starts very soon. Get ready!',
          scheduledAt: fiveMin,
        );
      }
      return;
    }

    await _scheduleAt(
      id: bookingId.hashCode.abs() % 100000,
      title: '⏰ Session in 1 Hour',
      body:
          'Your session with $expertName starts at ${_formatTime(scheduledAt)}. Get ready!',
      scheduledAt: reminderTime,
    );
  }

  // ── Internal schedule helper ───────────────────────────────────────────────
  Future<void> _scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    // v22: zonedSchedule() uses all named parameters
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // ── Immediate: booking confirmed ──────────────────────────────────────────
  Future<void> showBookingConfirmed({
    required String expertName,
    required DateTime scheduledAt,
  }) async {
    if (!_initialized) await init();
    // v22: show() uses all named parameters
    await _plugin.show(
      id: _uid(),
      title: 'Session Confirmed ✅',
      body: 'Your session with $expertName on ${_formatDateTime(scheduledAt)} is confirmed!',
      notificationDetails: _details,
    );
  }

  // ── Immediate: payment success ────────────────────────────────────────────
  Future<void> showPaymentSuccess(String expertName) async {
    if (!_initialized) await init();
    await _plugin.show(
      id: _uid(),
      title: 'Payment Successful 💜',
      body: 'Payment for your session with $expertName was successful.',
      notificationDetails: _details,
    );
  }

  // ── Immediate: generic ────────────────────────────────────────────────────
  Future<void> showGeneral({
    required String title,
    required String body,
  }) async {
    if (!_initialized) await init();
    await _plugin.show(
      id: _uid(),
      title: title,
      body: body,
      notificationDetails: _details,
    );
  }

  // ── Cancel ────────────────────────────────────────────────────────────────
  Future<void> cancelReminder(String bookingId) async {
    // v22: cancel() uses named param 'id'
    await _plugin.cancel(id: bookingId.hashCode.abs() % 100000);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  int _uid() => DateTime.now().millisecondsSinceEpoch % 100000;

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]}, ${_formatTime(dt)}';
  }
}