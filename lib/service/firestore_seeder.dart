import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreSeeder {
  static final _db = FirebaseFirestore.instance;

  static Future<void> seedInterns() async {
    final interns = [
      {
        'name': 'Sarah Mitchell',
        'email': 'kartikc2w@gmail.com',
        'phone': '+91 8485054079',   // ← ADD
        'specialization': 'Anxiety | Stress',
        'rating': 4.8,
        'isAvailable': false,
        'fcmToken': '',
        'bio': 'M.Sc. Clinical Psychology, 2nd year. Trained in CBT and mindfulness approaches.',
        'sessionCount': 120,
      },
      {
        'name': 'Priya Sharma',
        'email': 'kartikdeshmukh2411@gmail.com',
        'phone': '+91 9405276709',   // ← ADD
        'specialization': 'CBT | Career',
        'rating': 4.9,
        'isAvailable': false,
        'fcmToken': '',
        'bio': 'M.A. Counselling Psychology. Focuses on career transitions and burnout recovery.',
        'sessionCount': 98,
      },
      {
        'name': 'Alex Thompson',
        'email': 'kartikdeshmukh4511@gmail.com',
        'phone': '+91 8485054079',   // ← ADD
        'specialization': 'Depression | Anxiety',
        'rating': 4.7,
        'isAvailable': false,
        'fcmToken': '',
        'bio': 'M.Sc. Applied Psychology. Trained in person-centred therapy.',
        'sessionCount': 85,
      },
    ];

    final batch = _db.batch();
    for (final intern in interns) {
      final docId = (intern['email'] as String)
          .replaceAll('.', '_')
          .replaceAll('@', '_at_');
      final ref = _db.collection('interns').doc(docId);
      batch.set(ref, intern, SetOptions(merge: true));
    }

    await batch.commit();
    print('✅ Interns seeded to Firestore');
  }
}