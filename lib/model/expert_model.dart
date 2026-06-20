import 'package:cloud_firestore/cloud_firestore.dart';

class Expert {
  final String id;
  final String name;
  final String specialization;
  final String category; // anxiety, sleep, depression, medical, etc.
  final double rating;
  final int reviewCount;
  final bool isAvailable;
  final int price; // in INR
  final int experienceYears;
  final List<String> tags; // e.g. ["PTSD", "Anxiety Disorders"]
  final String clinic;
  final String avatarInitials;
  final String? avatarColor; // hex string
  final bool isNew;
  final String? bio;
  final bool offersAudio;
  final bool offersVideo;
  final bool offersChat;

  Expert({
    required this.id,
    required this.name,
    required this.specialization,
    required this.category,
    required this.rating,
    required this.reviewCount,
    required this.isAvailable,
    required this.price,
    required this.experienceYears,
    required this.tags,
    required this.clinic,
    required this.avatarInitials,
    this.avatarColor,
    this.isNew = false,
    this.bio,
    this.offersAudio = true,
    this.offersVideo = true,
    this.offersChat = true,
  });

  factory Expert.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Expert(
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
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'specialization': specialization,
        'category': category,
        'rating': rating,
        'reviewCount': reviewCount,
        'isAvailable': isAvailable,
        'price': price,
        'experienceYears': experienceYears,
        'tags': tags,
        'clinic': clinic,
        'avatarInitials': avatarInitials,
        'avatarColor': avatarColor,
        'isNew': isNew,
        'bio': bio,
        'offersAudio': offersAudio,
        'offersVideo': offersVideo,
        'offersChat': offersChat,
      };

  // Hardcoded seed data for development
  static List<Expert> get seedExperts => [
        Expert(
          id: 'expert_001',
          name: 'Dr. Rajesh Kumar',
          specialization: 'MD Psychiatry',
          category: 'anxiety',
          rating: 4.8,
          reviewCount: 2100,
          isAvailable: true,
          price: 1200,
          experienceYears: 12,
          tags: ['Anxiety Disorders', 'PTSD', 'Cognitive Therapy'],
          clinic: 'Mind & Soul Wellness Center',
          avatarInitials: 'RK',
          avatarColor: '#7C3AED',
          bio:
              'Specialist in anxiety and trauma-related disorders with 12+ years of clinical experience.',
        ),
        Expert(
          id: 'expert_002',
          name: 'Dr. Priya Sharma',
          specialization: 'PhD Clinical Psychology',
          category: 'depression',
          rating: 4.9,
          reviewCount: 1240,
          isAvailable: true,
          price: 1500,
          experienceYears: 8,
          tags: ['Depression', 'CBT', 'Mindfulness'],
          clinic: 'Wellness Mental Health Center',
          avatarInitials: 'PS',
          avatarColor: '#EC4899',
          bio:
              'Expert in evidence-based therapies for depression and mood disorders.',
        ),
        Expert(
          id: 'expert_003',
          name: 'Dr. Arjun Mehta',
          specialization: 'Sleep Medicine Specialist',
          category: 'sleep',
          rating: 4.7,
          reviewCount: 890,
          isAvailable: false,
          price: 1000,
          experienceYears: 10,
          tags: ['Insomnia', 'Sleep Disorders', 'CBT-I'],
          clinic: 'Restful Sleep Clinic',
          avatarInitials: 'AM',
          avatarColor: '#0EA5E9',
          bio:
              'Dedicated to treating sleep disorders with evidence-based methods.',
        ),
        Expert(
          id: 'expert_004',
          name: 'Dr. Sunita Patel',
          specialization: 'Child & Adolescent Psychiatry',
          category: 'child',
          rating: 4.9,
          reviewCount: 670,
          isAvailable: true,
          price: 1800,
          experienceYears: 15,
          tags: ['ADHD', 'Autism', 'Teen Mental Health'],
          clinic: 'Little Minds Clinic',
          avatarInitials: 'SP',
          avatarColor: '#F59E0B',
          bio:
              'Passionate about supporting children and adolescents through mental health challenges.',
        ),
        Expert(
          id: 'expert_005',
          name: 'Dr. Vikram Nair',
          specialization: 'MD Neurology & Psychiatry',
          category: 'medical',
          rating: 4.6,
          reviewCount: 430,
          isAvailable: true,
          price: 2000,
          experienceYears: 20,
          tags: ['OCD', 'Bipolar', 'Schizophrenia'],
          clinic: 'NeuroMind Institute',
          avatarInitials: 'VN',
          avatarColor: '#10B981',
          bio:
              'Combining neurology and psychiatry for comprehensive mental health care.',
        ),
      ];
}
