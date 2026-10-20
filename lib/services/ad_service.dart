import 'dart:io';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  static const String keyUserRewardedWatchCount = 'user_ad_watch_count';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  RewardedAd? _rewardedAd;
  bool _isRewardedLoading = false;
  bool get isRewardedAdReady => _rewardedAd != null;
  bool get isRewardedLoading => _isRewardedLoading;

  /// Official Google AdMob Test Ad Unit IDs
  /// Banner Test IDs:
  /// Android: ca-app-pub-3940256099942544/6300978111
  /// iOS: ca-app-pub-3940256099942544/2934735716
  static String get bannerAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    return '';
  }

  /// Rewarded Test IDs (Used ONLY in Help Us voluntary support tab)
  /// Android: ca-app-pub-3940256099942544/5224354917
  /// iOS: ca-app-pub-3940256099942544/1712485313
  static String get rewardedAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    }
    return '';
  }

  /// Initialize Mobile Ads SDK
  Future<void> initialize() async {
    if (kIsWeb) return;
    if (_isInitialized) return;

    try {
      final status = await MobileAds.instance.initialize();
      _isInitialized = true;
      log('Google Mobile Ads initialized successfully: ${status.adapterStatuses}');
      // Preload the first voluntary rewarded ad for the Help Us screen
      loadRewardedAd();
    } catch (e) {
      log('Error initializing Google Mobile Ads: $e');
    }
  }

  /// Preload a Rewarded Ad so it's ready when user wants to support
  void loadRewardedAd({VoidCallback? onLoaded, Function(LoadAdError)? onFailed}) {
    if (kIsWeb) return;
    if (_rewardedAd != null || _isRewardedLoading) {
      onLoaded?.call();
      return;
    }

    final adUnitId = rewardedAdUnitId;
    if (adUnitId.isEmpty) return;

    _isRewardedLoading = true;
    log('Loading voluntary Rewarded Ad...');

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          log('Rewarded Ad loaded successfully.');
          _rewardedAd = ad;
          _isRewardedLoading = false;
          onLoaded?.call();
        },
        onAdFailedToLoad: (LoadAdError error) {
          log('Rewarded Ad failed to load: ${error.message} (code: ${error.code})');
          _rewardedAd = null;
          _isRewardedLoading = false;
          onFailed?.call(error);
        },
      ),
    );
  }

  /// Show the voluntary Rewarded Ad to support the app
  Future<bool> showRewardedAd({
    required Function(RewardItem reward) onUserEarnedReward,
    VoidCallback? onAdDismissed,
    Function(String reason)? onAdFailedToShow,
  }) async {
    if (kIsWeb) {
      onAdFailedToShow?.call('Ads are not supported on this platform.');
      return false;
    }

    if (_rewardedAd == null) {
      // Try to load and notify caller
      loadRewardedAd(
        onFailed: (error) => onAdFailedToShow?.call('Failed to load ad: ${error.message}'),
      );
      onAdFailedToShow?.call('Ad is still preparing. Please try again in a moment!');
      return false;
    }

    final ad = _rewardedAd!;
    bool userEarnedReward = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        log('Rewarded Ad showed full screen.');
      },
      onAdDismissedFullScreenContent: (ad) {
        log('Rewarded Ad dismissed.');
        ad.dispose();
        _rewardedAd = null;
        // Automatically preload next ad so user can support again anytime
        loadRewardedAd();
        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, AdError error) {
        log('Rewarded Ad failed to show: ${error.message}');
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        onAdFailedToShow?.call(error.message);
      },
    );

    await ad.show(
      onUserEarnedReward: (AdWithoutView adWithoutView, RewardItem reward) async {
        log('User earned reward: ${reward.amount} ${reward.type}');
        userEarnedReward = true;
        await incrementAdWatchCount();
        onUserEarnedReward(reward);
      },
    );

    return userEarnedReward;
  }

  /// Get locally stored ad watch count from SharedPreferences
  Future<int> getAdWatchCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(keyUserRewardedWatchCount) ?? 0;
    } catch (e) {
      log('Error reading ad watch count: $e');
      return 0;
    }
  }

  /// Increment locally stored ad watch count
  Future<int> incrementAdWatchCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(keyUserRewardedWatchCount) ?? 0;
      final updated = current + 1;
      await prefs.setInt(keyUserRewardedWatchCount, updated);
      return updated;
    } catch (e) {
      log('Error saving ad watch count: $e');
      return 0;
    }
  }
}
