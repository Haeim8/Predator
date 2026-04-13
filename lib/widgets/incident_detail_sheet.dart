import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:predator/l10n/app_localizations.dart';
import '../core/theme.dart';
import '../models/incident.dart';

class IncidentDetailSheet extends StatelessWidget {
  final Incident incident;

  const IncidentDetailSheet({super.key, required this.incident});

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
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: isDark ? VigileTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with type badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getTypeColor(incident.type)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getTypeIcon(incident.type),
                              size: 16,
                              color: _getTypeColor(incident.type),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getTypeText(incident.type, l10n),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _getTypeColor(incident.type),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: VigileTheme.safeGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              size: 14,
                              color: VigileTheme.safeGreen,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.verified,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: VigileTheme.safeGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: -0.1, end: 0),

                  const SizedBox(height: 20),

                  // Title
                  Text(
                    l10n.incidentDetails,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

                  const SizedBox(height: 16),

                  // Location
                  _infoRow(
                    Icons.location_on_outlined,
                    incident.address,
                    isDark,
                  ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

                  const SizedBox(height: 12),

                  // Date
                  _infoRow(
                    Icons.calendar_today_outlined,
                    '${l10n.reportedOn} ${dateFormat.format(incident.dateTime)}',
                    isDark,
                  ).animate().fadeIn(delay: 300.ms, duration: 300.ms),

                  const SizedBox(height: 20),

                  // Description
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? VigileTheme.darkCard
                          : VigileTheme.lightBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      incident.description,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 300.ms),

                  // ── Médias ──
                  if (incident.mediaUrls.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Preuves',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 180,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: incident.mediaUrls.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final url = incident.mediaUrls[index];
                          final isVideo = url.contains('.mp4') ||
                              url.contains('.mov') ||
                              url.contains('.avi');

                          if (isVideo) {
                            return GestureDetector(
                              onTap: () => _openUrl(url),
                              child: Container(
                                width: 180,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? VigileTheme.darkCard
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.play_circle_filled,
                                          color: VigileTheme.primaryRed,
                                          size: 48),
                                      SizedBox(height: 8),
                                      Text('Voir la vidéo',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          return GestureDetector(
                            onTap: () => _showFullImage(context, url),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: url,
                                width: 180,
                                height: 180,
                                fit: BoxFit.cover,
                                placeholder: (_, _) => Container(
                                  width: 180,
                                  color: isDark
                                      ? VigileTheme.darkCard
                                      : Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: VigileTheme.primaryRed,
                                    ),
                                  ),
                                ),
                                errorWidget: (_, _, _) => Container(
                                  width: 180,
                                  color: isDark
                                      ? VigileTheme.darkCard
                                      : Colors.grey[200],
                                  child: const Icon(Icons.broken_image,
                                      color: Colors.grey),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ).animate().fadeIn(delay: 450.ms, duration: 300.ms),
                  ],

                  // ── Lien réseau social ──
                  if (incident.socialMediaUrl != null &&
                      incident.socialMediaUrl!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => _openUrl(incident.socialMediaUrl!),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.share,
                                color: Colors.blue, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Source originale',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    incident.socialMediaUrl!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black45,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.open_in_new,
                                color: Colors.blue, size: 18),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 500.ms, duration: 300.ms),
                  ],

                  // Source if available
                  if (incident.source != null &&
                      incident.source!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _infoRow(
                      Icons.link,
                      incident.source!,
                      isDark,
                    ).animate().fadeIn(delay: 550.ms, duration: 300.ms),
                  ],

                  const SizedBox(height: 24),

                  // Warning disclaimer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: VigileTheme.warningYellow
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: VigileTheme.warningYellow
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: VigileTheme.warningYellow,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Information vérifiée par l\'équipe de modération. '
                            'Aucune donnée personnelle n\'est divulguée.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 600.ms, duration: 300.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: VigileTheme.primaryRed,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
      ],
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

  IconData _getTypeIcon(IncidentType type) {
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

  String _getTypeText(IncidentType type, AppLocalizations l10n) {
    switch (type) {
      case IncidentType.sexualAssault:
        return l10n.sexualAssault;
      case IncidentType.harassment:
        return l10n.harassment;
      case IncidentType.violence:
        return l10n.violence;
      case IncidentType.other:
        return l10n.other;
      case IncidentType.individual:
        return 'Individu';
    }
  }
}
