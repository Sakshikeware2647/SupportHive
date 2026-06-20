import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // 🔥 added
import 'package:image_picker/image_picker.dart';
import '../model/user_profile_model.dart';

class ProfileService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance; // 🔥 added
  final ImagePicker _picker = ImagePicker();

  String get _uid => _auth.currentUser?.uid ?? '';
  DocumentReference get _userDoc => _db.collection('users').doc(_uid);

  // 🔥 added — reference to this user's photo in Firebase Storage
  Reference get _profilePhotoRef =>
      _storage.ref().child('profile_photos').child('$_uid.jpg');

  // ── CALL THIS RIGHT AFTER SIGN-IN / SIGN-UP ───────────────────────────────
  // Creates the Firestore document if it doesn't exist yet (new user),
  // or silently merges without overwriting existing data (returning user).
  // Returns the up-to-date profile model immediately — no waiting for stream.
  Future<UserProfileModel> createOrFetchProfile() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final docSnap = await _userDoc.get();

    if (!docSnap.exists) {
      // ── NEW USER: create document from Firebase Auth data ─────────────────
      final data = <String, dynamic>{
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'phone': '',
        'photoUrl': user.photoURL ?? '',
        'bio': '',
        'sessions': 0,
        'podcastsListened': 0,
        'wellnessScore': '0%',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _userDoc.set(data);
      return UserProfileModel(
        uid: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
        phone: '',
        photoUrl: user.photoURL ?? '',
      );
    } else {
      // ── EXISTING USER: keep email fresh ───────────────────────────────────
      final existingData = docSnap.data() as Map<String, dynamic>;
      if ((existingData['email'] as String? ?? '') != (user.email ?? '')) {
        await _userDoc.update({
          'email': user.email ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        existingData['email'] = user.email ?? '';
      }
      return UserProfileModel.fromMap(user.uid, existingData);
    }
  }

  // ── Real-time profile stream ──────────────────────────────────────────────
  // Always call createOrFetchProfile() before using this stream so the doc
  // is guaranteed to exist and the stream never emits null.
  Stream<UserProfileModel?> profileStream() {
    if (_uid.isEmpty) return const Stream.empty();
    return _userDoc.snapshots().map((snap) {
      if (!snap.exists) return null;
      return UserProfileModel.fromMap(
          _uid, snap.data() as Map<String, dynamic>);
    });
  }

  // ── Pick image ────────────────────────────────────────────────────────────
  Future<File?> pickImage({bool fromCamera = false}) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked == null) return null;
      return File(picked.path);
    } catch (e) {
      debugPrint('pickImage error: $e');
      return null;
    }
  }

  // ── Upload photo to Firebase Storage ──────────────────────────────────────
  // 🔥 replaced Cloudinary upload with Firebase Storage upload
  Future<String?> uploadProfilePhoto(File imageFile) async {
    try {
      final uploadTask = await _profilePhotoRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      if (uploadTask.state == TaskState.success) {
        final downloadUrl = await _profilePhotoRef.getDownloadURL();

        await _userDoc.update({
          'photoUrl': downloadUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        await _auth.currentUser?.updatePhotoURL(downloadUrl);
        return downloadUrl;
      }

      debugPrint('Firebase Storage upload failed: ${uploadTask.state}');
      return null;
    } catch (e) {
      debugPrint('uploadProfilePhoto error: $e');
      return null;
    }
  }

  // ── Remove profile photo ──────────────────────────────────────────────────
  // 🔥 now also deletes the file from Firebase Storage
  Future<void> removeProfilePhoto() async {
    try {
      try {
        await _profilePhotoRef.delete();
      } catch (e) {
        // File may not exist (e.g. user never uploaded one) — safe to ignore.
        debugPrint('No existing photo to delete in Storage: $e');
      }

      await _userDoc.update({
        'photoUrl': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _auth.currentUser?.updatePhotoURL(null);
    } catch (e) {
      debugPrint('removeProfilePhoto error: $e');
    }
  }

  // ── Update profile fields ─────────────────────────────────────────────────
  Future<void> updateProfile({
    required String name,
    required String phone,
    required String bio,
  }) async {
    await _userDoc.update({
      'name': name.trim(),
      'phone': phone.trim(),
      'bio': bio.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _auth.currentUser?.updateDisplayName(name.trim());
  }

  // ── Send password reset ───────────────────────────────────────────────────
  Future<void> sendPasswordReset() async {
    final email = _auth.currentUser?.email;
    if (email != null && email.isNotEmpty) {
      await _auth.sendPasswordResetEmail(email: email);
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async => await _auth.signOut();

  // ── Delete account ────────────────────────────────────────────────────────
  Future<void> deleteAccount() async {
    await _userDoc.delete();
    await _auth.currentUser?.delete();
  }
}