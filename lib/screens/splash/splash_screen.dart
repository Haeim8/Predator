import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../services/cache_service.dart';
import '../onboarding/onboarding_screen.dart';
import '../map/map_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;

    final cacheService = CacheService();
    await cacheService.init();

    if (!mounted) return;

    if (cacheService.isOnboardingComplete && cacheService.areTermsAccepted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, a1, a2) => const MapScreen(),
          transitionsBuilder: (_, animation, a3, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, a1, a2) => const OnboardingScreen(),
          transitionsBuilder: (_, animation, a3, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? PredatorTheme.darkBg : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo icon - eye/radar style
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    PredatorTheme.primaryRed,
                    PredatorTheme.darkRed,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: PredatorTheme.primaryRed.withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.remove_red_eye_outlined,
                size: 60,
                color: Colors.white,
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.0, 1.0),
                  duration: 800.ms,
                  curve: Curves.elasticOut,
                )
                .then()
                .shimmer(
                  duration: 1200.ms,
                  color: Colors.white24,
                ),
            const SizedBox(height: 32),
            // App name
            Text(
              'PREDATOR',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w700,
                letterSpacing: 12,
                color: isDark ? Colors.white : PredatorTheme.darkRed,
              ),
            )
                .animate()
                .fadeIn(delay: 400.ms, duration: 600.ms)
                .slideY(begin: 0.3, end: 0),
            const SizedBox(height: 8),
            Text(
              'COMMUNITY SAFETY',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 6,
                color: isDark
                    ? Colors.white54
                    : PredatorTheme.darkRed.withValues(alpha: 0.6),
              ),
            )
                .animate()
                .fadeIn(delay: 800.ms, duration: 600.ms),
            const SizedBox(height: 60),
            // Loading indicator
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  PredatorTheme.primaryRed.withValues(alpha: 0.6),
                ),
              ),
            ).animate().fadeIn(delay: 1200.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
