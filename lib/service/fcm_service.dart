// ─────────────────────────────────────────────────────────────────
// service/fcm_service.dart
//
// Sends a FCM data message to the intern's device.
// Uses the v1 HTTP API via your Cloud Function / server.
//
// For a PURE client-side Flutter implementation we use
// firebase_functions or a Cloud Function endpoint.
// Here we use the legacy HTTP API backed by a Firestore trigger
// approach: we write to a 'fcm_queue' collection and a Cloud
// Function (index.js) picks it up and sends the push.
//
// If you have your own FCM server key you can swap _sendViaServer()
// with a direct HTTP call to fcm.googleapis.com.
// ─────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

class FCMService {
  FCMService._();

  /// Writes a notification request to Firestore.
  /// A Cloud Function (or your backend) watches this collection and
  /// forwards the push to the intern's device using the Admin SDK.
  ///
  /// Firestore document structure:
  ///   /fcm_queue/{autoId}
  ///     token      : String   — intern's FCM token
  ///     callId     : String
  ///     channelName: String
  ///     callerName : String
  ///     internName : String
  ///     sentAt     : Timestamp
  ///     processed  : bool     — Cloud Function sets this to true after sending
  static Future<void> sendCallNotification({
    required String internFcmToken,
    required String callId,
    required String channelName,
    required String callerName,
    required String internName,
  }) async {
    if (internFcmToken.isEmpty) return;

    await FirebaseFirestore.instance.collection('fcm_queue').add({
      'token'      : internFcmToken,
      'callId'     : callId,
      'channelName': channelName,
      'callerName' : callerName,
      'internName' : internName,
      'sentAt'     : FieldValue.serverTimestamp(),
      'processed'  : false,
    });
  }
}