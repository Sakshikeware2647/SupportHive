// ─────────────────────────────────────────────────────────────────
// service/intern_auth_service.dart
// Call saveInternFcmTokenOnLogin() right after an intern signs in.
// ─────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class InternAuthService {
  InternAuthService._();

  static Future<void> saveInternFcmTokenOnLogin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Find intern doc by email
    final snap = await FirebaseFirestore.instance
        .collection('interns')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return;
    final internDocId = snap.docs.first.id;

    await FirebaseMessaging.instance.requestPermission();
    final token = await FirebaseMessaging.instance.getToken();

    if (token != null) {
      await FirebaseFirestore.instance
          .collection('interns')
          .doc(internDocId)
          .update({'fcmToken': token});

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        FirebaseFirestore.instance
            .collection('interns')
            .doc(internDocId)
            .update({'fcmToken': newToken});
      });
    }
  }
}