import 'package:cloud_firestore/cloud_firestore.dart';

enum IncidentType {
  sexualAssault,
  harassment,
  violence,
  other,
}

enum IncidentStatus {
  pending,
  verified,
  rejected,
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
    }
  }
}
