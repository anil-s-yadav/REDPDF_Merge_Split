import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BillingService with ChangeNotifier {
  BillingService._();
  static final BillingService instance = BillingService._();

  // ── Product IDs ────────────────────────────────────────────────────────────
  // Matches Google Play Console In-App Products & Subscriptions
  static const String idMonth1 = 'pdfbitz_merge_pro_1month';
  static const String idMonths6 = 'pdfbitz_merge_pro_6months';
  static const String idYear1 = 'pdfbitz_merge_pro_1year';
  static const String idLifetime = 'pdfbitz_merge_pro_lifetime';

  static const Set<String> allProductIds = {
    idMonth1,
    idMonths6,
    idYear1,
    idLifetime,
  };

  // ── SharedPreferences Keys for Offline Entitlement ─────────────────────────
  static const String _prefKeyIsPremium = 'billing_is_premium';
  static const String _prefKeyActiveProductId = 'billing_active_product_id';
  static const String _prefKeyPurchaseToken = 'billing_purchase_token';
  static const String _prefKeyPurchaseTime = 'billing_purchase_time';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isPurchasing = false;
  bool get isPurchasing => _isPurchasing;

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  String? _activeProductId;
  String? get activeProductId => _activeProductId;

  String? _purchaseError;
  String? get purchaseError => _purchaseError;

  final Map<String, ProductDetails> _products = {};
  Map<String, ProductDetails> get products => Map.unmodifiable(_products);

  // Callback for UserProvider / App state
  void Function(bool isPremium, String? productId)? onPremiumStatusChanged;

  /// Initialize billing service and listen for purchases
  Future<void> initialize({
    void Function(bool isPremium, String? productId)? onStatusChanged,
  }) async {
    if (kIsWeb) return;
    if (onStatusChanged != null) {
      onPremiumStatusChanged = onStatusChanged;
    }

    // 1. Verify offline entitlement first (so user never loses PRO while offline)
    await _loadOfflineEntitlement();

    // 2. Set up purchase stream listener
    _subscription?.cancel();
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () {
        _subscription?.cancel();
        _subscription = null;
      },
      onError: (error) {
        log('[BillingService] Purchase stream error: $error');
        _isPurchasing = false;
        _purchaseError = error.toString();
        notifyListeners();
      },
    );

    // 3. Check Google Play Store connection
    try {
      _isAvailable = await _iap.isAvailable();
      log('[BillingService] Store available: $_isAvailable');

      if (_isAvailable) {
        await loadProducts();
      }
    } catch (e) {
      log('[BillingService] Error checking availability: $e');
      _isAvailable = false;
    }

    notifyListeners();
  }

  /// Load localized product details and live prices from Google Play
  Future<void> loadProducts() async {
    if (!_isAvailable) return;

    _isLoading = true;
    notifyListeners();

    try {
      final ProductDetailsResponse response =
          await _iap.queryProductDetails(allProductIds);

      if (response.error != null) {
        log('[BillingService] Error querying products: ${response.error!.message}');
      }

      if (response.notFoundIDs.isNotEmpty) {
        log('[BillingService] Products not found in Play Console: ${response.notFoundIDs}');
      }

      _products.clear();
      for (final product in response.productDetails) {
        log('[BillingService] Product loaded: ${product.id} -> ${product.price} (${product.title})');
        _products[product.id] = product;
      }
    } catch (e) {
      log('[BillingService] Failed to load products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get live ProductDetails by ID
  ProductDetails? getProduct(String id) {
    if (_products.containsKey(id)) {
      return _products[id];
    }
    return null;
  }

  /// Purchase a plan by Product ID
  Future<bool> buyProduct(String productId) async {
    if (!_isAvailable) {
      _purchaseError = 'Google Play Store is currently not available.';
      notifyListeners();
      return false;
    }

    ProductDetails? details = getProduct(productId);

    // If products haven't loaded yet, try refreshing once
    if (details == null) {
      await loadProducts();
      details = getProduct(productId);
    }

    if (details == null) {
      _purchaseError =
          'Product "$productId" is not yet published or ready on Google Play Console.';
      log('[BillingService] $purchaseError');
      notifyListeners();
      return false;
    }

    _isPurchasing = true;
    _purchaseError = null;
    notifyListeners();

    try {
      PurchaseParam purchaseParam;

      // Handle Google Play Billing v5+ subscription offerToken on Android
      if (Platform.isAndroid && details is GooglePlayProductDetails) {
        final offers = details.productDetails.subscriptionOfferDetails;
        String? offerToken;
        if (offers != null && offers.isNotEmpty) {
          final idx = details.subscriptionIndex ?? 0;
          offerToken = (idx < offers.length)
              ? offers[idx].offerIdToken
              : offers.first.offerIdToken;
        }

        purchaseParam = GooglePlayPurchaseParam(
          productDetails: details,
          offerToken: offerToken,
        );
      } else {
        purchaseParam = PurchaseParam(productDetails: details);
      }

      // In in_app_purchase, buyNonConsumable is used for both non-consumable products and auto-renewing subscriptions
      final bool started =
          await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      log('[BillingService] Purchase flow launched: $started for $productId');
      return started;
    } catch (e) {
      log('[BillingService] Error launching purchase: $e');
      _isPurchasing = false;
      _purchaseError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Restore previous purchases (for reinstallation or switching devices)
  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      _purchaseError = 'Store not available to restore purchases.';
      notifyListeners();
      return;
    }

    _isPurchasing = true;
    _purchaseError = null;
    notifyListeners();

    try {
      log('[BillingService] Restoring purchases...');
      await _iap.restorePurchases();
    } catch (e) {
      log('[BillingService] Error restoring purchases: $e');
      _purchaseError = e.toString();
    } finally {
      _isPurchasing = false;
      notifyListeners();
    }
  }

  /// Process incoming purchases from Google Play
  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final purchaseDetails in purchaseDetailsList) {
      log('[BillingService] Purchase update: ${purchaseDetails.productID} -> status: ${purchaseDetails.status}');

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          _isPurchasing = true;
          _purchaseError = null;
          notifyListeners();
          break;

        case PurchaseStatus.canceled:
          _isPurchasing = false;
          _purchaseError = null;
          notifyListeners();
          break;

        case PurchaseStatus.error:
          _isPurchasing = false;
          _purchaseError = purchaseDetails.error?.message ?? 'Purchase failed.';
          log('[BillingService] Purchase error: ${purchaseDetails.error}');
          notifyListeners();

          if (purchaseDetails.pendingCompletePurchase) {
            await _iap.completePurchase(purchaseDetails);
          }
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndDeliverProduct(purchaseDetails);
          break;
      }
    }
  }

  /// Verify entitlement and deliver PRO access to the user
  Future<void> _verifyAndDeliverProduct(PurchaseDetails purchaseDetails) async {
    log('[BillingService] Delivering PRO access for product: ${purchaseDetails.productID}');

    final productId = purchaseDetails.productID;
    final token = purchaseDetails.verificationData.serverVerificationData;

    // Save offline entitlement
    await _saveOfflineEntitlement(
      isPremium: true,
      productId: productId,
      token: token,
    );

    // Notify listeners & UserProvider
    onPremiumStatusChanged?.call(true, productId);

    _isPurchasing = false;
    _purchaseError = null;
    notifyListeners();

    // Acknowledge / complete purchase (Mandatory to prevent Google auto-refund)
    if (purchaseDetails.pendingCompletePurchase) {
      try {
        await _iap.completePurchase(purchaseDetails);
        log('[BillingService] Purchase acknowledged successfully.');
      } catch (e) {
        log('[BillingService] Error completing purchase: $e');
      }
    }
  }

  /// Load locally cached entitlement (Offline protection)
  Future<void> _loadOfflineEntitlement() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool(_prefKeyIsPremium) ?? false;
      _activeProductId = prefs.getString(_prefKeyActiveProductId);

      if (_isPremium) {
        log('[BillingService] Offline entitlement active for $_activeProductId');
        onPremiumStatusChanged?.call(true, _activeProductId);
      }
    } catch (e) {
      log('[BillingService] Error reading offline entitlement: $e');
    }
  }

  /// Save entitlement to SharedPreferences
  Future<void> _saveOfflineEntitlement({
    required bool isPremium,
    required String productId,
    required String token,
  }) async {
    _isPremium = isPremium;
    _activeProductId = productId;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyIsPremium, isPremium);
      await prefs.setString(_prefKeyActiveProductId, productId);
      await prefs.setString(_prefKeyPurchaseToken, token);
      await prefs.setInt(
        _prefKeyPurchaseTime,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      log('[BillingService] Error saving offline entitlement: $e');
    }
  }

  /// Clear entitlement (e.g. if subscription expired or test reset)
  Future<void> clearEntitlement() async {
    _isPremium = false;
    _activeProductId = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyIsPremium, false);
      await prefs.remove(_prefKeyActiveProductId);
      await prefs.remove(_prefKeyPurchaseToken);
      await prefs.remove(_prefKeyPurchaseTime);
      onPremiumStatusChanged?.call(false, null);
      notifyListeners();
    } catch (e) {
      log('[BillingService] Error clearing entitlement: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
