import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:predator/l10n/app_localizations.dart';
import '../../core/theme.dart';
import '../../models/incident.dart';
import '../../services/incident_provider.dart';
import '../../services/location_service.dart';
import '../../widgets/incident_detail_sheet.dart';
import '../../widgets/report_incident_sheet.dart';
import '../../widgets/persons_list_sheet.dart';
import '../../models/convicted_person.dart';
import '../../services/firestore_service.dart';
import '../journalist/journalist_login_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();

  LatLng _currentPosition = const LatLng(48.8566, 2.3522);
  bool _locationGranted = false;
  List<ConvictedPerson> _verifiedPersons = [];

  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > 800;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocation();
      _loadIncidents();
      _loadPersons();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkLocation() async {
    try {
      final granted = await _locationService.checkAndRequestPermission();
      if (!mounted) return;

      if (!granted) {
        // Pas de blocage, on laisse la carte afficher les incidents
        return;
      }

      setState(() => _locationGranted = true);
      final position = await _locationService.getCurrentPosition();
      if (position != null && mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      // Géoloc échouée, pas grave — les incidents s'affichent quand même
    }
  }


  Future<void> _loadIncidents() async {
    final provider = context.read<IncidentProvider>();
    await provider.init();
    if (!mounted) return;
    _fitMapToIncidents(provider.incidents);
  }

  void _fitMapToIncidents(List<Incident> incidents) {
    if (incidents.isEmpty) return;

    double minLat = incidents.first.latitude;
    double maxLat = incidents.first.latitude;
    double minLng = incidents.first.longitude;
    double maxLng = incidents.first.longitude;

    for (final i in incidents) {
      if (i.latitude < minLat) minLat = i.latitude;
      if (i.latitude > maxLat) maxLat = i.latitude;
      if (i.longitude < minLng) minLng = i.longitude;
      if (i.longitude > maxLng) maxLng = i.longitude;
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
    );
  }

  Color _getMarkerColor(IncidentType type) {
    switch (type) {
      case IncidentType.sexualAssault:
        return Colors.red;
      case IncidentType.harassment:
        return Colors.orange;
      case IncidentType.violence:
        return Colors.purple;
      case IncidentType.other:
        return Colors.amber;
      case IncidentType.individual:
        return Colors.black;
    }
  }

  IconData _getMarkerIcon(IncidentType type) {
    switch (type) {
      case IncidentType.sexualAssault:
        return Icons.warning_amber;
      case IncidentType.harassment:
        return Icons.report_problem_outlined;
      case IncidentType.violence:
        return Icons.dangerous_outlined;
      case IncidentType.other:
        return Icons.info_outline;
      case IncidentType.individual:
        return Icons.person;
    }
  }

  void _showIncidentDetail(Incident incident) {
    if (_isDesktop(context)) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 300, vertical: 80),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: IncidentDetailSheet(incident: incident),
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => IncidentDetailSheet(incident: incident),
      );
    }
  }

  void _showReportSheet() {
    if (_isDesktop(context)) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 280, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: ReportIncidentSheet(
                currentPosition: _currentPosition,
                onSubmitted: () => _loadIncidents(),
              ),
            ),
          ),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportIncidentSheet(
        currentPosition: _currentPosition,
        onSubmitted: () => _loadIncidents(),
      ),
    );
  }

  void _showPersonDetail(ConvictedPerson person) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PersonDetailPublicSheet(person: person),
    );
  }

  void _showPersonsSheet() {
    if (_isDesktop(context)) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 280, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: const PersonsListSheet(),
            ),
          ),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PersonsListSheet(),
    );
  }

  Future<void> _loadPersons() async {
    try {
      final persons = await FirestoreService().getVerifiedPersons();
      if (!mounted) return;
      setState(() => _verifiedPersons = persons);
    } catch (e) {
      debugPrint('Error loading persons: $e');
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    // Chercher d'abord dans les personnes condamnées par nom/prénom
    final q = query.toLowerCase();
    final matchedPerson = _verifiedPersons.where((p) =>
        p.firstName.toLowerCase().contains(q) ||
        p.lastName.toLowerCase().contains(q) ||
        p.fullName.toLowerCase().contains(q));

    if (matchedPerson.isNotEmpty) {
      // Ouvrir le bottom sheet des personnes avec les résultats
      _showPersonsSheet();
      return;
    }

    // Sinon chercher une adresse/ville
    final location = await _locationService.getCoordinatesFromAddress(query);
    if (location != null && mounted) {
      final latLng = LatLng(location.latitude, location.longitude);
      _mapController.move(latLng, 14);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = _isDesktop(context);

    return Scaffold(
      body: Stack(
        children: [
          // ── Map (full screen) ──
          Consumer<IncidentProvider>(
            builder: (context, provider, _) {
              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentPosition,
                  initialZoom: 12,
                  minZoom: 3,
                  maxZoom: 18,
                ),
                children: [
                  // Tiles OpenStreetMap
                  TileLayer(
                    urlTemplate: isDark
                        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                        : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.predator.predator',
                  ),

                  // Marqueurs des incidents
                  MarkerLayer(
                    markers: provider.incidents.map((incident) {
                      return Marker(
                        point: LatLng(incident.latitude, incident.longitude),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => _showIncidentDetail(incident),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _getMarkerColor(incident.type),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _getMarkerColor(incident.type)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              _getMarkerIcon(incident.type),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Marqueurs des personnes condamnées (noir)
                  MarkerLayer(
                    markers: _verifiedPersons
                        .where((p) =>
                            p.showAddress &&
                            p.latitude != null &&
                            p.longitude != null)
                        .map((person) {
                      return Marker(
                        point: LatLng(person.latitude!, person.longitude!),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => _showPersonDetail(person),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Position actuelle
                  if (_locationGranted)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentPosition,
                          width: 24,
                          height: 24,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),

          // ── Search bar ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: isDesktop ? 480 : MediaQuery.of(context).size.width - 24,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? VigileTheme.darkCard.withValues(alpha: 0.95)
                      : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'journalist') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const JournalistLoginScreen()),
                          );
                        }
                      },
                      offset: const Offset(0, 40),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: isDark ? VigileTheme.darkCard : Colors.white,
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'journalist',
                          child: Row(
                            children: [
                              Icon(Icons.badge,
                                  size: 18, color: VigileTheme.primaryRed),
                              const SizedBox(width: 10),
                              Text('Espace Journaliste',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white : Colors.black87,
                                  )),
                            ],
                          ),
                        ),
                      ],
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.remove_red_eye_outlined,
                              color: VigileTheme.primaryRed, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'VIGILE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                              color: VigileTheme.primaryRed,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_drop_down,
                              color: VigileTheme.primaryRed, size: 18),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 20,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: l10n.searchPlaceholder,
                          border: InputBorder.none,
                          filled: false,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white24 : Colors.black26,
                            fontSize: 13,
                          ),
                          isDense: true,
                        ),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 13,
                        ),
                        onSubmitted: _searchLocation,
                      ),
                    ),
                    InkWell(
                      onTap: () => _searchLocation(_searchController.text),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(Icons.search,
                            size: 20,
                            color: isDark ? Colors.white38 : Colors.black38),
                      ),
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: -0.3, end: 0),
          ),

          // ── Légende ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 72,
            right: isDesktop ? 20 : 12,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? VigileTheme.darkCard.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _legendDot(Colors.red, l10n.sexualAssault, isDark),
                  const SizedBox(height: 4),
                  _legendDot(Colors.orange, l10n.harassment, isDark),
                  const SizedBox(height: 4),
                  _legendDot(Colors.purple, l10n.violence, isDark),
                  const SizedBox(height: 4),
                  _legendDot(Colors.amber, l10n.other, isDark),
                  const SizedBox(height: 4),
                  _legendDot(Colors.black, 'Individu', isDark),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          ),

          // ── Right toolbar ──
          Positioned(
            bottom: isDesktop ? 24 : 100,
            right: isDesktop ? 20 : 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bouton individus
                _toolButton(
                  icon: Icons.person_search,
                  isDark: isDark,
                  onTap: _showPersonsSheet,
                ),
                const SizedBox(height: 8),
                _toolButton(
                  icon: Icons.refresh,
                  isDark: isDark,
                  onTap: () =>
                      context.read<IncidentProvider>().refreshIncidents(),
                ),
                const SizedBox(height: 8),
                _toolButton(
                  icon: Icons.my_location,
                  isDark: isDark,
                  isAccent: true,
                  onTap: () {
                    if (_locationGranted) {
                      _mapController.move(_currentPosition, 15);
                    } else {
                      _checkLocation();
                    }
                  },
                ),
                if (isDesktop) ...[
                  const SizedBox(height: 12),
                  Material(
                    color: VigileTheme.primaryRed,
                    borderRadius: BorderRadius.circular(12),
                    elevation: 4,
                    child: InkWell(
                      onTap: _showReportSheet,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        child: const Icon(Icons.add_alert,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ],
            ).animate().fadeIn(delay: 600.ms),
          ),

          // ── Loading indicator ──
          Consumer<IncidentProvider>(
            builder: (context, provider, _) {
              if (!provider.isLoading) return const SizedBox.shrink();
              return Positioned(
                bottom: isDesktop ? 90 : 170,
                right: isDesktop ? 26 : 18,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? VigileTheme.darkCard : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          VigileTheme.primaryRed),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),

      // ── Mobile-only FAB ──
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton.extended(
              onPressed: _showReportSheet,
              backgroundColor: VigileTheme.primaryRed,
              icon: const Icon(Icons.add_alert,
                  color: Colors.white, size: 18),
              label: Text(
                l10n.reportIncident,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
              ),
            ).animate().fadeIn(delay: 800.ms).slideY(begin: 1, end: 0),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _toolButton({
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
    bool isAccent = false,
  }) {
    return Material(
      color: isDark ? VigileTheme.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 20,
            color: isAccent
                ? VigileTheme.primaryRed
                : (isDark ? Colors.white60 : Colors.black45),
          ),
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }
}
