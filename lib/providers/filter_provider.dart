import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question_identifier.dart';
import '../services/category_mapping_service.dart';
import '../providers/settings_provider.dart';

/// Provider for managing filter state and filtering questions by categories
/// Supports persistence across app sessions and OR logic for multiple filters
class FilterProvider extends ChangeNotifier {
  static const String _filterPrefsKey = 'active_filters';
  static const String _difficultyFilterPrefsKey = 'active_difficulty_filters';

  // Active filter categories (user-friendly names)
  Set<String> _activeFilters = <String>{};

  // Active difficulty filters
  Set<String> _activeDifficultyFilters = <String>{};

  // Original unfiltered question list
  List<QuestionIdentifier> _originalQuestions = [];

  // Cached filtered questions to avoid recomputation
  List<QuestionIdentifier> _filteredQuestions = [];

  // Flag to track if filters have been loaded from preferences
  bool _filtersLoaded = false;

  // Total count of questions with valid metadata
  int _totalQuestionCount = 0;

  // Count of questions after applying filters
  int _filteredQuestionCount = 0;

  // Additional filtering metadata
  Set<String> _liveQuestionIds = <String>{};
  Set<String> _seenQuestionIds = <String>{};
  QuestionType _currentQuestionType = QuestionType.both;
  bool _excludeActiveQuestions = false;

  /// Get current active filters
  Set<String> get activeFilters => Set.unmodifiable(_activeFilters);

  /// Get current active difficulty filters
  Set<String> get activeDifficultyFilters =>
      Set.unmodifiable(_activeDifficultyFilters);

  /// Get filtered questions based on active filters
  List<QuestionIdentifier> get filteredQuestions =>
      List.unmodifiable(_filteredQuestions);

  /// Get original unfiltered questions
  List<QuestionIdentifier> get originalQuestions =>
      List.unmodifiable(_originalQuestions);

  /// Check if any filters are active
  bool get hasActiveFilters =>
      _activeFilters.isNotEmpty || _activeDifficultyFilters.isNotEmpty;

  /// Get count of active filters
  int get activeFilterCount =>
      _activeFilters.length + _activeDifficultyFilters.length;

  /// Get total count of questions with valid metadata
  int get totalQuestionCount => _totalQuestionCount;

  /// Get count of questions after applying filters
  int get filteredQuestionCount => _filteredQuestionCount;

  /// Get the appropriate question count based on filter state
  /// Returns filtered count when filters are active, otherwise total count
  int get displayedQuestionCount =>
      hasActiveFilters ? _filteredQuestionCount : _totalQuestionCount;

  /// Initialize the provider and load persisted filters
  Future<void> initialize() async {
    if (!_filtersLoaded) {
      await _loadFiltersFromPreferences();
      _filtersLoaded = true;
    }
  }

  /// Set the original question list and apply current filters
  void setQuestions(List<QuestionIdentifier> questions) {
    _originalQuestions = List.from(questions);
    _applyFilters();
    notifyListeners(); // Notify listeners so UI updates immediately
  }

  /// Set questions with additional filtering metadata for subject type and exclude active
  void setQuestionsWithMetadata({
    required List<QuestionIdentifier> questions,
    required Set<String> liveQuestionIds,
    required Set<String> seenQuestionIds,
    required QuestionType questionType,
    required bool excludeActiveQuestions,
  }) {
    _originalQuestions = List.from(questions);
    _liveQuestionIds = Set.from(liveQuestionIds);
    _seenQuestionIds = Set.from(seenQuestionIds);
    _currentQuestionType = questionType;
    _excludeActiveQuestions = excludeActiveQuestions;
    _applyFilters();
    notifyListeners(); // Notify listeners so UI updates immediately
  }

  /// Update subject type filter and reapply filters
  void updateQuestionType(QuestionType questionType) {
    if (_currentQuestionType != questionType) {
      _currentQuestionType = questionType;
      _applyFilters();
      notifyListeners();
    }
  }

  /// Update exclude active questions filter and reapply filters
  void updateExcludeActiveQuestions(bool excludeActive) {
    if (_excludeActiveQuestions != excludeActive) {
      _excludeActiveQuestions = excludeActive;
      _applyFilters();
      notifyListeners();
    }
  }

  /// Add a filter category
  Future<void> addFilter(String category) async {
    if (!CategoryMappingService.isValidCategory(category)) {
      debugPrint('Warning: Invalid filter category: $category');
      return;
    }

    if (_activeFilters.add(category)) {
      await _saveFiltersToPreferences();
      _applyFilters();
      notifyListeners();
    }
  }

  /// Remove a filter category
  Future<void> removeFilter(String category) async {
    if (_activeFilters.remove(category)) {
      await _saveFiltersToPreferences();
      _applyFilters();
      notifyListeners();
    }
  }

  /// Toggle a filter category (add if not present, remove if present)
  Future<void> toggleFilter(String category) async {
    if (_activeFilters.contains(category)) {
      await removeFilter(category);
    } else {
      await addFilter(category);
    }
  }

  /// Clear all active filters
  Future<void> clearFilters() async {
    bool hasChanges = false;
    if (_activeFilters.isNotEmpty) {
      _activeFilters.clear();
      hasChanges = true;
    }
    if (_activeDifficultyFilters.isNotEmpty) {
      _activeDifficultyFilters.clear();
      hasChanges = true;
    }
    if (hasChanges) {
      await _saveFiltersToPreferences();
      _applyFilters();
      notifyListeners();
    }
  }

  /// Check if a specific filter is active
  bool isFilterActive(String category) {
    return _activeFilters.contains(category);
  }

  /// Add a difficulty filter
  Future<void> addDifficultyFilter(String difficulty) async {
    if (_activeDifficultyFilters.add(difficulty)) {
      await _saveFiltersToPreferences();
      _applyFilters();
      notifyListeners();
    }
  }

  /// Remove a difficulty filter
  Future<void> removeDifficultyFilter(String difficulty) async {
    if (_activeDifficultyFilters.remove(difficulty)) {
      await _saveFiltersToPreferences();
      _applyFilters();
      notifyListeners();
    }
  }

  /// Toggle a difficulty filter
  Future<void> toggleDifficultyFilter(String difficulty) async {
    if (_activeDifficultyFilters.contains(difficulty)) {
      await removeDifficultyFilter(difficulty);
    } else {
      await addDifficultyFilter(difficulty);
    }
  }

  /// Check if a specific difficulty filter is active
  bool isDifficultyFilterActive(String difficulty) {
    return _activeDifficultyFilters.contains(difficulty);
  }

  /// Check if current filters result in no questions
  bool get hasNoResults =>
      _filteredQuestions.isEmpty && _originalQuestions.isNotEmpty;

  /// Format question count text based on filter state
  /// Returns "X of Y questions" when filters are active, otherwise "X questions"
  String getQuestionCountText() {
    if (hasActiveFilters) {
      return '$_filteredQuestionCount of $_totalQuestionCount questions';
    } else {
      return '$_filteredQuestionCount of $_totalQuestionCount questions';
    }
  }

  /// Get available filter categories based on question metadata
  /// Returns categories that have at least one question with matching metadata
  List<String> getAvailableFilterCategories() {
    final availableCategories = <String>{};
    final questionsToConsider = _getQuestionsForCountCalculation();

    for (final question in questionsToConsider) {
      if (question.metadata?.primaryClassCode != null) {
        final userFriendlyCategory =
            CategoryMappingService.getUserFriendlyCategory(
                question.metadata!.primaryClassCode);

        // Only add if it's a valid category in our mapping
        if (CategoryMappingService.isValidCategory(userFriendlyCategory)) {
          availableCategories.add(userFriendlyCategory);
        }
      }
    }

    return availableCategories.toList()..sort();
  }

  /// Get available filter categories for a specific subject type
  List<String> getAvailableFilterCategoriesForSubject(String subjectType) {
    final subjectCategories =
        CategoryMappingService.getFilterableCategories(subjectType);
    final availableCategories = getAvailableFilterCategories();

    return subjectCategories
        .where((category) => availableCategories.contains(category))
        .toList();
  }

  /// Get count of questions for each available category
  Map<String, int> getCategoryQuestionCounts() {
    final counts = <String, int>{};
    final questionsToCount = _getQuestionsForCountCalculation();

    for (final question in questionsToCount) {
      if (question.metadata?.primaryClassCode != null) {
        final userFriendlyCategory =
            CategoryMappingService.getUserFriendlyCategory(
                question.metadata!.primaryClassCode);

        if (CategoryMappingService.isValidCategory(userFriendlyCategory)) {
          counts[userFriendlyCategory] =
              (counts[userFriendlyCategory] ?? 0) + 1;
        }
      }
    }

    return counts;
  }

  /// Get available difficulty levels based on question metadata
  List<String> getAvailableDifficultyLevels() {
    final availableDifficulties = <String>{};
    final questionsToConsider = _getQuestionsForCountCalculation();

    for (final question in questionsToConsider) {
      if (question.metadata?.difficulty != null) {
        availableDifficulties.add(question.metadata!.difficulty);
      }
    }

    // Return in order: Easy, Medium, Hard
    final orderedDifficulties = ['E', 'M', 'H'];
    return orderedDifficulties
        .where((d) => availableDifficulties.contains(d))
        .toList();
  }

  /// Get count of questions for each available difficulty level
  Map<String, int> getDifficultyQuestionCounts() {
    final counts = <String, int>{};
    final questionsToCount = _getQuestionsForCountCalculation();

    for (final question in questionsToCount) {
      if (question.metadata?.difficulty != null) {
        final difficulty = question.metadata!.difficulty;
        counts[difficulty] = (counts[difficulty] ?? 0) + 1;
      }
    }

    return counts;
  }

  List<QuestionIdentifier> _getQuestionsForCountCalculation() {
    List<QuestionIdentifier> questions = _originalQuestions;

    // Apply subject type filter
    if (_currentQuestionType != QuestionType.both) {
      questions = questions.where((q) {
        return q.subjectType == _currentQuestionType;
      }).toList();
    }

    // Apply live question filter
    if (_excludeActiveQuestions) {
      questions = questions.where((q) {
        return !_liveQuestionIds.contains(q.id);
      }).toList();
    }

    return questions;
  }

  /// Apply current filters to the question list using OR logic
  /// Updates both filtered and total question counts
  void _applyFilters() {
    // Start with all questions and apply subject type filter first
    List<QuestionIdentifier> workingSet = _originalQuestions;

    // Apply subject type filter
    if (_currentQuestionType != QuestionType.both) {
      workingSet = workingSet.where((question) {
        if (_currentQuestionType == QuestionType.english) {
          return question.subjectType == QuestionType.english;
        } else if (_currentQuestionType == QuestionType.math) {
          return question.subjectType == QuestionType.math;
        }
        return true; // Should not reach here given the condition above
      }).toList();
    }

    // Apply exclude active questions filter
    if (_excludeActiveQuestions) {
      workingSet = workingSet.where((question) {
        return !_liveQuestionIds.contains(question.id);
      }).toList();
    }

    // Calculate total questions with valid metadata (after subject and exclusion filters)
    final questionsWithMetadata = workingSet.where((question) {
      return question.metadata?.primaryClassCode != null;
    }).toList();

    _totalQuestionCount = questionsWithMetadata.length;

    List<QuestionIdentifier> matchedQuestions;
    if (_activeFilters.isEmpty && _activeDifficultyFilters.isEmpty) {
      // No filters active, all questions with metadata are considered matched
      matchedQuestions = questionsWithMetadata;
    } else {
      // Apply OR logic within each filter type, AND logic between filter types
      matchedQuestions = questionsWithMetadata.where((question) {
        bool categoryMatch = true;
        bool difficultyMatch = true;

        // Check category filter (if any active)
        if (_activeFilters.isNotEmpty) {
          final questionCategory =
              CategoryMappingService.getUserFriendlyCategory(
                  question.metadata!.primaryClassCode);
          categoryMatch = _activeFilters.contains(questionCategory);
        }

        // Check difficulty filter (if any active)
        if (_activeDifficultyFilters.isNotEmpty) {
          final questionDifficulty = question.metadata!.difficulty;
          difficultyMatch =
              _activeDifficultyFilters.contains(questionDifficulty);
        }

        // Question must match both category and difficulty filters (if active)
        return categoryMatch && difficultyMatch;
      }).toList();
    }

    // Update filtered questions and count
    _filteredQuestions = matchedQuestions;
    _filteredQuestionCount = _filteredQuestions.length;
  }

  /// Manually update question counts
  /// Useful when question data changes externally
  void updateQuestionCounts(int total, int filtered) {
    _totalQuestionCount = total;
    _filteredQuestionCount = filtered;
    notifyListeners();
  }

  /// Load filters from SharedPreferences
  Future<void> _loadFiltersFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load category filters
      final filtersJson = prefs.getString(_filterPrefsKey);
      if (filtersJson != null) {
        final filtersList = List<String>.from(json.decode(filtersJson));
        _activeFilters = filtersList.toSet();
      }

      // Load difficulty filters
      final difficultyFiltersJson = prefs.getString(_difficultyFilterPrefsKey);
      if (difficultyFiltersJson != null) {
        final difficultyFiltersList =
            List<String>.from(json.decode(difficultyFiltersJson));
        _activeDifficultyFilters = difficultyFiltersList.toSet();
      }

      _applyFilters();
    } catch (e) {
      debugPrint('Error loading filters from preferences: $e');
      // Reset to empty filters on error
      _activeFilters.clear();
      _activeDifficultyFilters.clear();
    }
  }

  /// Save filters to SharedPreferences
  Future<void> _saveFiltersToPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save category filters
      final filtersJson = json.encode(_activeFilters.toList());
      await prefs.setString(_filterPrefsKey, filtersJson);

      // Save difficulty filters
      final difficultyFiltersJson =
          json.encode(_activeDifficultyFilters.toList());
      await prefs.setString(_difficultyFilterPrefsKey, difficultyFiltersJson);
    } catch (e) {
      debugPrint('Error saving filters to preferences: $e');
    }
  }

  /// Reset filter state (useful for error recovery)
  Future<void> resetFilterState() async {
    _activeFilters.clear();
    _activeDifficultyFilters.clear();
    _filteredQuestions.clear();
    _originalQuestions.clear();
    _filtersLoaded = false;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_filterPrefsKey);
      await prefs.remove(_difficultyFilterPrefsKey);
    } catch (e) {
      debugPrint('Error clearing filter preferences: $e');
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _activeFilters.clear();
    _activeDifficultyFilters.clear();
    _originalQuestions.clear();
    _filteredQuestions.clear();
    super.dispose();
  }
}
