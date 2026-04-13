import 'package:cloud_firestore/cloud_firestore.dart';

enum PersonStatus { pending, verified, rejected }

class ConvictedPerson {
  final String id;
  final String firstName;
  final String lastName;
  final String facts;
  final DateTime? convictionDate;
  final String? address;
  final double? latitude;
  final double? longitude;
  final List<String> mediaUrls;
  final String? instagram;
  final String? twitter;
  final String? linkedin;
  final bool isAnonymous;
  final PersonStatus status;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? rejectionReason;
  final bool showAddress;
  final bool showSocialMedia;
  final DateTime createdAt;

  ConvictedPerson({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.facts,
    this.convictionDate,
    this.address,
    this.latitude,
    this.longitude,
    this.mediaUrls = const [],
    this.instagram,
    this.twitter,
    this.linkedin,
    this.isAnonymous = true,
    this.status = PersonStatus.pending,
    this.verifiedBy,
    this.verifiedAt,
    this.rejectionReason,
    this.showAddress = false,
    this.showSocialMedia = false,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  factory ConvictedPerson.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConvictedPerson(
      id: doc.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      facts: data['facts'] ?? '',
      convictionDate: data['convictionDate'] != null
          ? (data['convictionDate'] as Timestamp).toDate()
          : null,
      address: data['address'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      instagram: data['instagram'],
      twitter: data['twitter'],
      linkedin: data['linkedin'],
      isAnonymous: data['isAnonymous'] ?? true,
      status: PersonStatus.values[data['status'] ?? 0],
      verifiedBy: data['verifiedBy'],
      verifiedAt: data['verifiedAt'] != null
          ? (data['verifiedAt'] as Timestamp).toDate()
          : null,
      rejectionReason: data['rejectionReason'],
      showAddress: data['showAddress'] ?? false,
      showSocialMedia: data['showSocialMedia'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'facts': facts,
      'convictionDate': convictionDate != null
          ? Timestamp.fromDate(convictionDate!)
          : null,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'mediaUrls': mediaUrls,
      'instagram': instagram,
      'twitter': twitter,
      'linkedin': linkedin,
      'isAnonymous': isAnonymous,
      'status': status.index,
      'verifiedBy': verifiedBy,
      'verifiedAt':
          verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'rejectionReason': rejectionReason,
      'showAddress': showAddress,
      'showSocialMedia': showSocialMedia,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
