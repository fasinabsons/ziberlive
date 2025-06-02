import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  BannerAd? bannerAd;
  InterstitialAd? _interstitialAd;
  bool isPremium = false;

  void initialize() {
    MobileAds.instance.initialize();
  }

  void setPremium(bool value) {
    isPremium = value;
  }

  void loadBannerAd() {
    if (isPremium) return;
    bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx', // Replace with your AdMob unit ID
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(),
    )..load();
  }

  void loadInterstitialAd() {
    if (isPremium) return;
    InterstitialAd.load(
      adUnitId: '<YOUR_AD_UNIT_ID>',
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) => _interstitialAd = null,
      ),
    );
  }

  void showInterstitialAd() {
    if (isPremium) return;
    _interstitialAd?.show();
  }
}
