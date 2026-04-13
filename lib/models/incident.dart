import 'package:cloud_firestore/cloud_firestore.dart';

enum IncidentType {
  sexualAssault,
  harassment,
  violence,
  other,
  individual,
}

enum IncidentStatus {
  pending,
  verified,
  rejected,
}

enum DangerLevel {
  vigilance,  // 1 - vert
  risque,     // 2 - jaune
  incident,   // 3 - orange
  urgence,    // 4 - rouge
}

class Incident {
  final String id;
  final double latitude;
  final double longitude;
  final String address;
  final String description;
  final IncidentType type;
  final IncidentStatus status;
  final DateTime dateTime;
  final DateTime createdAt;
  final String? source;
  final bool isAnonymous;
  final List<String> mediaUrls;
  final String? socialMediaUrl;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final int viewCount;
  final String? rejectionReason;
  final DangerLevel dangerLevel;

  Incident({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.description,
    required this.type,
    required this.status,
    required this.dateTime,
    required this.createdAt,
    this.source,
    this.isAnonymous = true,
    this.mediaUrls = const [],
    this.socialMediaUrl,
    this.dangerLevel = DangerLevel.vigilance,
    this.verifiedBy,
    this.verifiedAt,
    this.viewCount = 0,
    this.rejectionReason,
  });

  factory Incident.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Incident(
      id: doc.id,
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      address: data['address'] ?? '',
      description: data['description'] ?? '',
      type: IncidentType.values[data['type'] ?? 0],
      status: IncidentStatus.values[data['status'] ?? 0],
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      source: data['source'],
      isAnonymous: data['isAnonymous'] ?? true,
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      socialMediaUrl: data['socialMediaUrl'],
      verifiedBy: data['verifiedBy'],
      verifiedAt: data['verifiedAt'] != null
          ? (data['verifiedAt'] as Timestamp).toDate()
          : null,
      viewCount: data['viewCount'] ?? 0,
      rejectionReason: data['rejectionReason'],
      dangerLevel: DangerLevel.values[(data['dangerLevel'] ?? 0).clamp(0, 3)],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'description': description,
      'type': type.index,
      'status': status.index,
      'dateTime': Timestamp.fromDate(dateTime),
      'createdAt': Timestamp.fromDate(createdAt),
      'source': source,
      'isAnonymous': isAnonymous,
      'mediaUrls': mediaUrls,
      'socialMediaUrl': socialMediaUrl,
      'verifiedBy': verifiedBy,
      'verifiedAt':
          verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'viewCount': viewCount,
      'rejectionReason': rejectionReason,
      'dangerLevel': dangerLevel.index,
    };
  }

  String get typeLabel {
    switch (type) {
      case IncidentType.sexualAssault:
        return 'Sexual Assault';
      case IncidentType.harassment:
        return 'Harassment';
      case IncidentType.violence:
        return 'Violence';
      case IncidentType.other:
        return 'Other';
      case IncidentType.individual:
        return 'Individu';
    }
  }
}
