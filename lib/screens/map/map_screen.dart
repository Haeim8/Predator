import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:predator/l10n/app_localizations.dart';
import '../../core/theme.dart';
import '../../models/incident.dart';
import '../../services/incident_provider.dart';
import '../../services/location_service.dart';
import '../../widgets/incident_detail_sheet.dart';
import '../../widgets/report_incident_sheet.dart';
import '../../widgets/location_permission_dialog.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();

  LatLng _currentPosition = const LatLng(48.8566, 2.3522);
  bool _locationGranted = false;
  bool _mapReady = false;
  Set<Marker> _markers = {};

  static const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#212121"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#757575"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#181818"}]},
  {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2c2c2c"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#8a8a8a"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3c3c3c"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#3d3d3d"}]}
]
''';

  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > 800;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocation();
      _loadIncidents();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkLocation() async {
    try {
      final granted = await _locationService.checkAndRequestPermission();
      if (!mounted) return;

      if (!granted) {
        _showLocationDialog();
        return;
      }

      setState(() => _locationGranted = true);
      final position = await _locationService.getCurrentPosition();
      if (position != null && mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition, 14),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _locationGranted = true);
    }
  }

  void _showLocationDialog() {
    final isWide = _isDesktop(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        insetPadding: isWide
            ? const EdgeInsets.symmetric(horizontal: 300, vertical: 120)
            : const EdgeInsets.all(24),
        backgroundColor: Colors.transparent,
        child: LocationPermissionDialog(
          onRetry: () {
            Navigator.of(ctx).pop();
            _checkLocation();
          },
          onOpenSettings: () {
            Navigator.of(ctx).pop();
            _locationService.openLocationSettings();
          },
        ),
      ),
    );
  }

  Future<void> _loadIncidents() async {
    final provider = context.read<IncidentProvider>();
    await provider.init();
    _buildMarkers();
  }

  void _buildMarkers() {
    final provider = context.read<IncidentProvider>();
    final incidents = provider.incidents;

    setState(() {
      _markers = incidents.map((incident) {
        return Marker(
          markerId: MarkerId(incident.id),
          position: LatLng(incident.latitude, incident.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getMarkerHue(incident.type),
          ),
          onTap: () => _showIncidentDetail(incident),
        );
      }).toSet();
    });
  }

  double _getMarkerHue(IncidentType type) {
    switch (type) {
      case IncidentType.sexualAssault:
        return BitmapDescriptor.hueRed;
      case IncidentType.harassment:
        return BitmapDescriptor.hueOrange;
      case IncidentType.violence:
        return BitmapDescriptor.hueViolet;
      case IncidentType.other:
        return BitmapDescriptor.hueYellow;
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

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;
    final location = await _locationService.getCoordinatesFromAddress(query);
    if (location != null && mounted) {
      final latLng = LatLng(location.latitude, location.longitude);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(latLng, 14),
      );
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
              if (_mapReady) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _buildMarkers();
                });
              }
              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentPosition,
                  zoom: 12,
                ),
                style: isDark ? _darkMapStyle : null,
                onMapCreated: (controller) {
                  _mapController = controller;
                  setState(() => _mapReady = true);
                  if (_locationGranted) {
                    controller.animateCamera(
                      CameraUpdate.newLatLngZoom(_currentPosition, 14),
                    );
                  }
                },
                markers: _markers,
                myLocationEnabled: _locationGranted,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: true,
              );
            },
          ),

          // ── Search bar — centré en haut ──
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
                      ? PredatorTheme.darkCard.withValues(alpha: 0.95)
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
                    const Icon(Icons.remove_red_eye_outlined,
                        color: PredatorTheme.primaryRed, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'PREDATOR',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: PredatorTheme.primaryRed,
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

          // ── Légende — toujours à droite ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 72,
            right: isDesktop ? 20 : 12,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? PredatorTheme.darkCard.withValues(alpha: 0.9)
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
                ],
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          ),

          // ── Right toolbar : refresh + location + signaler ──
          Positioned(
            bottom: isDesktop ? 24 : 100,
            right: isDesktop ? 20 : 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(_currentPosition, 15),
                      );
                    } else {
                      _checkLocation();
                    }
                  },
                ),
                if (isDesktop) ...[
                  const SizedBox(height: 12),
                  // Bouton signaler compact en bas à droite
                  Material(
                    color: PredatorTheme.primaryRed,
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
                    color: isDark ? PredatorTheme.darkCard : Colors.white,
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
                          PredatorTheme.primaryRed),
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
              backgroundColor: PredatorTheme.primaryRed,
              icon: const Icon(Icons.add_alert, color: Colors.white, size: 18),
              label: Text(
                l10n.reportIncident,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
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
      color: isDark ? PredatorTheme.darkCard : Colors.white,
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
                ? PredatorTheme.primaryRed
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
