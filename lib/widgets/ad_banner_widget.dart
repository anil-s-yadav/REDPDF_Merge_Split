import 'dart:io';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

enum AdBannerType {
  standard, // 320 x 50
  large, // 320 x 100
  mediumRectangle, // 300 x 250 (IAB Medium Rectangle - video & rich image banner)
  square1x1, // 300 x 300 (1:1 big banner with rich media)
  fourByThree, // 320 x 240 (4:3 aspect banner)
  adaptive, // Dynamically computed adaptive banner
}

class AdBannerWidget extends StatefulWidget {
  final AdBannerType bannerType;
  final EdgeInsetsGeometry? margin;
  final bool showBadge;

  const AdBannerWidget({
    super.key,
    this.bannerType = AdBannerType.standard,
    this.margin,
    this.showBadge = true,
  });

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _hasFailed = false;
  AdSize? _targetAdSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null && !_hasFailed) {
      _loadBanner();
    }
  }

  Future<void> _loadBanner() async {
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final adUnitId = AdService.bannerAdUnitId;
    if (adUnitId.isEmpty) return;

    final adSize = await _resolveAdSize();
    if (!mounted) return;

    setState(() {
      _targetAdSize = adSize;
    });

    final ad = BannerAd(
      adUnitId: adUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          final bannerAd = ad as BannerAd;
          log('Banner ad loaded: size=${bannerAd.size.width}x${bannerAd.size.height}');
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
              _hasFailed = false;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          log(
            'Banner ad failed to load: ${error.message} (code: ${error.code})',
          );
          ad.dispose();
          if (mounted) {
            setState(() {
              _bannerAd = null;
              _isAdLoaded = false;
              _hasFailed = true;
            });
          }
        },
      ),
    );

    _bannerAd = ad;
    await ad.load();
  }

  Future<AdSize> _resolveAdSize() async {
    switch (widget.bannerType) {
      case AdBannerType.standard:
        return AdSize.banner; // 320 x 50
      case AdBannerType.large:
        return AdSize.largeBanner; // 320 x 100
      case AdBannerType.mediumRectangle:
        return AdSize.mediumRectangle; // 300 x 250
      case AdBannerType.square1x1:
        return const AdSize(width: 300, height: 300); // 1:1 big banner
      case AdBannerType.fourByThree:
        return const AdSize(width: 320, height: 240); // 4:3 banner
      case AdBannerType.adaptive:
        final width = MediaQuery.sizeOf(context).width.truncate();
        final safeWidth = width > 0 ? width : 320;
        final adaptiveSize =
            await AdSize.getLargeAnchoredAdaptiveBannerAdSize(safeWidth);
        return adaptiveSize ?? AdSize.banner;
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return const SizedBox.shrink();
    }

    if (_hasFailed || !_isAdLoaded || _bannerAd == null || _targetAdSize == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = _targetAdSize!;

    return Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 4),
      alignment: Alignment.center,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: size.width.toDouble(),
            height: size.height.toDouble(),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2330) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: AdWidget(ad: _bannerAd!),
          ),
          if (widget.showBadge)
            Positioned(
              top: 4,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Ad',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
