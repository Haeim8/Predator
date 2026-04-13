import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/incident.dart';
import '../models/convicted_person.dart';
import '../models/journalist.dart';

class FirestoreService {
  final FirebaseFirestore _db =
      FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'predatoris');

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

  // ── Convicted Persons ──

  static const String _personsCollection = 'convicted_persons';

  Future<void> submitPerson(ConvictedPerson person) async {
    await _db.collection(_personsCollection).add(person.toFirestore());
  }

  Future<List<ConvictedPerson>> getVerifiedPersons() async {
    final snapshot = await _db
        .collection(_personsCollection)
        .where('status', isEqualTo: PersonStatus.verified.index)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => ConvictedPerson.fromFirestore(doc))
        .toList();
  }

  Future<List<ConvictedPerson>> searchPersons(String query) async {
    final all = await getVerifiedPersons();
    final q = query.toLowerCase();
    return all
        .where((p) =>
            p.firstName.toLowerCase().contains(q) ||
            p.lastName.toLowerCase().contains(q))
        .toList();
  }

  /// Returns a journalist's public profile only (no phoneNumber).
  Future<Journalist?> getJournalistByPseudo(String pseudo) async {
    final snapshot = await _db
        .collection('journalists')
        .where('pseudo', isEqualTo: pseudo)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    final data = doc.data();
    // Return only public fields - strip sensitive data
    return Journalist(
      uid: doc.id,
      phoneNumber: '', // never expose phone number publicly
      pseudo: data['pseudo'] ?? '',
      bio: data['bio'] ?? '',
      instagram: data['instagram'],
      twitter: data['twitter'],
      linkedin: data['linkedin'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
