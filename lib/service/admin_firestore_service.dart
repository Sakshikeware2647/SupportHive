/// ─────────────────────────────────────────────────────────────────────────────
/// service/admin_firestore_service.dart
///
/// All Firestore reads/writes that are only ever performed by the admin panel.
/// Completely separate from ExpertFirestoreService so no user-side code is
/// touched.
///
/// Sections:
///   • Expert CRUD
///   • Bookings (read-only)
///   • Podcast CRUD  ← NEW
///   • Stats helper  (now includes podcast counts)
/// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import '/model/admin_expert_model.dart';
import '/model/podcast.dart';

class AdminFirestoreService {
  AdminFirestoreService._();
  static final AdminFirestoreService instance = AdminFirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _experts =>
      _db.collection('experts');
  CollectionReference<Map<String, dynamic>> get _bookings =>
      _db.collection('bookings');
  CollectionReference<Map<String, dynamic>> get _podcasts =>
      _db.collection('podcasts');

  // ── Expert CRUD ──────────────────────────────────────────────────────────────

  /// Stream of ALL experts (with phoneNumber) for the admin list.
  Stream<List<AdminExpert>> expertsStream() => _experts
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(AdminExpert.fromDoc).toList());

  /// Add a new expert. Returns the generated document ID.
  Future<String> addExpert(AdminExpert expert) async {
    final ref = await _experts.add(expert.toFirestore());
    return ref.id;
  }

  /// Update every field of an existing expert document.
  Future<void> updateExpert(AdminExpert expert) =>
      _experts.doc(expert.id).update(expert.toFirestore());

  /// Soft-toggle availability without touching other fields.
  Future<void> setAvailability(String expertId, {required bool available}) =>
      _experts.doc(expertId).update({'isAvailable': available});

  /// Permanently delete an expert document.
  Future<void> deleteExpert(String expertId) =>
      _experts.doc(expertId).delete();

  // ── Bookings (read-only for admin) ───────────────────────────────────────────

  /// Stream of all bookings, newest first.
  Stream<List<Map<String, dynamic>>> bookingsStream() => _bookings
      .orderBy('scheduledAt', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => {'id': d.id, ...d.data()})
          .toList());

  /// Bookings filtered for a specific expert.
  Stream<List<Map<String, dynamic>>> bookingsForExpert(String expertId) =>
      _bookings
          .where('expertId', isEqualTo: expertId)
          .orderBy('scheduledAt', descending: true)
          .snapshots()
          .map((s) => s.docs
              .map((d) => {'id': d.id, ...d.data()})
              .toList());

  /// Approve a pending booking (admin-side confirmation).
  Future<void> approveBooking(String bookingId) =>
      _bookings.doc(bookingId).update({'status': 'confirmed'});

  /// Reject / cancel a booking.
  Future<void> rejectBooking(String bookingId) =>
      _bookings.doc(bookingId).update({'status': 'cancelled'});

  // ── Podcast CRUD ─────────────────────────────────────────────────────────────

  /// Stream of ALL podcasts for the admin list, newest first.
  Stream<List<Podcast>> podcastsStream() => _podcasts
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Podcast.fromDoc(d)).toList());

  /// Add a new podcast. Returns the generated document ID.
  Future<String> addPodcast(Podcast podcast) async {
    final ref = await _podcasts.add(podcast.toFirestore());
    return ref.id;
  }

  /// Overwrite every editable field of an existing podcast document.
  /// Intentionally does NOT touch playCount / likeCount / createdAt
  /// so user-generated counters are never reset by an admin edit.
  Future<void> updatePodcast(Podcast podcast) =>
      _podcasts.doc(podcast.id).update({
        'title': podcast.title,
        'author': podcast.author,
        'category': podcast.category,
        'duration': podcast.duration,
        'audioUrl': podcast.audioUrl,
        'videoUrl': podcast.videoUrl,
        'imageUrl': podcast.imageUrl,
        'description': podcast.description,
        'isNew': podcast.isNew,
        'isPremium': podcast.isPremium,
        'price': podcast.price,
        'tags': podcast.tags,
      });

  /// Soft-toggle premium status without touching other fields.
  Future<void> setPremium(String podcastId, {required bool isPremium}) =>
      _podcasts.doc(podcastId).update({'isPremium': isPremium});

  /// Toggle the "isNew" badge without touching other fields.
  Future<void> setIsNew(String podcastId, {required bool isNew}) =>
      _podcasts.doc(podcastId).update({'isNew': isNew});

  /// Permanently delete a podcast document.
  Future<void> deletePodcast(String podcastId) =>
      _podcasts.doc(podcastId).delete();

  // ── Stats helper ─────────────────────────────────────────────────────────────

  /// Returns a map with quick dashboard counts (experts + bookings + podcasts).
  Future<Map<String, int>> fetchStats() async {
    final results = await Future.wait([
      _experts.count().get(),
      _experts.where('isAvailable', isEqualTo: true).count().get(),
      _bookings.count().get(),
      _bookings.where('status', isEqualTo: 'confirmed').count().get(),
      _bookings.where('isPaid', isEqualTo: true).count().get(),
      _podcasts.count().get(),
      _podcasts.where('isPremium', isEqualTo: true).count().get(),
    ]);
    return {
      'totalExperts': results[0].count ?? 0,
      'availableExperts': results[1].count ?? 0,
      'totalBookings': results[2].count ?? 0,
      'confirmedBookings': results[3].count ?? 0,
      'paidBookings': results[4].count ?? 0,
      'totalPodcasts': results[5].count ?? 0,
      'premiumPodcasts': results[6].count ?? 0,
    };
  }
}