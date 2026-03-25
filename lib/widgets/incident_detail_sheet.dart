import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:predator/l10n/app_localizations.dart';
import '../core/theme.dart';
import '../models/incident.dart';

class IncidentDetailSheet extends StatelessWidget {
  final Incident incident;

  const IncidentDetailSheet({super.key, required this.incident});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.55,
      ),
      decoration: BoxDecoration(
        color: isDark ? PredatorTheme.darkSurface : Colors.white,
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
                          color: PredatorTheme.safeGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              size: 14,
                              color: PredatorTheme.safeGreen,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.verified,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: PredatorTheme.safeGreen,
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
                          ? PredatorTheme.darkCard
                          : PredatorTheme.lightBg,
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

                  // Source if available
                  if (incident.source != null &&
                      incident.source!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _infoRow(
                      Icons.link,
                      incident.source!,
                      isDark,
                    ).animate().fadeIn(delay: 500.ms, duration: 300.ms),
                  ],

                  const SizedBox(height: 24),

                  // Warning disclaimer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PredatorTheme.warningYellow
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: PredatorTheme.warningYellow
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: PredatorTheme.warningYellow,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Information verified by the moderation team. '
                            'No personal data is disclosed.',
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

  Widget _infoRow(IconData icon, String text, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: PredatorTheme.primaryRed,
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
    }
  }
}
