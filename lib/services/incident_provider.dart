import 'package:flutter/foundation.dart';
import '../models/incident.dart';
import 'firestore_service.dart';
import 'cache_service.dart';

class IncidentProvider extends ChangeNotifier {
  final CacheService _cacheService = CacheService();
  final FirestoreService _firestoreService = FirestoreService();

  List<Incident> _incidents = [];
  bool _isLoading = false;
  String? _error;

  List<Incident> get incidents => _incidents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    await _cacheService.init();

    // Charger le cache d'abord pour affichage immédiat
    _incidents = _cacheService.getCachedIncidents();
    notifyListeners();

    // Puis rafraîchir depuis Firestore
    if (_cacheService.shouldRefreshCache()) {
      await refreshIncidents();
    }
  }

  Future<void> refreshIncidents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final freshIncidents =
          await _firestoreService.getAllVerifiedIncidents();
      _incidents = freshIncidents;
      await _cacheService.cacheIncidents(freshIncidents);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching incidents: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> submitIncident(Incident incident) async {
    try {
      await _firestoreService.submitIncident(incident);
      // L'incident est en pending, il n'apparaîtra sur la carte
      // qu'après vérification par l'équipe de modération
    } catch (e) {
      _error = e.toString();
      debugPrint('Error submitting incident: $e');
      rethrow;
    }
  }
}
