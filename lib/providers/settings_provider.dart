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
  bool settingsHaveChanged = false; // Flag to check if a reload is needed

  // Getters
  bool get isCachingEnabled => _isCachingEnabled;
  QuestionType get questionType => _questionType;
  ThemePreference get themePreference => _themePreference; // New
  bool get isOledMode => _isOledMode; // New
  bool get excludeActiveQuestions => _excludeActiveQuestions; // New

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

  Future<void> loadSettings() async {
    _isCachingEnabled = await _cacheService.isCachingEnabled();
    _questionType = await _cacheService.getQuestionType();
    _themePreference = await _cacheService.getThemePreference(); // New
    _isOledMode = await _cacheService.isOledMode(); // New
    _excludeActiveQuestions =
        await _cacheService.getExcludeActiveQuestions(); // New
    notifyListeners();
  }

  Future<void> toggleCaching(bool value) async {
    _isCachingEnabled = value;
    await _cacheService.setCachingEnabled(value);
    settingsHaveChanged = true;
    notifyListeners();
  }

  Future<void> updateQuestionType(QuestionType newType) async {
    if (_questionType == newType) return;
    _questionType = newType;
    await _cacheService.setQuestionType(newType);
    settingsHaveChanged = true;
    notifyListeners();
  }

  // New methods for theme
  Future<void> updateThemePreference(ThemePreference newPreference) async {
    if (_themePreference == newPreference) return;
    _themePreference = newPreference;
    await _cacheService.setThemePreference(newPreference);
    notifyListeners();
  }

  Future<void> toggleOledMode(bool value) async {
    _isOledMode = value;
    await _cacheService.setOledMode(value);
    notifyListeners();
  }

  Future<void> toggleExcludeActiveQuestions(bool value) async {
    _excludeActiveQuestions = value;
    await _cacheService.setExcludeActiveQuestions(value);
    settingsHaveChanged = true;
    notifyListeners();
  }

  Future<void> clearCache() async {
    await _cacheService.clearSeenQuestions();
    settingsHaveChanged = true;
  }

  void appliedChanges() {
    settingsHaveChanged = false;
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
}
