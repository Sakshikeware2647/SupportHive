// ─────────────────────────────────────────────────────────────────
// service/intern_service.dart
// ─────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/intern_model.dart';

class InternService {
  InternService._();
  static final InternService instance = InternService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('interns');

  // ── Real-time stream (used by user-side InternsScreen) ─────────
  Stream<List<Intern>> internsStream() {
    return _col.orderBy('name').snapshots().map(
          (snap) => snap.docs
              .map((doc) => Intern.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // ── Admin CRUD ─────────────────────────────────────────────────

  /// Adds a new intern. Returns the generated Firestore document ID.
  Future<String> addIntern(Intern intern) async {
    final ref = await _col.add(intern.toMap());
    return ref.id;
  }

  /// Updates every field of an existing intern document.
  Future<void> updateIntern(Intern intern) async {
    await _col.doc(intern.internId).update(intern.toMap());
  }

  /// Toggle availability only.
  Future<void> setAvailability(String internId, {required bool available}) =>
      _col.doc(internId).update({'isAvailable': available});

  /// Hard-delete an intern document.
  Future<void> deleteIntern(String internId) => _col.doc(internId).delete();

  // ── FCM token ──────────────────────────────────────────────────

  Future<void> saveInternFcmToken(String internId, String token) async {
    await _col.doc(internId).update({'fcmToken': token});
  }
}