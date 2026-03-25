import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/incident.dart';

class CacheService {
  static const String _incidentsKey = 'cached_incidents';
  static const String _lastFetchKey = 'last_fetch_time';
  static const String _onboardingKey = 'onboarding_complete';
  static const String _termsAcceptedKey = 'terms_accepted';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Cache incidents locally
  Future<void> cacheIncidents(List<Incident> incidents) async {
    final jsonList = incidents
        .map((i) => {
              'id': i.id,
              'latitude': i.latitude,
              'longitude': i.longitude,
              'address': i.address,
              'description': i.description,
              'type': i.type.index,
              'status': i.status.index,
              'dateTime': i.dateTime.millisecondsSinceEpoch,
              'createdAt': i.createdAt.millisecondsSinceEpoch,
              'source': i.source,
              'isAnonymous': i.isAnonymous,
            })
        .toList();
    await _prefs.setString(_incidentsKey, jsonEncode(jsonList));
    await _prefs.setInt(
        _lastFetchKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Get cached incidents
  List<Incident> getCachedIncidents() {
    final jsonString = _prefs.getString(_incidentsKey);
    if (jsonString == null) return [];

    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) {
      return Incident(
        id: json['id'],
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        address: json['address'],
        description: json['description'],
        type: IncidentType.values[json['type']],
        status: IncidentStatus.values[json['status']],
        dateTime:
            DateTime.fromMillisecondsSinceEpoch(json['dateTime']),
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
        source: json['source'],
        isAnonymous: json['isAnonymous'] ?? true,
      );
    }).toList();
  }

  /// Check if cache needs refresh (older than 30 minutes)
  bool shouldRefreshCache() {
    final lastFetch = _prefs.getInt(_lastFetchKey);
    if (lastFetch == null) return true;
    final lastFetchTime =
        DateTime.fromMillisecondsSinceEpoch(lastFetch);
    return DateTime.now().difference(lastFetchTime).inMinutes > 30;
  }

  /// Onboarding state
  bool get isOnboardingComplete =>
      _prefs.getBool(_onboardingKey) ?? false;

  Future<void> setOnboardingComplete() async {
    await _prefs.setBool(_onboardingKey, true);
  }

  /// Terms acceptance
  bool get areTermsAccepted =>
      _prefs.getBool(_termsAcceptedKey) ?? false;

  Future<void> setTermsAccepted() async {
    await _prefs.setBool(_termsAcceptedKey, true);
  }
}
