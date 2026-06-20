import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/expert_model.dart';
import '../model/booking_model.dart';

class ExpertFirestoreService {
  ExpertFirestoreService._();
  static final ExpertFirestoreService instance = ExpertFirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Collection refs ──────────────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _expertsCol =>
      _db.collection('experts');

  CollectionReference<Map<String, dynamic>> _userBookingsCol(String uid) =>
      _db.collection('users').doc(uid).collection('counselling');

  CollectionReference<Map<String, dynamic>> get _allBookingsCol =>
      _db.collection('bookings');

  // ── Auth guard ───────────────────────────────────────────────────────────────
  User get _currentUser {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // EXPERTS
  // ════════════════════════════════════════════════════════════════════════════

  /// Seed hardcoded experts into Firestore (call once on first launch or from admin).
  Future<void> seedExperts() async {
    final snap = await _expertsCol.limit(1).get();
    if (snap.docs.isNotEmpty) return; // already seeded

    final batch = _db.batch();
    for (final expert in Expert.seedExperts) {
      final ref = _expertsCol.doc(expert.id);
      batch.set(ref, expert.toFirestore());
    }
    await batch.commit();
  }

  /// Real-time stream of all experts, optionally filtered by category.
  Stream<List<Expert>> expertsStream({String? category}) {
    Query<Map<String, dynamic>> q = _expertsCol;
    if (category != null && category != 'all') {
      q = q.where('category', isEqualTo: category);
    }
    return q.snapshots().map(
          (snap) => snap.docs.map(Expert.fromDoc).toList(),
        );
  }

  /// One-shot fetch.
  Future<List<Expert>> fetchExperts({String? category}) async {
    Query<Map<String, dynamic>> q = _expertsCol;
    if (category != null && category != 'all') {
      q = q.where('category', isEqualTo: category);
    }
    final snap = await q.get();
    return snap.docs.map(Expert.fromDoc).toList();
  }

  /// Adds a new expert (admin use).
  Future<String> addExpert(Expert expert) async {
    final ref = await _expertsCol.add(expert.toFirestore());
    return ref.id;
  }

  /// Updates an expert entry.
  Future<void> updateExpert(String id, Map<String, dynamic> fields) async {
    await _expertsCol.doc(id).update(fields);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BOOKINGS
  // ════════════════════════════════════════════════════════════════════════════

  /// Checks if the user has any UNPAID completed session with this expert.
  /// If yes, they must pay before booking again.
  Future<bool> hasUnpaidSession(String expertId) async {
    final uid = _currentUser.uid;
    final snap = await _userBookingsCol(uid)
        .where('expertId', isEqualTo: expertId)
        .where('isPaid', isEqualTo: false)
        .where('status', isEqualTo: BookingStatus.completed.name)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Checks if user already has a FREE trial used with this expert.
  Future<bool> hasUsedFreeTrial(String expertId) async {
    final uid = _currentUser.uid;
    final snap = await _userBookingsCol(uid)
        .where('expertId', isEqualTo: expertId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Creates a new booking in both the user's subcollection and global bookings.
  Future<String> createBooking(Booking booking) async {
    final uid = _currentUser.uid;

    // Write to global collection
    final ref = await _allBookingsCol.add(booking.toFirestore());

    // Mirror to user's counselling sub-collection
    await _userBookingsCol(uid).doc(ref.id).set(booking.toFirestore());

    return ref.id;
  }

  /// Confirms payment for a booking.
  Future<void> confirmPayment({
    required String bookingId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
  }) async {
    final uid = _currentUser.uid;
    final fields = {
      'isPaid': true,
      'status': BookingStatus.confirmed.name,
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
    };

    // Update both collections atomically
    final batch = _db.batch();
    batch.update(_allBookingsCol.doc(bookingId), fields);
    batch.update(_userBookingsCol(uid).doc(bookingId), fields);
    await batch.commit();
  }

  /// Cancels a booking.
  Future<void> cancelBooking(String bookingId) async {
    final uid = _currentUser.uid;
    final fields = {'status': BookingStatus.cancelled.name};

    final batch = _db.batch();
    batch.update(_allBookingsCol.doc(bookingId), fields);
    batch.update(_userBookingsCol(uid).doc(bookingId), fields);
    await batch.commit();
  }

  /// Stream of current user's bookings.
  Stream<List<Booking>> myBookingsStream() {
    final uid = _currentUser.uid;
    return _userBookingsCol(uid)
        .orderBy('scheduledAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Booking.fromDoc).toList());
  }

  /// Upcoming bookings within 2 hours (for notification scheduling).
  Future<List<Booking>> fetchUpcomingBookings() async {
    final uid = _currentUser.uid;
    final now = DateTime.now();
    final in2Hours = now.add(const Duration(hours: 2));

    final snap = await _userBookingsCol(uid)
        .where('status', isEqualTo: BookingStatus.confirmed.name)
        .where('scheduledAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(now),
            isLessThanOrEqualTo: Timestamp.fromDate(in2Hours))
        .where('notified1Hour', isEqualTo: false)
        .get();

    return snap.docs.map(Booking.fromDoc).toList();
  }

  /// Mark 1-hour notification sent.
  Future<void> markNotified(String bookingId) async {
    final uid = _currentUser.uid;
    final batch = _db.batch();
    batch.update(
        _allBookingsCol.doc(bookingId), {'notified1Hour': true});
    batch.update(
        _userBookingsCol(uid).doc(bookingId), {'notified1Hour': true});
    await batch.commit();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // IN-APP NOTIFICATIONS
  // ════════════════════════════════════════════════════════════════════════════

  CollectionReference<Map<String, dynamic>> _notificationsCol(String uid) =>
      _db.collection('users').doc(uid).collection('notifications');

  Future<void> saveNotification({
    required String title,
    required String body,
    required String type,
    String? bookingId,
  }) async {
    final uid = _currentUser.uid;
    await _notificationsCol(uid).add({
      'title': title,
      'body': body,
      'type': type,
      'bookingId': bookingId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
