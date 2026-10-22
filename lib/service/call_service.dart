// ─────────────────────────────────────────────────────────────────
// service/call_service.dart
// ─────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../model/call_model.dart';
import '../model/intern_model.dart';
import 'fcm_service.dart';
import 'call_usage_service.dart';

class CallService {
  CallService._();

  static final _db   = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static const _uuid = Uuid();

  static CollectionReference<Map<String, dynamic>> get _calls =>
      _db.collection('calls');
  static CollectionReference<Map<String, dynamic>> get _interns =>
      _db.collection('interns');

  // ── USER: initiate a call ──────────────────────────────────────

  static Future<CallModel?> initiateCall(Intern intern) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Re-check limit (belt-and-suspenders; UI already blocks)
      final hasFree = await CallUsageService.hasFreeCalls();
      if (!hasFree) return null;

      final callId = _uuid.v4();
      final channelName =
          'SupportHive_${intern.internId}_$callId'
              .replaceAll('-', '_')
              .replaceAll(' ', '_');

      final call = CallModel(
        callId         : callId,
        userId         : user.uid,
        userDisplayName: user.displayName ?? user.email ?? 'User',
        internId       : intern.internId,
        internName     : intern.name,
        channelName    : channelName,
        status         : CallStatus.ringing,
        createdAt      : DateTime.now(),
      );

      // 1. Write to Firestore first
      await _calls.doc(callId).set(call.toMap());

      // 2. Send FCM notification to intern (non-blocking)
      FCMService.sendCallNotification(
        internFcmToken: intern.fcmToken,
        callId        : callId,
        channelName   : channelName,
        callerName    : call.userDisplayName,
        internName    : intern.name,
      ).catchError((e) => print('FCM error: $e'));

      // 3. Deduct one call credit
      await CallUsageService.incrementCallCount();

      return call;
    } catch (e) {
      print('initiateCall error: $e');
      return null;
    }
  }

  // ── USER: watch call status ────────────────────────────────────

  static Stream<CallModel?> watchCallStatus(String callId) {
    return _calls.doc(callId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return CallModel.fromMap(snap.id, snap.data()!);
    });
  }

  // ── USER: end / cancel a call ──────────────────────────────────

  static Future<void> endCall(String callId, {bool missed = false}) async {
    await _calls.doc(callId).update({
      'status': missed ? CallStatus.missed : CallStatus.ended,
    });
  }

  // ── INTERN: listen for incoming calls ──────────────────────────

  static Stream<List<CallModel>> listenForIncomingCalls(String internId) {
    return _calls
        .where('internId', isEqualTo: internId)
        .where('status', isEqualTo: CallStatus.ringing)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CallModel.fromMap(d.id, d.data()))
            .toList());
  }

  // ── INTERN: accept ─────────────────────────────────────────────

  static Future<void> acceptCall(String callId) async {
    await _calls.doc(callId).update({'status': CallStatus.accepted});
  }

  // ── INTERN: decline ───────────────────────────────────────────

  static Future<void> declineCall(String callId) async {
    await _calls.doc(callId).update({'status': CallStatus.declined});
  }

  // ── INTERN: toggle availability ────────────────────────────────

  static Future<void> setInternAvailability(
      String internId, bool isAvailable) async {
    await _interns.doc(internId).update({'isAvailable': isAvailable});
  }

  // ── INTERN: update FCM token ───────────────────────────────────

  static Future<void> updateInternFcmToken(
      String internId, String fcmToken) async {
    await _interns.doc(internId).update({'fcmToken': fcmToken});
  }

  // ── Stream all interns ─────────────────────────────────────────

  static Stream<List<Intern>> streamInterns() {
    return _interns.snapshots().map((snap) => snap.docs
        .map((d) => Intern.fromMap(d.id, d.data()))
        .toList());
  }
}