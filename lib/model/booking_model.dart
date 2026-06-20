import 'package:cloud_firestore/cloud_firestore.dart';

enum SessionType { audio, video, chat }

enum BookingStatus { pending, confirmed, completed, cancelled }

class Booking {
  final String id;
  final String userId;
  final String expertId;
  final String expertName;
  final String expertSpecialization;
  final SessionType sessionType;
  final DateTime scheduledAt;
  final bool isOnline; // online vs offline (offline only Mon-Fri)
  final int price;
  final int platformFee;
  final int gst;
  final int totalAmount;
  final BookingStatus status;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final bool isPaid;
  final bool notified1Hour;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.userId,
    required this.expertId,
    required this.expertName,
    required this.expertSpecialization,
    required this.sessionType,
    required this.scheduledAt,
    required this.isOnline,
    required this.price,
    required this.platformFee,
    required this.gst,
    required this.totalAmount,
    required this.status,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    required this.isPaid,
    this.notified1Hour = false,
    required this.createdAt,
  });

  // Weekend slots → online only
  static bool isOnlineOnly(DateTime date) {
    return date.weekday == DateTime.saturday ||
        date.weekday == DateTime.sunday;
  }

  factory Booking.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      userId: d['userId'] ?? '',
      expertId: d['expertId'] ?? '',
      expertName: d['expertName'] ?? '',
      expertSpecialization: d['expertSpecialization'] ?? '',
      sessionType: SessionType.values.firstWhere(
        (e) => e.name == (d['sessionType'] ?? 'audio'),
        orElse: () => SessionType.audio,
      ),
      scheduledAt: (d['scheduledAt'] as Timestamp).toDate(),
      isOnline: d['isOnline'] ?? true,
      price: d['price'] ?? 0,
      platformFee: d['platformFee'] ?? 0,
      gst: d['gst'] ?? 0,
      totalAmount: d['totalAmount'] ?? 0,
      status: BookingStatus.values.firstWhere(
        (e) => e.name == (d['status'] ?? 'pending'),
        orElse: () => BookingStatus.pending,
      ),
      razorpayOrderId: d['razorpayOrderId'],
      razorpayPaymentId: d['razorpayPaymentId'],
      isPaid: d['isPaid'] ?? false,
      notified1Hour: d['notified1Hour'] ?? false,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'expertId': expertId,
        'expertName': expertName,
        'expertSpecialization': expertSpecialization,
        'sessionType': sessionType.name,
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'isOnline': isOnline,
        'price': price,
        'platformFee': platformFee,
        'gst': gst,
        'totalAmount': totalAmount,
        'status': status.name,
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'isPaid': isPaid,
        'notified1Hour': notified1Hour,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  Booking copyWith({
    String? razorpayOrderId,
    String? razorpayPaymentId,
    bool? isPaid,
    BookingStatus? status,
  }) {
    return Booking(
      id: id,
      userId: userId,
      expertId: expertId,
      expertName: expertName,
      expertSpecialization: expertSpecialization,
      sessionType: sessionType,
      scheduledAt: scheduledAt,
      isOnline: isOnline,
      price: price,
      platformFee: platformFee,
      gst: gst,
      totalAmount: totalAmount,
      status: status ?? this.status,
      razorpayOrderId: razorpayOrderId ?? this.razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId ?? this.razorpayPaymentId,
      isPaid: isPaid ?? this.isPaid,
      notified1Hour: notified1Hour,
      createdAt: createdAt,
    );
  }
}
