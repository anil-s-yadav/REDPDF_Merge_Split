import 'package:shared_preferences/shared_preferences.dart';

class RateUsService {
  static const _keyDismissedForever = 'rate_us_dismissed_forever';

  /// Returns `true` if the rating dialog should be shown (after every task).
  static Future<bool> shouldShowRateDialog() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_keyDismissedForever) ?? false);
  }

  /// User chose "Don't ask again" — never show again.
  static Future<void> dismissForever() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDismissedForever, true);
  }

  /// User chose "Not Now" — dialog will appear again after the next task.
  static Future<void> dismissTemporarily() async {
    // No-op: dialog shows after every task by default.
  }
}
