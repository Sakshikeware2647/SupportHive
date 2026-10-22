// ─────────────────────────────────────────────────────────────────
// model/call_model.dart
// ─────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

/// String constants used as Firestore status values.
/// Using a class with static consts (not enum) so Firestore
/// stores plain strings that are easy to query with .where().
class CallStatus {
  CallStatus._();
  static const String ringing   = 'ringing';
  static const String accepted  = 'accepted';
  static const String declined  = 'declined';
  static const String ended     = 'ended';
  static const String missed    = 'missed';
}

class CallModel {
  final String callId;
  final String userId;
  final String userDisplayName;
  final String internId;
  final String internName;
  final String channelName;
  final String status;
  final DateTime createdAt;

  const CallModel({
    required this.callId,
    required this.userId,
    required this.userDisplayName,
    required this.internId,
    required this.internName,
    required this.channelName,
    required this.status,
    required this.createdAt,
  });

  factory CallModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime created;
    final raw = map['createdAt'];
    if (raw is Timestamp) {
      created = raw.toDate();
    } else {
      created = DateTime.now();
    }
    return CallModel(
      callId: id,
      userId: map['userId'] ?? '',
      userDisplayName: map['userDisplayName'] ?? 'User',
      internId: map['internId'] ?? '',
      internName: map['internName'] ?? '',
      channelName: map['channelName'] ?? '',
      status: map['status'] ?? CallStatus.ringing,
      createdAt: created,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userDisplayName': userDisplayName,
        'internId': internId,
        'internName': internName,
        'channelName': channelName,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}