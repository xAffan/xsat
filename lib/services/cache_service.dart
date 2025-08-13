// lib/services/cache_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/sync_helper.dart';

class CacheService {
  static const _seenQuestionsKey = 'seen_questions';
  static const _cachingEnabledKey = 'caching_enabled';

  Future<void> addSeenQuestionId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_cachingEnabledKey) ?? true;
    if (!isEnabled) {
      print('DEBUG: Caching is disabled, not adding question: "$id"');
      return;
    }

    final seenIds = prefs.getStringList(_seenQuestionsKey) ?? [];
    if (!seenIds.contains(id)) {
      seenIds.add(id);
      await prefs.setStringList(_seenQuestionsKey, seenIds);

      // Verify the save was successful
      final verifyIds = prefs.getStringList(_seenQuestionsKey) ?? [];
      if (verifyIds.contains(id)) {
        print('DEBUG: Successfully added question to seen list: "$id"');
        print('DEBUG: Total seen questions now: ${seenIds.length}');
      } else {
        print('ERROR: Failed to save seen question to SharedPreferences!');
      }

      // Sync to cloud immediately (non-blocking)
      SyncHelper.syncSeenQuestion(id);
    } else {
      print('DEBUG: Question already in seen list: "$id"');
    }
  }

  Future<List<String>> getSeenQuestionIds() async {
    final prefs = await SharedPreferences.getInstance();
    final seenIds = prefs.getStringList(_seenQuestionsKey) ?? [];

    // Debug logging
    print('DEBUG: Retrieved ${seenIds.length} seen questions from cache');
    if (seenIds.isNotEmpty) {
      print('DEBUG: First few seen IDs: ${seenIds.take(5).toList()}');
    }

    return seenIds;
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
