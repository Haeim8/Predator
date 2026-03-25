import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:predator/l10n/app_localizations.dart';
import '../core/theme.dart';

class LocationPermissionDialog extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  const LocationPermissionDialog({
    super.key,
    required this.onRetry,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? PredatorTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: PredatorTheme.primaryRed.withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.location_off,
                  size: 32, color: PredatorTheme.primaryRed),
            )
                .animate()
                .scale(
                    begin: const Offset(0.8, 0.8),
                    duration: 500.ms,
                    curve: Curves.elasticOut)
                .then()
                .shake(hz: 2, offset: const Offset(2, 0)),
            const SizedBox(height: 20),
            Text(
              l10n.locationPermissionTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 10),
            Text(
              l10n.locationPermissionDesc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 24),
            SizedBox(
              width: 240,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.location_on, size: 18),
                label: Text(
                  l10n.enableLocation,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 10),
            TextButton(
              onPressed: onOpenSettings,
              child: Text(
                l10n.openSettings,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black45,
                  fontSize: 13,
                ),
              ),
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }
}
