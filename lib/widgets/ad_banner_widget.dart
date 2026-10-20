import 'dart:io';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

enum AdBannerType {
  standard,       // 320 x 50
  large,          // 320 x 100
  mediumRectangle, // 300 x 250
  square1x1,      // 300 x 300
  fourByThree,    // 320 x 240
  adaptive,       // full-width anchored
}

// ── Internal cache entry ──────────────────────────────────────────────────────

class CachedBannerEntry {
  final BannerAd ad;
  final AdSize size;
  bool isLoaded;
  final AdBannerType type;

  CachedBannerEntry({
    required this.ad,
    required this.size,
    required this.type,
    this.isLoaded = false,
  });
}

// ── Ad Cache singleton ────────────────────────────────────────────────────────

/// Singleton cache that preloads and recycles banner ads by type.
///
/// Strategy:
///   • On app init, preload [standard] and [mediumRectangle] (most-used).
///   • When a widget requests a type, return the cached ready ad instantly.
///   • After an ad is given to a widget, immediately start loading the next one
///     so the next screen has it ready.
///   • One concurrent ad per type (no memory bloat).
class BannerAdCache {
  BannerAdCache._();
  static final BannerAdCache instance = BannerAdCache._();

  final Map<AdBannerType, CachedBannerEntry?> _cache = {};
  final Map<AdBannerType, bool> _loading = {};

  /// Call once from AdService.initialize() to warm up the most-used ad sizes.
  void preload([List<AdBannerType> types = const [
    AdBannerType.standard,
    AdBannerType.mediumRectangle,
  ]]) {
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;
    for (final type in types) {
      if (_cache[type] == null && _loading[type] != true) {
        _loadForType(type);
      }
    }
  }

  /// Returns [true] if a loaded ad is ready for [type].
  bool isReady(AdBannerType type) {
    final entry = _cache[type];
    return entry != null && entry.isLoaded;
  }

  /// Peek at the cached ad size for [type] without consuming it.
  AdSize? sizeFor(AdBannerType type) => _cache[type]?.size;

  /// Claim the cached ad for [type].
  /// The caller owns it; we immediately start loading the next one.
  CachedBannerEntry? claim(AdBannerType type) {
    final entry = _cache[type];
    if (entry == null || !entry.isLoaded) return null;
    _cache[type] = null;
    _loadForType(type); // preload next immediately
    return entry;
  }

  Future<void> _loadForType(AdBannerType type) async {
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (_loading[type] == true) return;

    final adUnitId = AdService.bannerAdUnitId;
    if (adUnitId.isEmpty) return;

    AdSize adSize;
    try {
      adSize = await _resolveSize(type);
    } catch (_) {
      return;
    }

    _loading[type] = true;

    final ad = BannerAd(
      adUnitId: adUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          log('[AdCache] $type loaded (${adSize.width}x${adSize.height})');
          _cache[type] = CachedBannerEntry(
            ad: ad as BannerAd,
            size: adSize,
            type: type,
            isLoaded: true,
          );
          _loading[type] = false;
        },
        onAdFailedToLoad: (ad, error) {
          log('[AdCache] $type failed: ${error.message}');
          ad.dispose();
          _cache[type] = null;
          _loading[type] = false;
        },
      ),
    );

    await ad.load();
  }

  static Future<AdSize> _resolveSize(AdBannerType type) async {
    switch (type) {
      case AdBannerType.standard:
        return AdSize.banner;
      case AdBannerType.large:
        return AdSize.largeBanner;
      case AdBannerType.mediumRectangle:
        return AdSize.mediumRectangle;
      case AdBannerType.square1x1:
        return const AdSize(width: 300, height: 300);
      case AdBannerType.fourByThree:
        return const AdSize(width: 320, height: 240);
      case AdBannerType.adaptive:
        // Adaptive needs screen width — fallback to largeBanner if not available
        return AdSize.largeBanner;
    }
  }

  void dispose() {
    for (final entry in _cache.values) {
      entry?.ad.dispose();
    }
    _cache.clear();
    _loading.clear();
  }
}

// ── Ad Banner Widget ──────────────────────────────────────────────────────────

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
      case AdBannerType.large:
        return AdSize.largeBanner;
      case AdBannerType.mediumRectangle:
        return AdSize.mediumRectangle;
      case AdBannerType.square1x1:
        return const AdSize(width: 300, height: 300);
      case AdBannerType.fourByThree:
        return const AdSize(width: 320, height: 240);
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
