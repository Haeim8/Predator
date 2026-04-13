import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../models/convicted_person.dart';
import '../models/journalist.dart';
import '../services/firestore_service.dart';


class PersonsListSheet extends StatefulWidget {
  const PersonsListSheet({super.key});

  @override
  State<PersonsListSheet> createState() => _PersonsListSheetState();
}

class _PersonsListSheetState extends State<PersonsListSheet> {
  final _searchController = TextEditingController();
  final _service = FirestoreService();
  List<ConvictedPerson> _persons = [];
  List<ConvictedPerson> _filtered = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPersons();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPersons() async {
    try {
      final persons = await _service.getVerifiedPersons();
      if (!mounted) return;
      setState(() {
        _persons = persons;
        _filtered = persons;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearch(String query) {
    final q = query.toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = _persons;
      } else {
        _filtered = _persons
            .where((p) =>
                p.firstName.toLowerCase().contains(q) ||
                p.lastName.toLowerCase().contains(q))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? VigileTheme.darkSurface : Colors.white;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: VigileTheme.primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.person_search,
                      color: VigileTheme.primaryRed, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Individus signalés',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      Text('${_persons.length} personne(s) vérifiée(s)',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou prénom...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),

          // List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: VigileTheme.primaryRed))
                : _error != null
                    ? Center(
                        child: Text('Erreur: $_error',
                            style: const TextStyle(color: Colors.red)))
                    : _filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_off,
                                    size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  _searchController.text.isNotEmpty
                                      ? 'Aucun résultat pour "${_searchController.text}"'
                                      : 'Aucun individu signalé',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final person = _filtered[index];
                              return _PersonCard(
                                person: person,
                                onTap: () => _showPersonDetail(person),
                              );
                            },
                          ),
          ),
        ],
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
}

Widget _buildAvatar(ConvictedPerson person, double radius) {
  if (person.mediaUrls.isNotEmpty) {
    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: CachedNetworkImage(
          imageUrl: person.mediaUrls.first,
          fit: BoxFit.cover,
          placeholder: (_, _) => CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey.shade300,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          errorWidget: (_, _, _) => CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey.shade300,
            child: const Icon(Icons.person, color: Colors.white),
          ),
        ),
      ),
    );
  }
  return CircleAvatar(
    radius: radius,
    backgroundColor: Colors.grey.shade300,
    child: const Icon(Icons.person, color: Colors.white),
  );
}

// ── Card ──

class _PersonCard extends StatelessWidget {
  final ConvictedPerson person;
  final VoidCallback onTap;

  const _PersonCard({required this.person, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: VigileTheme.primaryRed.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            _buildAvatar(person, 24),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.fullName.toUpperCase(),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    person.facts,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  if (person.convictionDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Condamné le ${DateFormat('dd/MM/yyyy').format(person.convictionDate!)}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// ── Detail Sheet ──

class PersonDetailPublicSheet extends StatefulWidget {
  final ConvictedPerson person;

  const PersonDetailPublicSheet({super.key, required this.person});

  @override
  State<PersonDetailPublicSheet> createState() => _PersonDetailPublicSheetState();
}

class _PersonDetailPublicSheetState extends State<PersonDetailPublicSheet> {
  Journalist? _journalist;

  @override
  void initState() {
    super.initState();
    _loadJournalist();
  }

  Future<void> _loadJournalist() async {
    if (widget.person.verifiedBy == null) return;
    try {
      final db = FirestoreService();
      final journalists = await db.getJournalistByPseudo(widget.person.verifiedBy!);
      if (journalists != null && mounted) {
        setState(() => _journalist = journalists);
      }
    } catch (_) {}
  }

  Future<void> _openUrl(String url) async {
    String fullUrl = url;
    if (!url.startsWith('http')) fullUrl = 'https://$url';
    final uri = Uri.parse(fullUrl);
    if (!uri.scheme.startsWith('http')) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? VigileTheme.darkSurface : Colors.white;
    final person = widget.person;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Row(
                  children: [
                    _buildAvatar(person, 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(person.fullName.toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: VigileTheme.safeGreen
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified, size: 14,
                                    color: VigileTheme.safeGreen),
                                const SizedBox(width: 4),
                                Text(
                                  'Vérifié par ${person.verifiedBy ?? ""}',
                                  style: TextStyle(fontSize: 11,
                                      color: VigileTheme.safeGreen),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Faits
                _section('Faits', Icons.gavel, person.facts),

                // Date
                if (person.convictionDate != null)
                  _section('Date de condamnation', Icons.calendar_today,
                      DateFormat('dd/MM/yyyy').format(person.convictionDate!)),

                // Zone géographique (ville uniquement)
                if (person.showAddress && person.address != null)
                  _section('Zone géographique', Icons.location_city,
                      _getCityOnly(person.address!)),

                // Médias
                if (person.mediaUrls.length > 1) ...[
                  const SizedBox(height: 8),
                  const Text('Preuves',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: person.mediaUrls.length,
                      itemBuilder: (_, i) => Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: person.mediaUrls[i],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                // Réseaux sociaux de l'individu
                if (person.showSocialMedia &&
                    (person.instagram != null ||
                        person.twitter != null ||
                        person.linkedin != null)) ...[
                  const SizedBox(height: 16),
                  const Text('Réseaux sociaux',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  if (person.instagram != null)
                    _socialTile(Icons.camera_alt, person.instagram!),
                  if (person.twitter != null)
                    _socialTile(Icons.alternate_email, person.twitter!),
                  if (person.linkedin != null)
                    _socialTile(Icons.work, person.linkedin!),
                ],

                const SizedBox(height: 20),

                // Fiche du journaliste vérificateur
                _buildJournalistCard(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJournalistCard(bool isDark) {
    if (_journalist == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: VigileTheme.safeGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VigileTheme.safeGreen.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.verified_user, color: VigileTheme.safeGreen, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Vérifié par ${widget.person.verifiedBy ?? "un journaliste"}',
                style: TextStyle(fontSize: 13, color: VigileTheme.safeGreen),
              ),
            ),
          ],
        ),
      );
    }

    final j = _journalist!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VigileTheme.safeGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, color: VigileTheme.safeGreen, size: 18),
              const SizedBox(width: 8),
              const Text('Vérifié par',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: VigileTheme.primaryRed.withValues(alpha: 0.15),
                child: Text(
                  j.pseudo.isNotEmpty ? j.pseudo[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: VigileTheme.primaryRed,
                      fontWeight: FontWeight.w700,
                      fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(j.pseudo,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    if (j.bio.isNotEmpty)
                      Text(j.bio,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          if (j.instagram != null || j.twitter != null || j.linkedin != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (j.instagram != null)
                  _journalistSocialButton(Icons.camera_alt, 'https://instagram.com/${j.instagram}'),
                if (j.twitter != null)
                  _journalistSocialButton(Icons.alternate_email, 'https://x.com/${j.twitter}'),
                if (j.linkedin != null)
                  _journalistSocialButton(Icons.work, 'https://linkedin.com/in/${j.linkedin}'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _journalistSocialButton(IconData icon, String url) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => _openUrl(url),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: VigileTheme.primaryRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: VigileTheme.primaryRed),
        ),
      ),
    );
  }

  Widget _section(String title, IconData icon, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: VigileTheme.primaryRed),
              const SizedBox(width: 6),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  Widget _socialTile(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: VigileTheme.primaryRed),
          const SizedBox(width: 10),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  String _getCityOnly(String address) {
    final parts = address.split(',').map((s) => s.trim()).toList();
    if (parts.length >= 2) {
      return parts.sublist(parts.length - 2).join(', ');
    }
    return address;
  }
}
