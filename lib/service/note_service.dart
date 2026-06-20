// ─────────────────────────────────────────────
//  service/note_service.dart  –  SupportHive
// ─────────────────────────────────────────────
//
//  Firestore path:  users/{uid}/notes/{noteId}
//
//  pubspec.yaml dependencies:
//    firebase_core: ^3.x.x
//    cloud_firestore: ^5.x.x
//    firebase_auth: ^5.x.x
// ─────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/note.dart';

class NoteService {
  // ── Firestore reference ─────────────────────
  CollectionReference<Map<String, dynamic>> get _col {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notes');
  }

  // ── Real-time stream ────────────────────────
  Stream<List<Note>> notesStream() {
    return _col
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Note.fromMap(doc.id, doc.data()))
            .toList());
  }

  // ── Add ─────────────────────────────────────
  Future<String> add(Note note) async {
    final ref = await _col.add(note.toMap());
    return ref.id;
  }

  // ── Update ───────────────────────────────────
  Future<void> update(String id, Note note) async {
    await _col.doc(id).update(note.toMap());
  }

  // ── Delete ───────────────────────────────────
  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}