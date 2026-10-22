/// ─────────────────────────────────────────────────────────────────────────────
/// model/admin_expert_model.dart
///
/// Thin wrapper around Expert that adds [phoneNumber].
/// Used exclusively on the admin side so the existing Expert model is
/// untouched and user-side code continues to compile without changes.
/// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import '/model/expert_model.dart';

class AdminExpert extends Expert {
  /// Expert's contact phone number. Used to send the SMS join-link after a
  /// user's payment succeeds.
  final String phoneNumber;

  AdminExpert({
    required super.id,
    required super.name,
    required super.specialization,
    required super.category,
    required super.rating,
    required super.reviewCount,
    required super.isAvailable,
    required super.price,
    required super.experienceYears,
    required super.tags,
    required super.clinic,
    required super.avatarInitials,
    super.avatarColor,
    super.isNew = false,
    super.bio,
    super.offersAudio = true,
    super.offersVideo = true,
    super.offersChat = true,
    required this.phoneNumber,
  });

  // ── Firestore ────────────────────────────────────────────────────────────────

  factory AdminExpert.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AdminExpert(
      id: doc.id,
      name: d['name'] ?? '',
      specialization: d['specialization'] ?? '',
      category: d['category'] ?? 'general',
      rating: (d['rating'] ?? 0.0).toDouble(),
      reviewCount: d['reviewCount'] ?? 0,
      isAvailable: d['isAvailable'] ?? false,
      price: d['price'] ?? 0,
      experienceYears: d['experienceYears'] ?? 0,
      tags: List<String>.from(d['tags'] ?? []),
      clinic: d['clinic'] ?? '',
      avatarInitials: d['avatarInitials'] ?? 'DR',
      avatarColor: d['avatarColor'],
      isNew: d['isNew'] ?? false,
      bio: d['bio'],
      offersAudio: d['offersAudio'] ?? true,
      offersVideo: d['offersVideo'] ?? true,
      offersChat: d['offersChat'] ?? true,
      phoneNumber: d['phoneNumber'] ?? '',
    );
  }

  @override
  Map<String, dynamic> toFirestore() => {
        ...super.toFirestore(),
        'phoneNumber': phoneNumber,
      };
}