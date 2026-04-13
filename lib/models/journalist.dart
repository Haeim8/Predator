import 'package:cloud_firestore/cloud_firestore.dart';

class Journalist {
  final String uid;
  final String phoneNumber;
  final String pseudo;
  final String bio;
  final String? instagram;
  final String? twitter;
  final String? linkedin;
  final String? pressCardUrl;
  final String? pressCardNumber;
  final bool isCardVerified;
  final bool isSubscriptionActive;
  final DateTime? subscriptionExpiry;
  final DateTime createdAt;

  Journalist({
    required this.uid,
    required this.phoneNumber,
    required this.pseudo,
    this.bio = '',
    this.instagram,
    this.twitter,
    this.linkedin,
    this.pressCardUrl,
    this.pressCardNumber,
    this.isCardVerified = false,
    this.isSubscriptionActive = false,
    this.subscriptionExpiry,
    required this.createdAt,
  });

  factory Journalist.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Journalist(
      uid: doc.id,
      phoneNumber: data['phoneNumber'] ?? '',
      pseudo: data['pseudo'] ?? '',
      bio: data['bio'] ?? '',
      instagram: data['instagram'],
      twitter: data['twitter'],
      linkedin: data['linkedin'],
      pressCardUrl: data['pressCardUrl'],
      pressCardNumber: data['pressCardNumber'],
      isCardVerified: data['isCardVerified'] ?? false,
      isSubscriptionActive: data['isSubscriptionActive'] ?? false,
      subscriptionExpiry: data['subscriptionExpiry'] != null
          ? (data['subscriptionExpiry'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'phoneNumber': phoneNumber,
      'pseudo': pseudo,
      'bio': bio,
      'instagram': instagram,
      'twitter': twitter,
      'linkedin': linkedin,
      'pressCardUrl': pressCardUrl,
      'pressCardNumber': pressCardNumber,
      'isCardVerified': isCardVerified,
      'isSubscriptionActive': isSubscriptionActive,
      'subscriptionExpiry': subscriptionExpiry != null
          ? Timestamp.fromDate(subscriptionExpiry!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get hasValidSubscription {
    if (!isSubscriptionActive) return false;
    if (subscriptionExpiry == null) return false;
    return subscriptionExpiry!.isAfter(DateTime.now());
  }
}
