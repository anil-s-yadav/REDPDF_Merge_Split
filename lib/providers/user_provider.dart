import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  static const String _premiumKey = 'isPremium';
  bool _isPremium =
      false; // Based on screenshots showing premium features/styling
  final String _name = 'Anil Yadav';
  final String _email = 'anilyadav44x@gmail.com';
  late SharedPreferences _prefs;

  bool get isPremium => _isPremium;
  String get name => _name;
  String get email => _email;

  UserProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _isPremium = _prefs.getBool(_premiumKey) ?? true;
    notifyListeners();
  }

  void togglePremium() {
    _isPremium = !_isPremium;
    _prefs.setBool(_premiumKey, _isPremium);
    notifyListeners();
  }
}
