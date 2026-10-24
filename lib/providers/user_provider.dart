import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/billing_service.dart';

class UserProvider with ChangeNotifier {
  static const String _premiumKey = 'isPremium';
  static const String _activePlanKey = 'activePlanId';

  bool _isPremium = false;
  String? _activePlanId;
  final String _name = 'Anil Yadav';
  final String _email = 'anilyadav44x@gmail.com';
  SharedPreferences? _prefs;

  bool get isPremium => _isPremium;
  String? get activePlanId => _activePlanId;
  String get name => _name;
  String get email => _email;

  UserProvider() {
    _loadFromPrefs();
    // Connect to BillingService status changes
    BillingService.instance.onPremiumStatusChanged = (isPremium, productId) {
      setPremium(isPremium: isPremium, planId: productId);
    };
  }

  Future<void> _loadFromPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _isPremium = _prefs?.getBool(_premiumKey) ?? false;
    _activePlanId = _prefs?.getString(_activePlanKey);
    notifyListeners();
  }

  Future<void> setPremium({required bool isPremium, String? planId}) async {
    _isPremium = isPremium;
    _activePlanId = planId;
    notifyListeners();

    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, _isPremium);
    if (planId != null) {
      await prefs.setString(_activePlanKey, planId);
    } else {
      await prefs.remove(_activePlanKey);
    }
  }

  /// Developer / Test toggle
  Future<void> togglePremium() async {
    _isPremium = !_isPremium;
    notifyListeners();
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, _isPremium);
  }
}
