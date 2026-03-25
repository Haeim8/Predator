import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/incident.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _collection = 'incidents';

  /// Fetch only verified incidents for public display
  Stream<List<Incident>> getVerifiedIncidents() {
    return _db
        .collection(_collection)
        .where('status', isEqualTo: IncidentStatus.verified.index)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Incident.fromFirestore(doc)).toList());
  }

  /// Fetch verified incidents within a bounding box for map display
  Future<List<Incident>> getIncidentsInArea({
    required double southLat,
    required double northLat,
    required double westLng,
    required double eastLng,
  }) async {
    // Firestore doesn't support compound geo queries natively,
    // so we filter by latitude range and then filter longitude in memory
    final snapshot = await _db
        .collection(_collection)
        .where('status', isEqualTo: IncidentStatus.verified.index)
        .where('latitude', isGreaterThanOrEqualTo: southLat)
        .where('latitude', isLessThanOrEqualTo: northLat)
        .get();

    return snapshot.docs
        .map((doc) => Incident.fromFirestore(doc))
        .where((incident) =>
            incident.longitude >= westLng && incident.longitude <= eastLng)
        .toList();
  }

  /// Submit a new incident (pending verification)
  Future<void> submitIncident(Incident incident) async {
    await _db.collection(_collection).add(incident.toFirestore());
  }

  /// Get all incidents for caching
  Future<List<Incident>> getAllVerifiedIncidents() async {
    final snapshot = await _db
        .collection(_collection)
        .where('status', isEqualTo: IncidentStatus.verified.index)
        .get();

    return snapshot.docs.map((doc) => Incident.fromFirestore(doc)).toList();
  }
}
