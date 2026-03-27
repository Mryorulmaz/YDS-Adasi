import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Reklam servisi – Banner, Interstitial, Rewarded. Gerçek yayında AdMob ID'leri güncelle.
class AdService {
  static final AdService _instance = AdService._();
  static AdService get instance => _instance;

  AdService._();

  // AdMob ID'leri – Android için test, iOS için gerçek ID'ler
  static String get _bannerUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/6300978111';
    // iOS Banner: YDS ADASI iOS Banner
    return 'ca-app-pub-6306264558109126/9689463079';
  }

  static String get _interstitialUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/1033173712';
    // iOS Interstitial
    return 'ca-app-pub-6306264558109126/4452284546';
  }

  static String get _rewardedUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/5224354917';
    // iOS Rewarded
    return 'ca-app-pub-6306264558109126/8451239302';
  }

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInterstitialReady = false;
  bool _isRewardedReady = false;

  /// Uygulama başlangıcında bir kez çağrılmalı
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    loadInterstitial();
    loadRewarded();
    if (kDebugMode) {
      debugPrint('AdService: Mobile Ads initialized (test mode)');
    }
  }

  /// Her 10 kelimede gösterilecek tam ekran reklam – önceden yükle
  Future<void> loadInterstitial() async {
    await InterstitialAd.load(
      adUnitId: _interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialReady = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialReady = false;
              loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (e) {
          _isInterstitialReady = false;
          if (kDebugMode) debugPrint('Interstitial load failed: $e');
        },
      ),
    );
  }

  /// Tam ekran reklamı göster; yoksa sessizce atla
  Future<void> showInterstitial() async {
    if (_interstitialAd != null && _isInterstitialReady) {
      await _interstitialAd!.show();
    } else {
      loadInterstitial();
    }
  }

  bool get isInterstitialReady => _isInterstitialReady;

  /// Ödüllü reklam – +10 kelime hakkı için
  Future<void> loadRewarded() async {
    await RewardedAd.load(
      adUnitId: _rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedReady = true;
        },
        onAdFailedToLoad: (e) {
          _isRewardedReady = false;
          if (kDebugMode) debugPrint('Rewarded load failed: $e');
        },
      ),
    );
  }

  /// Ödüllü reklamı göster; tamamlandığında onRewarded çağrılır
  Future<void> showRewarded({required VoidCallback onRewarded}) async {
    if (_rewardedAd != null && _isRewardedReady) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isRewardedReady = false;
          loadRewarded();
        },
      );
      _rewardedAd!.show(
        onUserEarnedReward: (_, __) => onRewarded(),
      );
    } else {
      loadRewarded();
    }
  }

  bool get isRewardedReady => _isRewardedReady;

  /// Banner ad widget – alt tarafta sabit
  BannerAd buildBannerAd() {
    return BannerAd(
      adUnitId: _bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {},
        onAdFailedToLoad: (ad, e) => ad.dispose(),
      ),
    );
  }
}
