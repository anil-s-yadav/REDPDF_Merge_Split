import 'dart:io';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/ad_service.dart';

// Re-export so any widget importing ad_banner_widget.dart has access
export '../services/ad_service.dart' show AdBannerType, BannerAdCache, CachedBannerEntry;

// ── Ad Banner Widget ──────────────────────────────────────────────────────────

class AdBannerWidget extends StatefulWidget {
  final AdBannerType bannerType;
  final EdgeInsetsGeometry? margin;
  final bool showBadge;

  const AdBannerWidget({
    super.key,
    this.bannerType = AdBannerType.standard,
    this.margin,
    this.showBadge = false,
  });

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget>
    with SingleTickerProviderStateMixin {
  BannerAd? _bannerAd;
  AdSize? _adSize;
  bool _isAdLoaded = false;
  bool _hasFailed = false;

  // For smooth fade-in when ad appears
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _tryFromCache();
  }

  /// Step 1: try the cache first (instant, no network wait).
  void _tryFromCache() {
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final entry = BannerAdCache.instance.claim(widget.bannerType);
    if (entry != null) {
      _bannerAd = entry.ad;
      _adSize = entry.size;
      _isAdLoaded = true;
      // Trigger fade-in after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fadeController.forward();
      });
    } else {
      // Cache miss — load directly, also kick the cache to preload for next time
      BannerAdCache.instance.preload([widget.bannerType]);
      _loadDirect();
    }
  }

  /// Step 2 (cache miss): load directly while the cache preloads for next screen.
  Future<void> _loadDirect() async {
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final adUnitId = AdService.bannerAdUnitId;
    if (adUnitId.isEmpty) return;

    final adSize = await _resolveAdaptiveSize();
    if (!mounted) return;

    setState(() => _adSize = adSize);

    final ad = BannerAd(
      adUnitId: adUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          log('[AdBannerWidget] Direct load OK: ${widget.bannerType}');
          if (mounted) {
            setState(() {
              _bannerAd = ad as BannerAd;
              _isAdLoaded = true;
              _hasFailed = false;
            });
            _fadeController.forward();
          }
        },
        onAdFailedToLoad: (ad, error) {
          log('[AdBannerWidget] Direct load failed: ${error.message}');
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

  Future<AdSize> _resolveAdaptiveSize() async {
    switch (widget.bannerType) {
      case AdBannerType.standard:
        return AdSize.banner;
      case AdBannerType.mediumRectangle:
        return AdSize.mediumRectangle;
      case AdBannerType.adaptive:
        final width = MediaQuery.sizeOf(context).width.truncate();
        final safeWidth = width > 0 ? width : 320;
        final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(safeWidth);
        return size ?? AdSize.banner;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return const SizedBox.shrink();
    }
    final isPremium = context.watch<UserProvider?>()?.isPremium ?? false;
    if (isPremium) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Placeholder skeleton while loading ───────────────────────────────────
    if (!_isAdLoaded || _hasFailed || _bannerAd == null) {
      if (_hasFailed || _adSize == null) return const SizedBox.shrink();

      // Show a shimmer-like placeholder matching the ad slot size
      final ph = _adSize ?? AdSize.banner;
      return Container(
        margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 4),
        alignment: Alignment.center,
        child: _ShimmerPlaceholder(
          width: ph.width.toDouble(),
          height: ph.height.toDouble(),
          isDark: isDark,
        ),
      );
    }

    // ── Real ad (fade-in) ─────────────────────────────────────────────────────
    final size = _adSize!;
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
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
                color: isDark
                    ? const Color(0xFF1E2330)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: isDark ? 0.2 : 0.04),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1.5,
                  ),
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
      ),
    );
  }
}

// ── Shimmer Placeholder ───────────────────────────────────────────────────────

class _ShimmerPlaceholder extends StatefulWidget {
  final double width;
  final double height;
  final bool isDark;

  const _ShimmerPlaceholder({
    required this.width,
    required this.height,
    required this.isDark,
  });

  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isDark
        ? const Color(0xFF1E2330)
        : const Color(0xFFEEEEEE);
    final shimmerColor = widget.isDark
        ? const Color(0xFF2A3040)
        : const Color(0xFFF5F5F5);

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _anim.value, 0),
              end: Alignment(1.0 + 2.0 * _anim.value, 0),
              colors: [baseColor, shimmerColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
