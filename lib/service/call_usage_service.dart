// ─────────────────────────────────────────────────────────────────────────────
// service/call_usage_service.dart
//
// Single source of truth for call quota.
// Exposes every method used across:
//   • call_service.dart          → hasFreeCalls(), incrementCallCount()
//   • intern_call_screen.dart    → hasFreeCalls(), remainingFreeCalls(),
//                                   resetAfterPayment()
//   • interns_screen.dart        → ensureInitialised(), remainingFreeCalls(),
//                                   isLimitExceeded(), consumeCall(),
//                                   creditPaidCalls()
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CallUsageService {
  CallUsageService._();

  static const int _freeCalls = 3;
  static const int _paidCalls = 5;

  // ── Firestore ref ──────────────────────────────────────────────────────────
  static DocumentReference<Map<String, dynamic>> get _doc {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('callUsage')
        .doc('stats');
  }

  // ── Bootstrap ──────────────────────────────────────────────────────────────
  /// Creates the usage document with free quota if it doesn't exist yet.
  /// Call once after login.
  static Future<void> ensureInitialised() async {
    final snap = await _doc.get();
    if (!snap.exists) {
      await _doc.set({
        'totalAllotted': _freeCalls,
        'usedCalls'    : 0,
        'topUpCount'   : 0,
        'createdAt'    : FieldValue.serverTimestamp(),
      });
    }
  }

  // ── Internal stats fetch ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>> _stats() async {
    final snap = await _doc.get();
    if (!snap.exists) {
      await ensureInitialised();
      return {'totalAllotted': _freeCalls, 'usedCalls': 0, 'topUpCount': 0};
    }
    return snap.data()!;
  }

  // ── Read helpers ───────────────────────────────────────────────────────────

  /// Calls the user is still allowed to make (≥ 0).
  static Future<int> remainingFreeCalls() async {
    final s         = await _stats();
    final remaining = (s['totalAllotted'] as int) - (s['usedCalls'] as int);
    return remaining < 0 ? 0 : remaining;
  }

  /// true when the user has at least one call remaining.
  /// Used by call_service.dart and intern_call_screen.dart.
  static Future<bool> hasFreeCalls() async {
    return (await remainingFreeCalls()) > 0;
  }

  /// true when the user has used up ALL allotted calls.
  /// Used by interns_screen.dart.
  static Future<bool> isLimitExceeded() async {
    return !(await hasFreeCalls());
  }

  // ── Consume a call ─────────────────────────────────────────────────────────

  /// Increments usedCalls by 1.
  /// Returns false if no calls remain — caller should abort the call.
  /// Used by interns_screen.dart (as consumeCall).
  static Future<bool> consumeCall() async {
    final s   = await _stats();
    final rem = (s['totalAllotted'] as int) - (s['usedCalls'] as int);
    if (rem <= 0) return false;
    await _doc.update({'usedCalls': FieldValue.increment(1)});
    return true;
  }

  /// Alias used by call_service.dart after a call is successfully initiated.
  static Future<void> incrementCallCount() async {
    await consumeCall();
  }

  // ── Credit paid calls ──────────────────────────────────────────────────────

  /// Adds 5 calls to the user's quota after a successful Razorpay payment.
  /// Used by payment_success_screen.dart (as creditPaidCalls).
  static Future<void> creditPaidCalls() async {
    await _doc.update({
      'totalAllotted': FieldValue.increment(_paidCalls),
      'topUpCount'   : FieldValue.increment(1),
      'lastTopUpAt'  : FieldValue.serverTimestamp(),
    });
  }

  /// Alias used by intern_call_screen.dart after Razorpay success.
  static Future<void> resetAfterPayment() async {
    await creditPaidCalls();
  }

  // ── Refund a call credit ───────────────────────────────────────────────────
  /// Decrements usedCalls by 1 if there are any used calls to refund.
  static Future<void> refundCall() async {
    final s = await _stats();
    final used = s['usedCalls'] as int;
    if (used > 0) {
      await _doc.update({'usedCalls': FieldValue.increment(-1)});
    }
  }

  // ── Stream ─────────────────────────────────────────────────────────────────
  static Stream<Map<String, dynamic>> statsStream() {
    return _doc.snapshots().map((snap) {
      if (!snap.exists) {
        return {'totalAllotted': _freeCalls, 'usedCalls': 0, 'topUpCount': 0};
      }
      return snap.data()!;
    });
  }
}