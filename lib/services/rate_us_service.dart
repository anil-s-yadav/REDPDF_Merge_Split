import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RateUsService {
  static const _keyDismissedForever = 'rate_us_dismissed_forever';
  static const _keyTaskCount = 'rate_us_task_count';
  static const _keyLastPromptTime = 'rate_us_last_prompt_time';
  static const _keyHasUsedInAppReview = 'rate_us_used_in_app_review';

  // Show the native in-app review on the 3rd and every 10th task after that.
  // Show the custom fallback dialog on every other qualifying task.
  static const _firstPromptAfterTasks = 3;
  static const _repeatInterval = 10;

  /// Increment the completed-task counter. Call this after every successful
  /// merge / split / extract.
  static Future<void> recordTaskCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_keyTaskCount) ?? 0) + 1;
    await prefs.setInt(_keyTaskCount, count);
  }

  /// Try the native In-App Review flow. Returns `true` if the native review
  /// dialog was shown, `false` if it wasn't available (so the caller can fall
  /// back to a custom dialog).
  static Future<bool> requestInAppReview() async {
    try {
      final inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyHasUsedInAppReview, true);
        return true;
      }
    } catch (e) {
      debugPrint('In-app review error: $e');
    }
    return false;
  }

  /// Whether we should show *any* review prompt (native or custom).
  static Future<bool> shouldShowRateDialog() async {
    final prefs = await SharedPreferences.getInstance();

    // User chose "Don't ask again"
    if (prefs.getBool(_keyDismissedForever) ?? false) return false;

    final taskCount = prefs.getInt(_keyTaskCount) ?? 0;

    // Not enough tasks yet
    if (taskCount < _firstPromptAfterTasks) return false;

    // After the first prompt, show every _repeatInterval tasks
    final tasksSinceFirst = taskCount - _firstPromptAfterTasks;
    if (tasksSinceFirst > 0 && tasksSinceFirst % _repeatInterval != 0) {
      return false;
    }

    // Don't prompt more than once per 24 hours
    final lastPrompt = prefs.getInt(_keyLastPromptTime) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastPrompt < const Duration(hours: 24).inMilliseconds) {
      return false;
    }

    // Record this prompt time
    await prefs.setInt(_keyLastPromptTime, now);
    return true;
  }

  /// Whether we should try the native in-app review (preferred) vs the custom
  /// fallback dialog.
  static Future<bool> shouldTryNativeReview() async {
    final prefs = await SharedPreferences.getInstance();
    // Google limits how often native review can be shown, so we try it
    // if we haven't successfully shown it yet, or every ~10 tasks.
    final hasUsed = prefs.getBool(_keyHasUsedInAppReview) ?? false;
    if (!hasUsed) return true;

    // Even if used before, try periodically (Google will throttle anyway)
    final taskCount = prefs.getInt(_keyTaskCount) ?? 0;
    return taskCount % _repeatInterval == 0;
  }

  /// User chose "Don't ask again" — never show again.
  static Future<void> dismissForever() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDismissedForever, true);
  }

  /// User chose "Not Now" — dialog will appear again after more tasks.
  static Future<void> dismissTemporarily() async {
    // No-op: the task-count + time gating handles re-prompting.
  }
}
