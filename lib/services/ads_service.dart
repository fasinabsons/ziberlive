import 'dart:async';
import 'package:flutter_unity_ads/flutter_unity_ads.dart'; // Unity Ads
import 'package:google_mobile_ads/google_mobile_ads.dart'; // AdMob
import 'package:ziberlive/providers/app_state_provider.dart'; // For granting rewards
import 'package:ziberlive/config.dart'; // For reward constants

// Define a generic AdReward item (can be kept or removed if AppStateProvider handles all rewards)
class AdReward {
  final String adNetwork;
  final num amount; // Generic amount, specific points determined by constants
  final String type; // Generic type, specific points determined by constants

  AdReward({required this.adNetwork, required this.amount, required this.type});
}

// Enum to help manage ad state for different providers
enum AdLoadState { notLoaded, loading, loaded, failed }

enum AdNetwork { adMob, unityAds }

class AdsService {
  BannerAd? bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _admobRewardedAd;
  AdLoadState _unityRewardedAdState = AdLoadState.notLoaded;
  AdNetwork? _lastShownRewardedNetwork; // For alternating logic

  // bool isPremium = false; // Replaced by a getter accessing AppStateProvider
  AppStateProvider? _appStateProvider; // To grant rewards and get premium status

  // Getter for premium status, dynamically fetched from AppStateProvider
  bool get isPremium {
    return _appStateProvider?.isPremium ?? false;
  }

  // Method to set the AppStateProvider instance
  void setAppStateProvider(AppStateProvider provider) {
    _appStateProvider = provider;
  }

  // AdMob Ad Unit IDs - Replace with your actual IDs
  static const String _admobBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111'; // Test ID
  static const String _admobInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712'; // Test ID
  static const String _admobRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917'; // Test ID

  // Unity Ads Game ID and Placement IDs - Replace with your actual IDs
  static const String _unityGameIdAndroid = 'YOUR_UNITY_GAME_ID_ANDROID';
  static const String _unityGameIdIOS = 'YOUR_UNITY_GAME_ID_IOS';
  static const String _unityRewardedPlacementId = 'rewardedVideo'; // Default placement

  // StreamControllers for rewarded ad events
  final StreamController<AdReward> _onRewardEarnedController = StreamController<AdReward>.broadcast();
  Stream<AdReward> get onRewardEarned => _onRewardEarnedController.stream;

  final StreamController<String> _onRewardedAdLoadedController = StreamController<String>.broadcast();
  Stream<String> get onRewardedAdLoaded => _onRewardedAdLoadedController.stream; // String is ad network name

  final StreamController<String> _onRewardedAdFailedToLoadController = StreamController<String>.broadcast();
  Stream<String> get onRewardedAdFailedToLoad => _onRewardedAdFailedToLoadController.stream; // String is ad network name

  final StreamController<String> _onRewardedAdDismissedController = StreamController<String>.broadcast();
  Stream<String> get onRewardedAdDismissed => _onRewardedAdDismissedController.stream; // String is ad network name


  Future<void> initialize() async {
    if (isPremium) return;

    // Initialize AdMob
    await MobileAds.instance.initialize();
    print("AdsService: AdMob Initialized.");

    // Initialize UnityAds
    // Determine platform for Game ID
    String gameId = _unityGameIdAndroid; // Default to Android
    if (TargetPlatform.iOS == true) { // Needs import 'package:flutter/foundation.dart';
        gameId = _unityGameIdIOS;
    }

    try {
      await UnityAds.init(
        gameId: gameId,
        testMode: true, // Set to false for production
        onComplete: () {
          print('AdsService: UnityAds Initialization Complete.');
          // Pre-load Unity Ad after initialization
          loadUnityRewardedAd();
        },
        onFailed: (error, message) =>
            print('AdsService: UnityAds Initialization Failed: $error $message'),
      );
    } catch (e) {
      print('AdsService: UnityAds Initialization exception: $e');
    }
  }

  // void setPremium(bool value) { // No longer needed, isPremium is a getter
  //   isPremium = value;
  // }

    // Removed the direct assignment to isPremium here. The getter handles it.
    // The logic to dispose/load ads based on premium status change
    // should ideally be triggered by AppStateProvider when its _isPremium changes,
    // or AdsService could listen to AppStateProvider.
    // For now, existing calls to initialize() or load methods when isPremium is false will work.
    // If AppStateProvider.isPremium becomes true, existing ad instances will be disposed by this logic.
    if (this.isPremium) { // Use the getter
      // Dispose ads if user becomes premium
      bannerAd?.dispose();
      bannerAd = null;
      _interstitialAd?.dispose();
      _interstitialAd = null;
      _admobRewardedAd?.dispose();
      _admobRewardedAd = null;
      // UnityAds doesn't have a direct "dispose" for loaded ads in the same way,
      // but we can stop trying to show them.
      _unityRewardedAdState = AdLoadState.notLoaded;
      print("AdsService: Ads disabled due to premium status.");
    } else {
      // User is not premium, try to load ads
      initialize(); // Re-initialize or just load ads
      loadBannerAd();
      loadInterstitialAd();
      loadAdMobRewardedAd();
      loadUnityRewardedAd();
    }
  }

  void loadBannerAd() {
    if (isPremium || bannerAd != null) return;
    print("AdsService: Loading AdMob Banner Ad...");
    bannerAd = BannerAd(
      adUnitId: _admobBannerAdUnitId,
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) => print('AdsService: AdMob Banner Ad loaded.'),
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('AdsService: AdMob Banner Ad failed to load: $error');
          ad.dispose();
          bannerAd = null; // Reset on failure
        },
      ),
    )..load();
  }

  void loadInterstitialAd() {
    if (isPremium || _interstitialAd != null) return;
    print("AdsService: Loading AdMob Interstitial Ad...");
    InterstitialAd.load(
      adUnitId: _admobInterstitialAdUnitId,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print('AdsService: AdMob Interstitial Ad loaded.');
          _interstitialAd = ad;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd(); // Preload next
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              print('AdsService: AdMob Interstitial failed to show: $error');
              loadInterstitialAd(); // Preload next
            }
          );
        },
        onAdFailedToLoad: (error) {
          print('AdsService: AdMob Interstitial Ad failed to load: $error');
          _interstitialAd = null; // Reset on failure
        }
      ),
    );
  }

  void showInterstitialAd() {
    if (isPremium) {
      print("AdsService: Not showing Interstitial Ad (Premium User).");
      return;
    }
    if (_interstitialAd == null) {
      print("AdsService: Interstitial Ad not loaded yet. Attempting to load.");
      loadInterstitialAd();
      return;
    }
    print("AdsService: Showing AdMob Interstitial Ad.");
    _interstitialAd?.show();
  }

  // --- Rewarded Ads Logic ---

  void loadAdMobRewardedAd() {
    if (isPremium || _admobRewardedAd != null) return;
    print("AdsService: Loading AdMob Rewarded Ad...");
    RewardedAd.load(
      adUnitId: _admobRewardedAdUnitId,
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          print('AdsService: AdMob Rewarded Ad loaded.');
          _admobRewardedAd = ad;
          _onRewardedAdLoadedController.add("AdMob");
          _admobRewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (RewardedAd ad) {
              print('AdsService: AdMob Rewarded Ad dismissed.');
              _onRewardedAdDismissedController.add("AdMob");
              ad.dispose();
              _admobRewardedAd = null;
              loadAdMobRewardedAd(); // Preload next
            },
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
              print('AdsService: AdMob Rewarded Ad failed to show: $error');
              ad.dispose();
              _admobRewardedAd = null;
              loadAdMobRewardedAd(); // Preload next
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('AdsService: AdMob Rewarded Ad failed to load: $error');
          _admobRewardedAd = null;
          _onRewardedAdFailedToLoadController.add("AdMob");
        },
      ),
    );
  }

  void loadUnityRewardedAd() async {
    if (isPremium || _unityRewardedAdState == AdLoadState.loading || _unityRewardedAdState == AdLoadState.loaded) {
      return;
    }
    print("AdsService: Loading Unity Rewarded Ad (Placement: $_unityRewardedPlacementId)...");
    _unityRewardedAdState = AdLoadState.loading;
    try {
      // The flutter_unity_ads plugin typically uses a listener approach.
      // Loading is often implicit with checking placement state or calling a load method.
      // We'll use `UnityAds.load()` if available, or rely on `isUnityPlacementReady` before showing.
      // For this example, let's assume a direct load call pattern or that init preloads.
      // We need to listen to events from UnityAds.
      // The `flutter_unity_ads` plugin might require setting up listeners globally or when showing.
      // For simplicity, we'll simulate a load and use a flag.

      // This is a common pattern: check if placement is ready.
      // Actual loading might be tied to `UnityAds.load()` or `UnityAds.showVideo()`.
      // The `flutter_unity_ads` documentation should be consulted for the exact API.
      // For now, we'll assume `UnityAds.load` is the way if explicit loading is needed.
      await UnityAds.load(
        placementId: _unityRewardedPlacementId,
        onComplete: (placementId) {
          print('AdsService: Unity Rewarded Ad ($placementId) Loaded.');
          _unityRewardedAdState = AdLoadState.loaded;
          _onRewardedAdLoadedController.add("UnityAds");
        },
        onFailed: (placementId, error, message) {
          print('AdsService: Unity Rewarded Ad ($placementId) Load Failed: $error $message');
          _unityRewardedAdState = AdLoadState.failed;
          _onRewardedAdFailedToLoadController.add("UnityAds");
        },
      );
    } catch (e) {
      print('AdsService: Unity Rewarded Ad load exception: $e');
      _unityRewardedAdState = AdLoadState.failed;
      _onRewardedAdFailedToLoadController.add("UnityAds");
    }
  }

  bool isAdMobRewardedAdReady() {
    return _admobRewardedAd != null;
  }

  bool isUnityRewardedAdReady() {
    // This depends on the plugin's API. Some use `UnityAds.isReady(placementId)`.
    // Or a successful load callback as handled by `_unityRewardedAdState`.
    return _unityRewardedAdState == AdLoadState.loaded;
  }

  void showRewardedAd({String? rewardContext}) { // Added rewardContext
    if (isPremium) {
      print("AdsService: Not showing Rewarded Ad (Premium User).");
      return;
    }
    print("AdsService: Request to show Rewarded Ad (Context: $rewardContext).");

    bool admobReady = isAdMobRewardedAdReady();
    bool unityReady = isUnityRewardedAdReady();

    AdNetwork? networkToShow;

    if (admobReady && unityReady) {
      // Both ready, alternate
      if (_lastShownRewardedNetwork == AdNetwork.adMob) {
        networkToShow = AdNetwork.unityAds;
      } else { // Includes null case (first time) or if last was Unity
        networkToShow = AdNetwork.adMob;
      }
    } else if (admobReady) {
      networkToShow = AdNetwork.adMob;
    } else if (unityReady) {
      networkToShow = AdNetwork.unityAds;
    }

    if (networkToShow == AdNetwork.adMob) {
      print("AdsService: Showing AdMob Rewarded Ad.");
      _admobRewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        print('AdsService: AdMob Reward! Amount: ${reward.amount}, Type: ${reward.type}');
        if (rewardContext == "SettingsAd") {
          _appStateProvider?.grantAdRewardPoints(
            coins: kRewardSettingsAdCoins,
            amazonCouponPoints: kRewardSettingsAdAmazonCouponPoints,
            payPalPoints: kRewardSettingsAdPayPalPoints,
          );
          _appStateProvider?.recordSettingsAdWatched(); // Record after successful settings ad
          print("AdsService: Settings Ad rewards granted via AdMob.");
        } else { // Default to Sync Ad rewards
          _appStateProvider?.grantAdRewardPoints(
            trustScorePoints: kRewardTrustScorePoints,
            communityTreePoints: kRewardCommunityTreePoints,
            incomePoolPoints: kRewardIncomePoolPoints,
            amazonCouponPoints: kRewardAmazonCouponPoints, // Note: Sync ads also give Amazon points in this setup
            payPalPoints: kRewardPayPalPoints,             // Note: Sync ads also give PayPal points
          );
          print("AdsService: Sync Ad rewards granted via AdMob.");
        }
        _onRewardEarnedController.add(AdReward(adNetwork: "AdMob", amount: reward.amount, type: reward.type));
      });
      _lastShownRewardedNetwork = AdNetwork.adMob;
    } else if (networkToShow == AdNetwork.unityAds) {
      print("AdsService: Showing UnityAds Rewarded Ad.");
      UnityAds.showVideo(
        placementId: _unityRewardedPlacementId,
        onComplete: (placementId) {
          print('AdsService: UnityAds Rewarded Ad ($placementId) shown and completed.');
          if (rewardContext == "SettingsAd") {
            _appStateProvider?.grantAdRewardPoints(
              coins: kRewardSettingsAdCoins,
              amazonCouponPoints: kRewardSettingsAdAmazonCouponPoints,
              payPalPoints: kRewardSettingsAdPayPalPoints,
            );
            _appStateProvider?.recordSettingsAdWatched(); // Record after successful settings ad
            print("AdsService: Settings Ad rewards granted via UnityAds.");
          } else { // Default to Sync Ad rewards
            _appStateProvider?.grantAdRewardPoints(
              trustScorePoints: kRewardTrustScorePoints,
              communityTreePoints: kRewardCommunityTreePoints,
              incomePoolPoints: kRewardIncomePoolPoints,
              amazonCouponPoints: kRewardAmazonCouponPoints,
              payPalPoints: kRewardPayPalPoints,
            );
            print("AdsService: Sync Ad rewards granted via UnityAds.");
          }
          _onRewardEarnedController.add(AdReward(adNetwork: "UnityAds", amount: 10, type: "default"));

          _unityRewardedAdState = AdLoadState.notLoaded;
          _onRewardedAdDismissedController.add("UnityAds");
          loadUnityRewardedAd();
        },
        onFailed: (placementId, error, message) {
          print('AdsService: UnityAds Rewarded Ad ($placementId) Failed to Show: $error $message');
          _unityRewardedAdState = AdLoadState.notLoaded;
          loadUnityRewardedAd();
        },
        onStart: (placementId) => print('AdsService: UnityAds Rewarded Ad ($placementId) Started.'),
        onClick: (placementId) => print('AdsService: UnityAds Rewarded Ad ($placementId) Clicked.'),
        onSkipped: (placementId) {
          print('AdsService: UnityAds Rewarded Ad ($placementId) Skipped.');
          _onRewardedAdDismissedController.add("UnityAds");
          _unityRewardedAdState = AdLoadState.notLoaded;
          loadUnityRewardedAd();
        }
      );
      _lastShownRewardedNetwork = AdNetwork.unityAds;
    } else {
      print("AdsService: No Rewarded Ad is currently available from any network. Attempting to load both.");
      if (!admobReady) loadAdMobRewardedAd();
      if (!unityReady && _unityRewardedAdState != AdLoadState.loading) { // Check not already loading for Unity
        loadUnityRewardedAd();
      }
    }
  }

  void dispose() {
    print("AdsService: Disposing AdsService resources.");
    bannerAd?.dispose();
    _interstitialAd?.dispose();
    _admobRewardedAd?.dispose();
    _onRewardEarnedController.close();
    _onRewardedAdLoadedController.close();
    _onRewardedAdFailedToLoadController.close();
    _onRewardedAdDismissedController.close();
    // UnityAds usually has a static `UnityAds.destroy()` or similar, but it's often not needed
    // unless you are completely stopping ads for the app session.
    // Individual ad objects are not typically "disposed" in Unity Ads Flutter plugins.
  }
}
