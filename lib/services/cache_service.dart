// lib/services/cache_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/sync_helper.dart';

class CacheService {
  static const _seenQuestionsKey = 'seen_questions';
  static const _cachingEnabledKey = 'caching_enabled';

  Future<void> addSeenQuestionId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_cachingEnabledKey) ?? true;
    if (!isEnabled) return;

    final seenIds = prefs.getStringList(_seenQuestionsKey) ?? [];
    if (!seenIds.contains(id)) {
      seenIds.add(id);
      await prefs.setStringList(_seenQuestionsKey, seenIds);

      // Sync to cloud immediately (non-blocking)
      SyncHelper.syncSeenQuestion(id);
    }
  }

  Future<List<String>> getSeenQuestionIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_seenQuestionsKey) ?? [];
  }

  Future<void> clearSeenQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_seenQuestionsKey);
  }

  Future<void> setCachingEnabled(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cachingEnabledKey, isEnabled);
  }

  Future<bool> isCachingEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_cachingEnabledKey) ?? true; // Enabled by default
  }
}
