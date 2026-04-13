import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme.dart';
import '../../models/journalist.dart';
import '../../models/incident.dart';
import '../../models/convicted_person.dart';
import '../../services/journalist_service.dart';
import '../map/map_screen.dart';
import 'journalist_login_screen.dart';


class JournalistDashboardScreen extends StatefulWidget {
  final Journalist journalist;

  const JournalistDashboardScreen({super.key, required this.journalist});

  @override
  State<JournalistDashboardScreen> createState() =>
      _JournalistDashboardScreenState();
}

class _JournalistDashboardScreenState extends State<JournalistDashboardScreen> {
  final JournalistService _service = JournalistService();
  int _selectedTab = 0;
  List<Incident> _pendingIncidents = [];
  List<Incident> _myVerifications = [];
  List<ConvictedPerson> _pendingPersons = [];
  List<ConvictedPerson> _myPersonVerifications = [];
  bool _isLoading = true;

  // Filtres signalements
  String _filterSearch = '';
  String? _filterType; // null = tous

  // Profile editing
  late TextEditingController _pseudoController;
  late TextEditingController _bioController;
  late TextEditingController _instagramController;
  late TextEditingController _twitterController;
  late TextEditingController _linkedinController;

  @override
  void initState() {
    super.initState();
    _pseudoController = TextEditingController(text: widget.journalist.pseudo);
    _bioController = TextEditingController(text: widget.journalist.bio);
    _instagramController =
        TextEditingController(text: widget.journalist.instagram ?? '');
    _twitterController =
        TextEditingController(text: widget.journalist.twitter ?? '');
    _linkedinController =
        TextEditingController(text: widget.journalist.linkedin ?? '');
    _loadIncidents();
  }

  @override
  void dispose() {
    _pseudoController.dispose();
    _bioController.dispose();
    _instagramController.dispose();
    _twitterController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  Future<void> _loadIncidents() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getPendingIncidents(),
        _service.getMyVerifications(widget.journalist.pseudo),
        _service.getPendingPersons(),
        _service.getMyPersonVerifications(widget.journalist.pseudo),
      ]);
      setState(() {
        _pendingIncidents = results[0] as List<Incident>;
        _myVerifications = results[1] as List<Incident>;
        _pendingPersons = results[2] as List<ConvictedPerson>;
        _myPersonVerifications = results[3] as List<ConvictedPerson>;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _verify(Incident incident) async {
    await _service.verifyIncident(incident.id, widget.journalist.pseudo);
    _loadIncidents();
  }

  Future<void> _showRejectDialog(Incident incident) async {
    final reasonController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? VigileTheme.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Raison du rejet',
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w700)),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Expliquez pourquoi ce signalement est rejeté...',
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(ctx, reasonController.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      await _service.rejectIncident(
          incident.id, widget.journalist.pseudo, reason);
      _loadIncidents();
    }
  }

  Future<void> _saveProfile() async {
    await _service.updateProfile(widget.journalist.uid, {
      'pseudo': _pseudoController.text.trim(),
      'bio': _bioController.text.trim(),
      'instagram': _instagramController.text.trim().isEmpty
          ? null
          : _instagramController.text.trim(),
      'twitter': _twitterController.text.trim().isEmpty
          ? null
          : _twitterController.text.trim(),
      'linkedin': _linkedinController.text.trim().isEmpty
          ? null
          : _linkedinController.text.trim(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profil mis à jour'),
        backgroundColor: VigileTheme.safeGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer mon compte'),
        content: const Text(
            'Cette action est irréversible. Toutes vos données seront supprimées.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteProfile(widget.journalist.uid);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const JournalistLoginScreen()),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _logout() async {
    await _service.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const JournalistLoginScreen()),
    );
  }

  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > 800;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_isDesktop(context)) {
      return _buildMobileLayout(isDark);
    }

    return Scaffold(
      body: Row(
        children: [
          // ── Sidebar ──
          Container(
            width: 260,
            decoration: BoxDecoration(
              color:
                  isDark ? const Color(0xFF111111) : const Color(0xFF1A1A1A),
              border: Border(
                right:
                    BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.remove_red_eye_outlined,
                        color: VigileTheme.primaryRed, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'VIGILE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'JOURNALISTE',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 3,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(height: 40),

                _navItem(0, Icons.inbox, 'Signalements reçus',
                    count: _pendingIncidents.length),
                _navItem(1, Icons.verified, 'Mes vérifications',
                    count: _myVerifications.length),
                const Divider(
                    color: Colors.white10,
                    indent: 20,
                    endIndent: 20,
                    height: 32),
                _navItem(2, Icons.person, 'Mon Profil'),

                const Spacer(),

                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        backgroundColor: VigileTheme.primaryRed,
                        child: Text(
                          widget.journalist.pseudo.isNotEmpty
                              ? widget.journalist.pseudo[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.journalist.pseudo,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                      ),
                      Text(
                        widget.journalist.phoneNumber,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 11),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                  child: TextButton.icon(
                    onPressed: _logout,
                    icon:
                        const Icon(Icons.logout, color: Colors.red, size: 18),
                    label: const Text('Déconnexion',
                        style: TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),

          // ── Main content ──
          Expanded(
            child: Container(
              color: isDark ? VigileTheme.darkBg : VigileTheme.lightBg,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: VigileTheme.primaryRed))
                  : _buildContent(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(bool isDark) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF111111) : const Color(0xFF1A1A1A),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.remove_red_eye_outlined,
                color: VigileTheme.primaryRed, size: 20),
            const SizedBox(width: 8),
            const Text(
              'VIGILE',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadIncidents,
            icon: const Icon(Icons.refresh, color: Colors.white54, size: 20),
          ),
          PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: VigileTheme.primaryRed,
              child: Text(
                widget.journalist.pseudo.isNotEmpty
                    ? widget.journalist.pseudo[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
            onSelected: (value) {
              if (value == 'logout') _logout();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(widget.journalist.pseudo,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Déconnexion', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: VigileTheme.primaryRed))
          : _buildContent(isDark),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (i) => setState(() => _selectedTab = i),
        selectedItemColor: VigileTheme.primaryRed,
        unselectedItemColor: isDark ? Colors.white38 : Colors.black38,
        backgroundColor: isDark ? const Color(0xFF111111) : Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: [
          BottomNavigationBarItem(
            icon: Badge(
              label: Text('${_pendingIncidents.length}',
                  style: const TextStyle(fontSize: 10)),
              isLabelVisible: _pendingIncidents.isNotEmpty,
              child: const Icon(Icons.inbox),
            ),
            label: 'Signalements',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text('${_myVerifications.length}',
                  style: const TextStyle(fontSize: 10)),
              isLabelVisible: _myVerifications.isNotEmpty,
              child: const Icon(Icons.verified),
            ),
            label: 'Vérifications',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, {int? count}) {
    final isSelected = _selectedTab == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected
            ? VigileTheme.primaryRed.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => setState(() => _selectedTab = index),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon,
                    size: 20,
                    color: isSelected
                        ? VigileTheme.primaryRed
                        : Colors.white54),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Colors.white : Colors.white54,
                    ),
                  ),
                ),
                if (count != null && count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? VigileTheme.primaryRed
                          : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.white54,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    switch (_selectedTab) {
      case 0:
        return _buildPendingList(isDark);
      case 1:
        return _buildMyVerifications(isDark);
      case 2:
        return _buildProfile(isDark);
      default:
        return const SizedBox();
    }
  }

  // ── Signalements reçus ──
  // Filtre les items selon la recherche et le type
  List<dynamic> _getFilteredItems() {
    final items = <dynamic>[
      ..._pendingPersons,
      ..._pendingIncidents,
    ];

    return items.where((item) {
      // Filtre par type
      if (_filterType == 'individu' && item is! ConvictedPerson) return false;
      if (_filterType == 'incident' && item is! Incident) return false;

      // Filtre par recherche
      if (_filterSearch.isNotEmpty) {
        final q = _filterSearch.toLowerCase();
        if (item is ConvictedPerson) {
          return item.fullName.toLowerCase().contains(q) ||
              (item.address ?? '').toLowerCase().contains(q) ||
              item.facts.toLowerCase().contains(q);
        } else if (item is Incident) {
          return item.address.toLowerCase().contains(q) ||
              item.description.toLowerCase().contains(q);
        }
      }
      return true;
    }).toList();
  }

  Widget _buildPendingList(bool isDark) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final filtered = _getFilteredItems();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              Text('Signalements',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: VigileTheme.primaryRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${_pendingIncidents.length + _pendingPersons.length}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: VigileTheme.primaryRed, fontSize: 13)),
              ),
              const Spacer(),
              IconButton(
                onPressed: _loadIncidents,
                icon: Icon(Icons.refresh, size: 20,
                    color: isDark ? Colors.white54 : Colors.black45),
              ),
            ],
          ),
        ),

        // Barre de recherche
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: TextField(
            onChanged: (v) => setState(() => _filterSearch = v),
            decoration: InputDecoration(
              hintText: 'Rechercher par nom, ville, description...',
              prefixIcon: const Icon(Icons.search, size: 18),
              filled: true,
              fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ),

        // Filtres type
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              _filterChip('Tous', null, isDark),
              const SizedBox(width: 6),
              _filterChip('Individus', 'individu', isDark),
              const SizedBox(width: 6),
              _filterChip('Incidents', 'incident', isDark),
            ],
          ),
        ),

        const Divider(height: 1),

        // Liste
        if (filtered.isEmpty)
          _emptyState(Icons.inbox, 'Aucun signalement', isDark)
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = filtered[index];
                if (item is ConvictedPerson) {
                  return _buildSlimPersonTile(item, dateFormat, isDark);
                } else if (item is Incident) {
                  return _buildSlimIncidentTile(item, dateFormat, isDark);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
      ],
    );
  }

  Widget _filterChip(String label, String? type, bool isDark) {
    final selected = _filterType == type;
    return GestureDetector(
      onTap: () => setState(() => _filterType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? VigileTheme.primaryRed.withValues(alpha: 0.15)
              : isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? VigileTheme.primaryRed : Colors.transparent,
          ),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? VigileTheme.primaryRed : Colors.grey)),
      ),
    );
  }

  // Tile slim pour incident
  Widget _buildSlimIncidentTile(Incident incident, DateFormat dateFormat, bool isDark) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      onTap: () => _showIncidentFullDetail(incident, true),
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: _getTypeColor(incident.type).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(_getTypeIcon(incident.type), size: 18,
            color: _getTypeColor(incident.type)),
      ),
      title: Text(incident.address,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(incident.description,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: VigileTheme.primaryRed.withValues(alpha: 0.7))),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: _getDangerColor(incident.dangerLevel).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(_getDangerLabel(incident.dangerLevel),
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                        color: _getDangerColor(incident.dangerLevel))),
              ),
              const SizedBox(width: 8),
              Icon(Icons.visibility, size: 12, color: VigileTheme.primaryRed.withValues(alpha: 0.5)),
              const SizedBox(width: 2),
              Text('${incident.viewCount}',
                  style: TextStyle(fontSize: 10, color: VigileTheme.primaryRed.withValues(alpha: 0.5))),
              const Spacer(),
              Text(dateFormat.format(incident.createdAt),
                  style: TextStyle(fontSize: 10, color: VigileTheme.primaryRed.withValues(alpha: 0.5))),
            ],
          ),
        ],
      ),
      trailing: Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
    );
  }

  // Tile slim pour personne
  Widget _buildSlimPersonTile(ConvictedPerson person, DateFormat dateFormat, bool isDark) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      onTap: () => _showVerifyPersonDialog(person),
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.person, size: 18, color: Colors.black54),
      ),
      title: Text(person.fullName.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(person.facts,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: VigileTheme.primaryRed.withValues(alpha: 0.7))),
          const SizedBox(height: 4),
          Row(
            children: [
              if (person.address != null) ...[
                Icon(Icons.location_on, size: 11, color: VigileTheme.primaryRed.withValues(alpha: 0.5)),
                const SizedBox(width: 2),
                Text(person.address!, maxLines: 1,
                    style: TextStyle(fontSize: 10, color: VigileTheme.primaryRed.withValues(alpha: 0.5))),
              ],
              const Spacer(),
              Text(dateFormat.format(person.createdAt),
                  style: TextStyle(fontSize: 10, color: VigileTheme.primaryRed.withValues(alpha: 0.5))),
            ],
          ),
        ],
      ),
      trailing: Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
    );
  }

  IconData _getTypeIcon(IncidentType type) {
    switch (type) {
      case IncidentType.sexualAssault: return Icons.warning_amber;
      case IncidentType.harassment: return Icons.report_problem_outlined;
      case IncidentType.violence: return Icons.dangerous_outlined;
      case IncidentType.other: return Icons.info_outline;
      case IncidentType.individual: return Icons.person;
    }
  }

  // ── Mes vérifications ──
  Widget _buildMyVerifications(bool isDark) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final totalVerifs = _myVerifications.length + _myPersonVerifications.length;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Mes vérifications',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87)),
              const Spacer(),
              IconButton(
                onPressed: _loadIncidents,
                icon: Icon(Icons.refresh,
                    color: isDark ? Colors.white54 : Colors.black45),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (totalVerifs == 0)
            _emptyState(Icons.verified, 'Aucune vérification', isDark)
          else
            Expanded(
              child: ListView(
                children: [
                  if (_myPersonVerifications.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text('Individus (${_myPersonVerifications.length})',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: VigileTheme.primaryRed)),
                    ),
                    ..._myPersonVerifications.map((person) =>
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildPersonCard(person, dateFormat, isDark, false),
                        )),
                    const SizedBox(height: 20),
                  ],
                  if (_myVerifications.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text('Incidents (${_myVerifications.length})',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: VigileTheme.accentOrange)),
                    ),
                    ..._myVerifications.map((incident) =>
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildIncidentCard(incident, dateFormat, isDark, false),
                        )),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyState(IconData icon, String text, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            Icon(icon,
                size: 60, color: isDark ? Colors.white12 : Colors.black12),
            const SizedBox(height: 16),
            Text(text,
                style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentCard(Incident incident, DateFormat dateFormat,
      bool isDark, bool showActions) {
    final isVerified = incident.status == IncidentStatus.verified;
    final isRejected = incident.status == IncidentStatus.rejected;

    return GestureDetector(
      onTap: () => _showIncidentFullDetail(incident, showActions),
      child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? VigileTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      _getTypeColor(incident.type).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  incident.typeLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getTypeColor(incident.type),
                  ),
                ),
              ),
              if (!showActions) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isVerified
                            ? VigileTheme.safeGreen
                            : Colors.red)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isVerified ? 'Vérifié' : 'Rejeté',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          isVerified ? VigileTheme.safeGreen : Colors.red,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 10),
              Icon(Icons.location_on, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  incident.address,
                  style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.black45),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // View count
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility,
                      size: 14,
                      color: isDark ? Colors.white24 : Colors.black26),
                  const SizedBox(width: 4),
                  Text('${incident.viewCount}',
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              isDark ? Colors.white38 : Colors.black26)),
                ],
              ),
              const SizedBox(width: 10),
              Text(
                dateFormat.format(incident.dateTime),
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black26),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Description
          Text(
            incident.description,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          // Rejection reason
          if (isRejected && incident.rejectionReason != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.block, size: 14, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Raison: ${incident.rejectionReason}',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.withValues(alpha: 0.8)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Media
          if (incident.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: incident.mediaUrls.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final url = incident.mediaUrls[i];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        width: 80,
                        height: 80,
                        color: isDark
                            ? VigileTheme.darkSurface
                            : Colors.grey[200],
                      ),
                      errorWidget: (_, _, _) => Container(
                        width: 80,
                        height: 80,
                        color: isDark
                            ? VigileTheme.darkSurface
                            : Colors.grey[200],
                        child: const Icon(Icons.broken_image,
                            color: Colors.grey),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // Social media link
          if (incident.socialMediaUrl != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final uri = Uri.parse(incident.socialMediaUrl!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Row(
                children: [
                  const Icon(Icons.share, size: 14, color: Colors.blue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      incident.socialMediaUrl!,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          decoration: TextDecoration.underline),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Source
          if (incident.source != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.link, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Source: ${incident.source}',
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black38),
                ),
              ],
            ),
          ],

          // Actions (only for pending)
          if (showActions) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showRejectDialog(incident),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Rejeter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _verify(incident),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Valider'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VigileTheme.safeGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ── Fiche détaillée incident pour journaliste ──
  void _showIncidentFullDetail(Incident incident, bool canEdit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: isDark ? VigileTheme.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getTypeColor(incident.type).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(incident.typeLabel,
                                style: TextStyle(fontWeight: FontWeight.w700,
                                    color: _getTypeColor(incident.type))),
                          ),
                          const Spacer(),
                          Text(dateFormat.format(incident.createdAt),
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Adresse
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: VigileTheme.primaryRed),
                          const SizedBox(width: 6),
                          Expanded(child: Text(incident.address, style: const TextStyle(fontSize: 14))),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description
                      const Text('Description', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SelectableText(incident.description, style: const TextStyle(fontSize: 14, height: 1.5)),
                      ),

                      // Niveau de dangerosité
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Dangerosité : ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getDangerColor(incident.dangerLevel).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getDangerLabel(incident.dangerLevel),
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12,
                                  color: _getDangerColor(incident.dangerLevel)),
                            ),
                          ),
                        ],
                      ),

                      // Médias
                      if (incident.mediaUrls.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Text('Médias', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const Spacer(),
                            Text('${incident.mediaUrls.length} fichier(s)',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${incident.mediaUrls.length} URL(s) média copiée(s)'),
                                    behavior: SnackBarBehavior.floating,
                                    action: SnackBarAction(
                                      label: 'Ouvrir',
                                      onPressed: () async {
                                        final uri = Uri.parse(incident.mediaUrls.first);
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                                        }
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: VigileTheme.primaryRed.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.download, size: 14, color: VigileTheme.primaryRed),
                                    SizedBox(width: 4),
                                    Text('Extraire', style: TextStyle(fontSize: 11,
                                        fontWeight: FontWeight.w600, color: VigileTheme.primaryRed)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: incident.mediaUrls.length,
                            itemBuilder: (_, i) => GestureDetector(
                              onLongPress: () {
                                // Copier l'URL du média
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('URL média ${i + 1} copiée'),
                                      behavior: SnackBarBehavior.floating),
                                );
                              },
                              child: Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CachedNetworkImage(
                                    imageUrl: incident.mediaUrls[i],
                                    fit: BoxFit.cover,
                                    errorWidget: (_, _, _) => Container(
                                      color: Colors.grey.shade300,
                                      child: const Icon(Icons.broken_image, color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],

                      // Source / Réseau social
                      if (incident.source != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.source, size: 14, color: Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(child: SelectableText('Source: ${incident.source!}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
                          ],
                        ),
                      ],
                      if (incident.socialMediaUrl != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.link, size: 14, color: Colors.blue),
                            const SizedBox(width: 6),
                            Expanded(child: SelectableText(incident.socialMediaUrl!,
                                style: const TextStyle(fontSize: 12, color: Colors.blue))),
                          ],
                        ),
                      ],

                      // Anonyme
                      const SizedBox(height: 16),
                      Text(incident.isAnonymous ? 'Signalement anonyme' : 'Signalement non-anonyme',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),

                      // Actions journaliste
                      if (canEdit) ...[
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await _service.verifyIncident(incident.id, widget.journalist.pseudo);
                                  _loadIncidents();
                                },
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('Valider'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: VigileTheme.safeGreen,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showRejectDialog(incident);
                                },
                                icon: const Icon(Icons.close, size: 16),
                                label: const Text('Rejeter'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getDangerColor(DangerLevel level) {
    switch (level) {
      case DangerLevel.vigilance: return Colors.green;
      case DangerLevel.risque: return const Color(0xFFFFD600);
      case DangerLevel.incident: return const Color(0xFFE65100);
      case DangerLevel.urgence: return const Color(0xFFB71C1C);
    }
  }

  String _getDangerLabel(DangerLevel level) {
    switch (level) {
      case DangerLevel.vigilance: return 'Vigilance';
      case DangerLevel.risque: return 'Risque';
      case DangerLevel.incident: return 'Incident';
      case DangerLevel.urgence: return 'Urgence';
    }
  }

  // ── Profil ──
  Widget _buildProfile(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text('Mon Profil',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87)),
                ),
                const SizedBox(width: 8),
                if (!_isDesktop(context))
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MapScreen()),
                    ),
                    icon: const Icon(Icons.map, size: 16),
                    label: const Text('Carte', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VigileTheme.primaryRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Header card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? VigileTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: VigileTheme.primaryRed,
                    child: Text(
                      widget.journalist.pseudo.isNotEmpty
                          ? widget.journalist.pseudo[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _profileField('Pseudo (signature)',
                            _pseudoController, Icons.badge, isDark),
                        const SizedBox(height: 12),
                        _profileField(
                            'Bio', _bioController, Icons.info_outline, isDark,
                            maxLines: 2),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Téléphone ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? VigileTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone,
                      color: VigileTheme.primaryRed, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Téléphone',
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white38
                                    : Colors.black38)),
                        Text(widget.journalist.phoneNumber,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white
                                    : Colors.black87)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Déconnectez-vous et reconnectez-vous avec le nouveau numéro'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Text('Changer',
                        style: TextStyle(
                            color: VigileTheme.primaryRed, fontSize: 13)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Réseaux sociaux ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? VigileTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Réseaux sociaux',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black54)),
                  const SizedBox(height: 16),
                  _profileField('Instagram', _instagramController,
                      Icons.camera_alt, isDark,
                      hint: '@votre_compte'),
                  const SizedBox(height: 12),
                  _profileField('X (Twitter)', _twitterController,
                      Icons.alternate_email, isDark,
                      hint: '@votre_compte'),
                  const SizedBox(height: 12),
                  _profileField(
                      'LinkedIn', _linkedinController, Icons.work, isDark,
                      hint: 'URL de votre profil'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Abonnement ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.journalist.hasValidSubscription
                    ? VigileTheme.safeGreen.withValues(alpha: 0.1)
                    : VigileTheme.warningYellow.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.journalist.hasValidSubscription
                      ? VigileTheme.safeGreen.withValues(alpha: 0.3)
                      : VigileTheme.warningYellow.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.journalist.hasValidSubscription
                        ? Icons.check_circle
                        : Icons.warning,
                    color: widget.journalist.hasValidSubscription
                        ? VigileTheme.safeGreen
                        : VigileTheme.warningYellow,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.journalist.hasValidSubscription
                              ? 'Abonnement actif'
                              : 'Abonnement inactif',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          widget.journalist.hasValidSubscription
                              ? 'Expire le ${DateFormat('dd/MM/yyyy').format(widget.journalist.subscriptionExpiry!)}'
                              : '200€/an — Contactez l\'administrateur pour activer',
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white38
                                  : Colors.black38),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Save button ──
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saveProfile,
                icon: const Icon(Icons.save, size: 20),
                label: const Text('Sauvegarder',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),

            const SizedBox(height: 32),

            // ── Delete account ──
            Center(
              child: TextButton.icon(
                onPressed: _deleteAccount,
                icon:
                    const Icon(Icons.delete_forever, color: Colors.red, size: 18),
                label: const Text('Supprimer mon compte',
                    style: TextStyle(color: Colors.red, fontSize: 13)),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _profileField(String label, TextEditingController controller,
      IconData icon, bool isDark,
      {int maxLines = 1, String? hint}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: VigileTheme.primaryRed, size: 20),
        filled: true,
        fillColor: isDark
            ? VigileTheme.darkSurface
            : VigileTheme.lightBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: VigileTheme.primaryRed, width: 2),
        ),
      ),
    );
  }

  Color _getTypeColor(IncidentType type) {
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

  // ── Person Card ──
  Widget _buildPersonCard(ConvictedPerson person, DateFormat dateFormat,
      bool isDark, bool showActions) {
    return GestureDetector(
      onTap: () => showActions ? _showVerifyPersonDialog(person) : null,
      child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? VigileTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: VigileTheme.primaryRed.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: VigileTheme.primaryRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person, size: 14, color: VigileTheme.primaryRed),
                    SizedBox(width: 4),
                    Text('Individu',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: VigileTheme.primaryRed)),
                  ],
                ),
              ),
              if (person.status == PersonStatus.verified) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: VigileTheme.safeGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Vérifié',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: VigileTheme.safeGreen)),
                ),
              ],
              if (person.status == PersonStatus.rejected) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Rejeté',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600, color: Colors.red)),
                ),
              ],
              const Spacer(),
              Text(dateFormat.format(person.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
          const SizedBox(height: 12),

          // Nom
          Text(person.fullName.toUpperCase(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),

          // Faits
          Text(person.facts,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4)),

          if (person.convictionDate != null) ...[
            const SizedBox(height: 6),
            Text('Condamné le ${DateFormat('dd/MM/yyyy').format(person.convictionDate!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],

          if (person.address != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(person.address!,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ),
              ],
            ),
          ],

          // Médias
          if (person.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: person.mediaUrls.length,
                itemBuilder: (_, i) => Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: person.mediaUrls[i],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Réseaux sociaux
          if (person.instagram != null || person.twitter != null || person.linkedin != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                if (person.instagram != null)
                  Chip(
                    avatar: const Icon(Icons.camera_alt, size: 14),
                    label: Text(person.instagram!, style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                  ),
                if (person.twitter != null)
                  Chip(
                    avatar: const Icon(Icons.alternate_email, size: 14),
                    label: Text(person.twitter!, style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                  ),
                if (person.linkedin != null)
                  Chip(
                    avatar: const Icon(Icons.work, size: 14),
                    label: Text(person.linkedin!, style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],

          // Actions journaliste
          if (showActions) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showVerifyPersonDialog(person),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Valider'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VigileTheme.safeGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectPersonDialog(person),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Rejeter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Raison du rejet
          if (person.rejectionReason != null && person.status == PersonStatus.rejected) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Colors.red),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Rejeté: ${person.rejectionReason}',
                        style: const TextStyle(fontSize: 12, color: Colors.red)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
    );
  }

  void _showVerifyPersonDialog(ConvictedPerson person) {
    final firstNameC = TextEditingController(text: person.firstName);
    final lastNameC = TextEditingController(text: person.lastName);
    final factsC = TextEditingController(text: person.facts);
    final addressC = TextEditingController(text: person.address ?? '');
    final instagramC = TextEditingController(text: person.instagram ?? '');
    final twitterC = TextEditingController(text: person.twitter ?? '');
    final linkedinC = TextEditingController(text: person.linkedin ?? '');
    bool showAddress = person.address != null;
    bool showSocial = person.instagram != null || person.twitter != null || person.linkedin != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: VigileTheme.safeGreen.withValues(alpha: 0.1),
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit_note, color: VigileTheme.safeGreen),
                      const SizedBox(width: 8),
                      const Text('Vérifier et modifier', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, size: 20)),
                    ],
                  ),
                ),
                // Formulaire scrollable
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(child: TextField(controller: lastNameC, decoration: const InputDecoration(labelText: 'Nom', border: OutlineInputBorder(), isDense: true))),
                          const SizedBox(width: 10),
                          Expanded(child: TextField(controller: firstNameC, decoration: const InputDecoration(labelText: 'Prénom', border: OutlineInputBorder(), isDense: true))),
                        ]),
                        const SizedBox(height: 12),
                        TextField(controller: factsC, decoration: const InputDecoration(labelText: 'Faits', border: OutlineInputBorder(), isDense: true, alignLabelWithHint: true), maxLines: 4),
                        const SizedBox(height: 12),
                        TextField(controller: addressC, decoration: const InputDecoration(labelText: 'Adresse', border: OutlineInputBorder(), isDense: true)),
                        const SizedBox(height: 12),
                        TextField(controller: instagramC, decoration: const InputDecoration(labelText: 'Instagram', border: OutlineInputBorder(), isDense: true)),
                        const SizedBox(height: 8),
                        TextField(controller: twitterC, decoration: const InputDecoration(labelText: 'X (Twitter)', border: OutlineInputBorder(), isDense: true)),
                        const SizedBox(height: 8),
                        TextField(controller: linkedinC, decoration: const InputDecoration(labelText: 'LinkedIn', border: OutlineInputBorder(), isDense: true)),
                        const SizedBox(height: 16),
                        const Text('Visibilité publique :', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        CheckboxListTile(
                          title: const Text('Afficher l\'adresse', style: TextStyle(fontSize: 13)),
                          value: showAddress,
                          onChanged: (v) => setDialogState(() => showAddress = v!),
                          activeColor: VigileTheme.primaryRed,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                        CheckboxListTile(
                          title: const Text('Afficher les réseaux sociaux', style: TextStyle(fontSize: 13)),
                          value: showSocial,
                          onChanged: (v) => setDialogState(() => showSocial = v!),
                          activeColor: VigileTheme.primaryRed,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            // Mettre à jour les infos modifiées + valider
                            final updates = <String, dynamic>{
                              'firstName': firstNameC.text.trim(),
                              'lastName': lastNameC.text.trim(),
                              'facts': factsC.text.trim(),
                              'address': addressC.text.trim().isEmpty ? null : addressC.text.trim(),
                              'instagram': instagramC.text.trim().isEmpty ? null : instagramC.text.trim(),
                              'twitter': twitterC.text.trim().isEmpty ? null : twitterC.text.trim(),
                              'linkedin': linkedinC.text.trim().isEmpty ? null : linkedinC.text.trim(),
                            };
                            // D'abord update les infos
                            await _service.updatePersonInfo(person.id, updates);
                            // Puis valider
                            await _service.verifyPerson(
                              personId: person.id,
                              pseudo: widget.journalist.pseudo,
                              showAddress: showAddress,
                              showSocialMedia: showSocial,
                            );
                            _loadIncidents();
                          },
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Valider'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VigileTheme.safeGreen,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRejectPersonDialog(ConvictedPerson person) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter cet individu'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Raison du rejet',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _service.rejectPerson(
                person.id,
                widget.journalist.pseudo,
                reasonController.text.trim(),
              );
              _loadIncidents();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }
}
