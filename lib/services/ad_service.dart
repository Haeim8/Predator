import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  BannerAd? bannerAd;
  bool isBannerReady = false;

  // Test Ad Unit IDs - replace with real ones for production
  static String get bannerAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Test
    } else {
      return 'ca-app-pub-3940256099942544/2934735716'; // Test
    }
  }

  Future<void> init() async {
    await MobileAds.instance.initialize();
  }

  void loadBannerAd({VoidCallback? onLoaded}) {
    bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          isBannerReady = true;
          onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner failed to load: $error');
          ad.dispose();
          isBannerReady = false;
        },
      ),
    );
    bannerAd!.load();
  }

  void dispose() {
    bannerAd?.dispose();
  }
}
