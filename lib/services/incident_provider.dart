import 'package:flutter/foundation.dart';
import '../main.dart';
import '../models/incident.dart';
import 'cache_service.dart';

class IncidentProvider extends ChangeNotifier {
  final CacheService _cacheService = CacheService();

  List<Incident> _incidents = [];
  bool _isLoading = false;
  String? _error;

  List<Incident> get incidents => _incidents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    await _cacheService.init();

    if (kDemoMode) {
      _incidents = _getDemoIncidents();
      notifyListeners();
      return;
    }

    _incidents = _cacheService.getCachedIncidents();
    notifyListeners();

    if (_cacheService.shouldRefreshCache()) {
      await refreshIncidents();
    }
  }

  Future<void> refreshIncidents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (kDemoMode) {
      await Future.delayed(const Duration(seconds: 1));
      _incidents = _getDemoIncidents();
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Production: use FirestoreService
    _isLoading = false;
    notifyListeners();
  }

  Future<void> submitIncident(Incident incident) async {
    if (kDemoMode) {
      await Future.delayed(const Duration(milliseconds: 800));
      _incidents = [..._incidents, incident];
      notifyListeners();
      return;
    }
    // Production: use FirestoreService
  }

  List<Incident> _getDemoIncidents() {
    return [
      // Paris - Gare du Nord
      Incident(
        id: 'demo_1',
        latitude: 48.8809,
        longitude: 2.3553,
        address: 'Gare du Nord, Paris, France',
        description:
            'Zone signalée pour harcèlement de rue récurrent. Plusieurs témoignages concordants de victimes entre 22h et 2h du matin.',
        type: IncidentType.harassment,
        status: IncidentStatus.verified,
        dateTime: DateTime(2025, 11, 15, 23, 30),
        createdAt: DateTime(2025, 11, 16),
        source: '@parisalerte_info',
      ),
      // Paris - Châtelet
      Incident(
        id: 'demo_2',
        latitude: 48.8589,
        longitude: 2.3469,
        address: 'Les Halles, Châtelet, Paris',
        description:
            'Agression sexuelle signalée dans le couloir souterrain du forum. Fait vérifié par les autorités locales.',
        type: IncidentType.sexualAssault,
        status: IncidentStatus.verified,
        dateTime: DateTime(2025, 12, 3, 21, 15),
        createdAt: DateTime(2025, 12, 4),
      ),
      // Paris - Stalingrad
      Incident(
        id: 'demo_3',
        latitude: 48.8842,
        longitude: 2.3668,
        address: 'Place de Stalingrad, Paris',
        description:
            'Zone à risque identifiée. Plusieurs agressions violentes signalées ces derniers mois.',
        type: IncidentType.violence,
        status: IncidentStatus.verified,
        dateTime: DateTime(2025, 10, 20, 20, 0),
        createdAt: DateTime(2025, 10, 21),
        source: 'Journaliste indépendant - Le Média Local',
      ),
      // Marseille - La Canebière
      Incident(
        id: 'demo_4',
        latitude: 43.2965,
        longitude: 5.3698,
        address: 'La Canebière, Marseille, France',
        description:
            'Harcèlement de rue signalé à plusieurs reprises. Témoignages recueillis auprès de résidents.',
        type: IncidentType.harassment,
        status: IncidentStatus.verified,
        dateTime: DateTime(2025, 9, 10, 19, 45),
        createdAt: DateTime(2025, 9, 11),
      ),
      // Lyon - Part-Dieu
      Incident(
        id: 'demo_5',
        latitude: 45.7606,
        longitude: 4.8593,
        address: 'Gare Part-Dieu, Lyon, France',
        description:
            'Tentative d\'agression dans le parking souterrain. Plainte déposée et confirmée.',
        type: IncidentType.sexualAssault,
        status: IncidentStatus.verified,
        dateTime: DateTime(2025, 11, 28, 22, 0),
        createdAt: DateTime(2025, 11, 29),
      ),
      // Milan - Stazione Centrale
      Incident(
        id: 'demo_6',
        latitude: 45.4854,
        longitude: 9.2046,
        address: 'Stazione Centrale, Milano, Italia',
        description:
            'Zona segnalata per molestie ricorrenti nei pressi della stazione. Verificato da associazioni locali.',
        type: IncidentType.harassment,
        status: IncidentStatus.verified,
        dateTime: DateTime(2025, 12, 1, 23, 0),
        createdAt: DateTime(2025, 12, 2),
        source: '@milano_sicura',
      ),
      // Barcelona - Las Ramblas
      Incident(
        id: 'demo_7',
        latitude: 41.3818,
        longitude: 2.1735,
        address: 'Las Ramblas, Barcelona, España',
        description:
            'Zona de alerta por múltiples incidentes de acoso nocturno. Reportado por vecinos y turistas.',
        type: IncidentType.harassment,
        status: IncidentStatus.verified,
        dateTime: DateTime(2025, 8, 15, 1, 30),
        createdAt: DateTime(2025, 8, 16),
      ),
      // Berlin - Alexanderplatz
      Incident(
        id: 'demo_8',
        latitude: 52.5219,
        longitude: 13.4132,
        address: 'Alexanderplatz, Berlin, Deutschland',
        description:
            'Gewaltsamer Vorfall gemeldet. Polizeibericht bestätigt den Vorfall in der Nähe des U-Bahn-Eingangs.',
        type: IncidentType.violence,
        status: IncidentStatus.verified,
        dateTime: DateTime(2025, 10, 5, 0, 30),
        createdAt: DateTime(2025, 10, 6),
      ),
      // Paris - Barbès
      Incident(
        id: 'demo_9',
        latitude: 48.8845,
        longitude: 2.3497,
        address: 'Boulevard Barbès, Paris',
        description:
            'Plusieurs signalements de harcèlement de rue. Zone identifiée par les associations de quartier.',
        type: IncidentType.harassment,
        status: IncidentStatus.verified,
        dateTime: DateTime(2025, 11, 5, 18, 0),
        createdAt: DateTime(2025, 11, 6),
      ),
      // Paris - Bois de Boulogne
      Incident(
        id: 'demo_10',
        latitude: 48.8626,
        longitude: 2.2494,
        address: 'Bois de Boulogne, Paris',
        description:
            'Zone signalée pour agressions nocturnes. Éviter les zones isolées après 21h.',
        type: IncidentType.violence,
        status: IncidentStatus.verified,
        dateTime: DateTime(2025, 7, 20, 23, 45),
        createdAt: DateTime(2025, 7, 21),
        source: 'Préfecture de Police de Paris',
      ),
    ];
  }
}
