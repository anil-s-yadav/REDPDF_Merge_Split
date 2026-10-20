import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../services/ad_service.dart';
import '../../widgets/ad_banner_widget.dart';

class HelpUsScreen extends StatefulWidget {
  const HelpUsScreen({super.key});

  @override
  State<HelpUsScreen> createState() => _HelpUsScreenState();
}

class _HelpUsScreenState extends State<HelpUsScreen> {
  int _userWatchCount = 0;
  bool _isWatchingAd = false;
  final AdService _adService = AdService.instance;

  // Curated clean community supporters for motivation
  final List<CommunitySupporter> _dummySupporters = const [
    CommunitySupporter(
      name: 'David Miller',
      count: 48,
      color: Color(0xFF3B82F6),
    ),
    CommunitySupporter(
      name: 'Aisha Patel',
      count: 39,
      color: Color(0xFFF59E0B),
    ),
    CommunitySupporter(
      name: 'Lucas Silva',
      count: 31,
      color: Color(0xFF10B981),
    ),
    CommunitySupporter(
      name: 'Elena Rostova',
      count: 22,
      color: Color(0xFF8B5CF6),
    ),
    CommunitySupporter(
      name: 'Kenji Tanaka',
      count: 17,
      color: Color(0xFFEC4899),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserWatchCount();
    _adService.loadRewardedAd();
  }

  Future<void> _loadUserWatchCount() async {
    final count = await _adService.getAdWatchCount();
    if (mounted) {
      setState(() {
        _userWatchCount = count;
      });
    }
  }

  String _getUserTierTitle(int count) {
    if (count >= 25) return '💎 Diamond';
    if (count >= 10) return '🥇 Gold';
    if (count >= 5) return '🥈 Silver';
    if (count >= 1) return '🥉 Bronze';
    return '🌱 Supporter';
  }

  int _getNextTierTarget(int count) {
    if (count < 1) return 1;
    if (count < 5) return 5;
    if (count < 10) return 10;
    if (count < 25) return 25;
    return count + 10;
  }

  Future<void> _handleWatchAd() async {
    if (_isWatchingAd) return;

    setState(() {
      _isWatchingAd = true;
    });

    final success = await _adService.showRewardedAd(
      onUserEarnedReward: (reward) {
        _onAdSuccess();
      },
      onAdDismissed: () {
        if (mounted) {
          setState(() {
            _isWatchingAd = false;
          });
        }
      },
      onAdFailedToShow: (reason) {
        if (mounted) {
          setState(() {
            _isWatchingAd = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                reason.isNotEmpty
                    ? reason
                    : 'Ad could not be shown right now. Please try again shortly.',
              ),
              backgroundColor: Colors.grey.shade800,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );

    if (!success && mounted) {
      setState(() {
        _isWatchingAd = false;
      });
    }
  }

  void _onAdSuccess() async {
    final updatedCount = await _adService.getAdWatchCount();
    if (!mounted) return;

    setState(() {
      _userWatchCount = updatedCount;
      _isWatchingAd = false;
    });

    _showCelebrationDialog(updatedCount);
  }

  void _showCelebrationDialog(int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? const Color(0xFF1E2433) : Colors.white,
        title: const Center(
          child: Column(
            children: [
              Text('❤️🎉', style: TextStyle(fontSize: 44)),
              SizedBox(height: 8),
              Text(
                'Thank You So Much!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your support directly helps us keep RedPDF 100% free and uninterrupted for you and thousands of others.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(
                  0xFFEF4444,
                ).withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.favorite,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Total Ads Watched: $count',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEF4444),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'You are welcome!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Support Us',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(
                0xFFEF4444,
              ).withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFEF4444),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '$_userWatchCount Supports from you',
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacing20,
            vertical: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Hero Heartfelt Banner
              _buildHeroCard(context, isDark),
              const SizedBox(height: 16),

              // 2. User's Personal Stats Card
              _buildUserProgressCard(context, isDark, colorScheme),
              const SizedBox(height: 16),

              // 3. Watch Ad CTA Button
              _buildWatchAdButton(context, isDark),
              const SizedBox(height: 24),

              // 4. Cleaner & Aesthetic Community Leaderboard
              _buildCleanLeaderboard(context, isDark, colorScheme),
              const SizedBox(height: 24),

              // 5. 4:3 / Rich Media Banner showcase
              _buildRichMediaBannerCard(context, isDark),
              const SizedBox(height: 80), // Padding for bottom nav bar
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero Banner ──
  Widget _buildHeroCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF3B151E),
                  const Color(0xFF28131C),
                  const Color(0xFF1B1119),
                ]
              : [
                  const Color(0xFFFFF1F2),
                  const Color(0xFFFFE4E6),
                  const Color(0xFFFEE2E2),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.3 : 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFFEF4444,
            ).withValues(alpha: isDark ? 0.15 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFF43F5E)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Help Keep RedPDF Free',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isDark ? Colors.white : const Color(0xFF881337),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '100% voluntary • No interruptions',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFFFDA4AF)
                            : const Color(0xFFBE123C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Watching a voluntary ad here helps us cover server and maintenance costs, support developer and future updates. Thank you for your support!',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: isDark ? Colors.grey.shade300 : const Color(0xFF4C0519),
            ),
          ),
        ],
      ),
    );
  }

  // ── User Progress Card ──
  Widget _buildUserProgressCard(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final nextTarget = _getNextTierTarget(_userWatchCount);
    final progress = math.min(
      1.0,
      _userWatchCount / (nextTarget > 0 ? nextTarget : 1),
    );
    final tierTitle = _getUserTierTitle(_userWatchCount);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surface.withValues(alpha: 0.8)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Contribution',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_userWatchCount Ads Watched',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tierTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFEF4444),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _userWatchCount == 0
                    ? 'Watch 1 ad to become a Supporter!'
                    : '$_userWatchCount / $nextTarget to next badge',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Watch Ad Button ──
  Widget _buildWatchAdButton(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEF4444),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        onPressed: _isWatchingAd ? null : _handleWatchAd,
        child: _isWatchingAd
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Preparing Ad...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_circle_fill_rounded, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    _userWatchCount == 0
                        ? 'Watch an Ad to Help Us ❤️'
                        : 'Watch Another Ad (+1 Support)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Cleaner & Aesthetic Leaderboard ──
  Widget _buildCleanLeaderboard(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final totalCommunityAds =
        _dummySupporters.fold<int>(0, (sum, item) => sum + item.count) +
        _userWatchCount;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surface.withValues(alpha: 0.7)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Clean Total Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFFF59E0B),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Our Top Supporters',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF10B981,
                    ).withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$totalCommunityAds Ads Contributed',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // User's Row (Clean & Highlighted if user has watched)
          if (_userWatchCount > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(
                  0xFFEF4444,
                ).withValues(alpha: isDark ? 0.18 : 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 10),
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0xFFEF4444),
                    child: Text(
                      'You',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'You (Active Helper)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_userWatchCount ads',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Clean Top Supporters List (Clean, modern rows)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _dummySupporters.length,
            separatorBuilder: (context, index) => Divider(
              height: 12,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
            ),
            itemBuilder: (context, index) {
              final supporter = _dummySupporters[index];
              final rank = index + 1;

              final String rankBadge = switch (rank) {
                1 => '🥇',
                2 => '🥈',
                3 => '🥉',
                _ => '#$rank',
              };

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        rankBadge,
                        style: TextStyle(
                          fontSize: rank <= 3 ? 14 : 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: supporter.color.withValues(alpha: 0.15),
                      child: Text(
                        supporter.name.substring(0, 1),
                        style: TextStyle(
                          color: supporter.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        supporter.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${supporter.count} ads',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── 4:3 / Rich Media Banner Card ──
  Widget _buildRichMediaBannerCard(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(
                Icons.campaign_outlined,
                size: 16,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                'Our Featured Partner (4:3 / Rich Banner)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        const Center(
          child: AdBannerWidget(
            bannerType: AdBannerType.mediumRectangle,
            showBadge: true,
          ),
        ),
      ],
    );
  }
}

class CommunitySupporter {
  final String name;
  final int count;
  final Color color;

  const CommunitySupporter({
    required this.name,
    required this.count,
    required this.color,
  });
}
