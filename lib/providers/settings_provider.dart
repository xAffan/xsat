import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/cache_service.dart';

// Enum for the different question types
enum QuestionType { english, math, both }

// Enum for the different theme preferences
enum ThemePreference { system, light, dark }

class SettingsProvider with ChangeNotifier {
  final CacheService _cacheService = CacheService();
  bool _isCachingEnabled = true;
  QuestionType _questionType = QuestionType.english;
  ThemePreference _themePreference = ThemePreference.system; // New
  bool _isOledMode = false; // New
  bool _excludeActiveQuestions = false; // New
  bool _onboardingCompleted = false; // New

  // Callback for sync operations
  Future<void> Function()? _syncCallback;

  // Getters
  bool get isCachingEnabled => _isCachingEnabled;
  QuestionType get questionType => _questionType;
  ThemePreference get themePreference => _themePreference; // New
  bool get isOledMode => _isOledMode; // New
  bool get excludeActiveQuestions => _excludeActiveQuestions; // New
  bool get onboardingCompleted => _onboardingCompleted; // New

  // Sounds are always enabled - no setting needed
  bool get soundEnabled => true;

  // Convert our enum to Flutter's ThemeMode for the MaterialApp
  ThemeMode get themeMode {
    switch (_themePreference) {
      case ThemePreference.light:
        return ThemeMode.light;
      case ThemePreference.dark:
        return ThemeMode.dark;
      case ThemePreference.system:
        return ThemeMode.system;
    }
  }

  SettingsProvider() {
    loadSettings();
  }

  /// Set the sync callback
  void setSyncCallback(Future<void> Function()? callback) {
    _syncCallback = callback;
  }

  /// Trigger sync if callback is available
  Future<void> _triggerSync() async {
    if (_syncCallback != null) {
      try {
        await _syncCallback!();
      } catch (e) {
        // Silently fail - sync shouldn't break settings updates
        debugPrint('Settings sync failed: $e');
      }
    }
  }

  Future<void> loadSettings() async {
    _isCachingEnabled = await _cacheService.isCachingEnabled();
    _questionType = await _cacheService.getQuestionType();
    _themePreference = await _cacheService.getThemePreference(); // New
    _isOledMode = await _cacheService.isOledMode(); // New
    _excludeActiveQuestions =
        await _cacheService.getExcludeActiveQuestions(); // New
    _onboardingCompleted = await _cacheService.isOnboardingCompleted(); // New
    notifyListeners();
  }

  Future<void> toggleCaching(bool value) async {
    _isCachingEnabled = value;
    await _cacheService.setCachingEnabled(value);
    notifyListeners();
    await _triggerSync();
  }

  Future<void> updateQuestionType(QuestionType newType) async {
    if (_questionType == newType) return;
    _questionType = newType;
    await _cacheService.setQuestionType(newType);
    notifyListeners();
    await _triggerSync();
  }

  // New methods for theme
  Future<void> updateThemePreference(ThemePreference newPreference) async {
    if (_themePreference == newPreference) return;
    _themePreference = newPreference;
    await _cacheService.setThemePreference(newPreference);
    notifyListeners();
    // Don't sync theme appearance preferences
  }

  Future<void> toggleOledMode(bool value) async {
    _isOledMode = value;
    await _cacheService.setOledMode(value);
    notifyListeners();
    await _triggerSync(); // YES - sync OLED mode
  }

  Future<void> toggleExcludeActiveQuestions(bool value) async {
    _excludeActiveQuestions = value;
    await _cacheService.setExcludeActiveQuestions(value);
    // Exclude active questions now applies instantly, no restart needed
    notifyListeners();
    await _triggerSync();
  }

  Future<void> setOnboardingCompleted(bool value) async {
    _onboardingCompleted = value;
    await _cacheService.setOnboardingCompleted(value);
    notifyListeners();
  }

  Future<void> clearCache() async {
    await _cacheService.clearSeenQuestions();
    // Cache clearing doesn't need restart - just clears the seen questions list
    notifyListeners();
  }
}

// Add extension to CacheService to handle all settings
extension on CacheService {
  Future<void> setQuestionType(QuestionType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('question_type', type.name);
  }

  Future<QuestionType> getQuestionType() async {
    final prefs = await SharedPreferences.getInstance();
    final typeName =
        prefs.getString('question_type') ?? QuestionType.english.name;
    return QuestionType.values.firstWhere((e) => e.name == typeName);
  }

  // New methods for theme preferences in SharedPreferences
  Future<void> setThemePreference(ThemePreference preference) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_preference', preference.name);
  }

  Future<ThemePreference> getThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName =
        prefs.getString('theme_preference') ?? ThemePreference.system.name;
    return ThemePreference.values.firstWhere((e) => e.name == themeName,
        orElse: () => ThemePreference.system);
  }

  Future<void> setOledMode(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('oled_mode', isEnabled);
  }

  Future<bool> isOledMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('oled_mode') ?? false;
  }

  Future<void> setExcludeActiveQuestions(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('exclude_active_questions', value);
  }

  Future<bool> getExcludeActiveQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('exclude_active_questions') ?? false;
  }

  Future<void> setOnboardingCompleted(bool isCompleted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', isCompleted);
  }

  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }
}
