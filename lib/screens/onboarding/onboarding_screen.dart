import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/theme.dart';
import '../../services/cache_service.dart';
import '../map/map_screen.dart';
import 'package:predator/l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > 800;

  void _showTermsDialog() {
    final l10n = AppLocalizations.of(context)!;
    final isWide = _isDesktop(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: isWide
            ? const EdgeInsets.symmetric(horizontal: 200, vertical: 60)
            : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        title: Row(
          children: [
            const Icon(Icons.gavel, color: PredatorTheme.primaryRed),
            const SizedBox(width: 12),
            Text(l10n.termsTitle,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: SizedBox(
          width: isWide ? 500 : double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              l10n.termsContent,
              style: TextStyle(
                fontSize: isWide ? 15 : 14,
                height: 1.6,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.iDecline,
                style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final cacheService = CacheService();
              await cacheService.init();
              await cacheService.setOnboardingComplete();
              await cacheService.setTermsAccepted();
              if (!ctx.mounted) return;
              final nav = Navigator.of(ctx);
              nav.pop();
              nav.pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (c1, a1, a2) => const MapScreen(),
                  transitionsBuilder: (c2, animation, a3, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 600),
                ),
              );
            },
            child: Text(l10n.iAccept),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = _isDesktop(context);

    final pages = [
      _OnboardingPageData(
        icon: Icons.shield_outlined,
        title: l10n.onboardingTitle1,
        description: l10n.onboardingDesc1,
        features: [
          _FeatureItem(Icons.money_off, l10n.freeApp),
          _FeatureItem(Icons.groups, l10n.communityDriven),
          _FeatureItem(Icons.access_time_filled, l10n.alwaysAvailable),
        ],
        showParticipateVisual: false,
      ),
      _OnboardingPageData(
        icon: Icons.people_outline,
        title: l10n.onboardingTitle2,
        description: l10n.onboardingDesc2,
        features: const [],
        showParticipateVisual: true,
      ),
    ];

    if (isDesktop) {
      return _buildDesktopLayout(l10n, isDark, pages);
    }
    return _buildMobileLayout(l10n, isDark, pages);
  }

  // ─── DESKTOP: split layout (left brand panel + right content) ───
  Widget _buildDesktopLayout(
      AppLocalizations l10n, bool isDark, List<_OnboardingPageData> pages) {
    return Scaffold(
      body: Row(
        children: [
          // Left panel - brand
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    PredatorTheme.darkRed,
                    PredatorTheme.primaryRed.withValues(alpha: 0.8),
                    const Color(0xFF1A0000),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 2),
                      ),
                      child: const Icon(Icons.remove_red_eye_outlined,
                          size: 70, color: Colors.white),
                    )
                        .animate()
                        .scale(
                            begin: const Offset(0.6, 0.6),
                            duration: 800.ms,
                            curve: Curves.elasticOut)
                        .then()
                        .shimmer(duration: 1500.ms, color: Colors.white24),
                    const SizedBox(height: 36),
                    const Text(
                      'PREDATOR',
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 14,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
                    const SizedBox(height: 8),
                    Text(
                      'COMMUNITY SAFETY',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 8,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
                    const SizedBox(height: 48),
                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _statBadge('10+', 'Villes'),
                        const SizedBox(width: 32),
                        _statBadge('100%', 'Anonyme'),
                        const SizedBox(width: 32),
                        _statBadge('24/7', 'Actif'),
                      ],
                    ).animate().fadeIn(delay: 700.ms, duration: 500.ms),
                  ],
                ),
              ),
            ),
          ),

          // Right panel - content
          Expanded(
            flex: 5,
            child: Container(
              color: isDark ? PredatorTheme.darkBg : Colors.white,
              child: SafeArea(
                child: Column(
                  children: [
                    // Skip
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: TextButton(
                          onPressed: _showTermsDialog,
                          child: Text(l10n.skip,
                              style: TextStyle(
                                  color:
                                      isDark ? Colors.white54 : Colors.black45,
                                  fontSize: 15)),
                        ),
                      ),
                    ),
                    // Pages
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (i) =>
                            setState(() => _currentPage = i),
                        children: pages
                            .map((p) => _OnboardingPage(
                                data: p, isDark: isDark, isDesktop: true))
                            .toList(),
                      ),
                    ),
                    // Bottom controls
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 60, vertical: 32),
                      child: Column(
                        children: [
                          SmoothPageIndicator(
                            controller: _pageController,
                            count: pages.length,
                            effect: WormEffect(
                              dotHeight: 10,
                              dotWidth: 10,
                              activeDotColor: PredatorTheme.primaryRed,
                              dotColor:
                                  isDark ? Colors.white24 : Colors.black12,
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: 360,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_currentPage < pages.length - 1) {
                                  _pageController.nextPage(
                                    duration:
                                        const Duration(milliseconds: 400),
                                    curve: Curves.easeInOut,
                                  );
                                } else {
                                  _showTermsDialog();
                                }
                              },
                              child: Text(
                                _currentPage < pages.length - 1
                                    ? l10n.next
                                    : l10n.acceptTerms,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600),
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
        ],
      ),
    );
  }

  Widget _statBadge(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.5))),
      ],
    );
  }

  // ─── MOBILE: classic vertical layout ───
  Widget _buildMobileLayout(
      AppLocalizations l10n, bool isDark, List<_OnboardingPageData> pages) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _showTermsDialog,
                  child: Text(l10n.skip,
                      style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black45,
                          fontSize: 16)),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: pages
                    .map((p) => _OnboardingPage(
                        data: p, isDark: isDark, isDesktop: false))
                    .toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: pages.length,
                    effect: WormEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      activeDotColor: PredatorTheme.primaryRed,
                      dotColor: isDark ? Colors.white24 : Colors.black12,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < pages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _showTermsDialog();
                        }
                      },
                      child: Text(
                        _currentPage < pages.length - 1
                            ? l10n.next
                            : l10n.acceptTerms,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String label;
  const _FeatureItem(this.icon, this.label);
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;
  final List<_FeatureItem> features;
  final bool showParticipateVisual;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
    required this.features,
    required this.showParticipateVisual,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;
  final bool isDark;
  final bool isDesktop;

  const _OnboardingPage({
    required this.data,
    required this.isDark,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final hPadding = isDesktop ? 60.0 : 32.0;
    final titleSize = isDesktop ? 36.0 : 28.0;
    final descSize = isDesktop ? 17.0 : 16.0;
    final iconContainerSize = isDesktop ? 120.0 : 100.0;
    final iconSize = isDesktop ? 60.0 : 50.0;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isDesktop) const SizedBox(height: 40),
          Container(
            width: iconContainerSize,
            height: iconContainerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: PredatorTheme.primaryRed.withValues(alpha: 0.1),
            ),
            child: Icon(data.icon,
                size: iconSize, color: PredatorTheme.primaryRed),
          )
              .animate()
              .scale(
                  begin: const Offset(0.8, 0.8),
                  duration: 600.ms,
                  curve: Curves.elasticOut)
              .fadeIn(duration: 400.ms),
          const SizedBox(height: 40),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 480 : 400),
            child: Text(
              data.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: descSize,
                height: 1.5,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          if (data.features.isNotEmpty) ...[
            const SizedBox(height: 40),
            if (isDesktop)
              // Desktop: horizontal feature row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: data.features.asMap().entries.map((entry) {
                  final index = entry.key;
                  final feature = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _featureCard(feature, isDark),
                  )
                      .animate()
                      .fadeIn(
                          delay: (600 + index * 150).ms, duration: 400.ms)
                      .slideY(begin: 0.2, end: 0);
                }).toList(),
              )
            else
              // Mobile: vertical list
              ...data.features.asMap().entries.map((entry) {
                final index = entry.key;
                final feature = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: PredatorTheme.primaryRed
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(feature.icon,
                            color: PredatorTheme.primaryRed, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        feature.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(
                        delay: (600 + index * 150).ms, duration: 400.ms)
                    .slideX(begin: 0.2, end: 0);
              }),
          ],
          if (data.showParticipateVisual) ...[
            const SizedBox(height: 40),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 500 : 400),
              child: Container(
                padding: EdgeInsets.all(isDesktop ? 32 : 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color:
                          PredatorTheme.primaryRed.withValues(alpha: 0.3)),
                ),
                child: isDesktop
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _stepColumn(Icons.edit_note, 'Signaler',
                              PredatorTheme.primaryRed, isDark),
                          Icon(Icons.arrow_forward,
                              color: isDark ? Colors.white24 : Colors.black12),
                          _stepColumn(Icons.verified_user, 'Vérifier',
                              PredatorTheme.accentOrange, isDark),
                          Icon(Icons.arrow_forward,
                              color: isDark ? Colors.white24 : Colors.black12),
                          _stepColumn(Icons.public, 'Publier',
                              PredatorTheme.safeGreen, isDark),
                        ],
                      )
                    : Column(
                        children: [
                          Icon(Icons.verified_user,
                              size: 40, color: PredatorTheme.safeGreen),
                          const SizedBox(height: 12),
                          Text(
                            '✓ Report → ✓ Team Verifies → ✓ Alert Published',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color:
                                  isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
              ),
            ).animate().fadeIn(delay: 600.ms, duration: 500.ms),
          ],
        ],
      ),
    );
  }

  Widget _featureCard(_FeatureItem feature, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: PredatorTheme.primaryRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: PredatorTheme.primaryRed.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(feature.icon, color: PredatorTheme.primaryRed, size: 28),
          const SizedBox(height: 10),
          Text(
            feature.label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepColumn(
      IconData icon, String label, Color color, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white60 : Colors.black54)),
      ],
    );
  }
}
