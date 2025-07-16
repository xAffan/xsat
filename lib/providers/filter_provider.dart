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

  // Active filter categories (user-friendly names)
  Set<String> _activeFilters = <String>{};

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
  QuestionType _currentQuestionType = QuestionType.both;
  bool _excludeActiveQuestions = false;

  /// Get current active filters
  Set<String> get activeFilters => Set.unmodifiable(_activeFilters);

  /// Get filtered questions based on active filters
  List<QuestionIdentifier> get filteredQuestions =>
      List.unmodifiable(_filteredQuestions);

  /// Get original unfiltered questions
  List<QuestionIdentifier> get originalQuestions =>
      List.unmodifiable(_originalQuestions);

  /// Check if any filters are active
  bool get hasActiveFilters => _activeFilters.isNotEmpty;

  /// Get count of active filters
  int get activeFilterCount => _activeFilters.length;

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
  void setQuestionsWithMetadata(
    List<QuestionIdentifier> questions,
    Set<String> liveQuestionIds,
    QuestionType questionType,
    bool excludeActiveQuestions,
  ) {
    _originalQuestions = List.from(questions);
    _liveQuestionIds = Set.from(liveQuestionIds);
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
    if (_activeFilters.isNotEmpty) {
      _activeFilters.clear();
      await _saveFiltersToPreferences();
      _applyFilters();
      notifyListeners();
    }
  }

  /// Check if a specific filter is active
  bool isFilterActive(String category) {
    return _activeFilters.contains(category);
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
      return '$_totalQuestionCount questions';
    }
  }

  /// Get available filter categories based on question metadata
  /// Returns categories that have at least one question with matching metadata
  List<String> getAvailableFilterCategories() {
    final availableCategories = <String>{};

    for (final question in _originalQuestions) {
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

    for (final question in _originalQuestions) {
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

    if (_activeFilters.isEmpty) {
      // No category filters active, show all questions with metadata
      _filteredQuestions = questionsWithMetadata;
    } else {
      // Apply OR logic: question matches if it belongs to ANY active filter category
      _filteredQuestions = workingSet.where((question) {
        if (question.metadata?.primaryClassCode == null) {
          return false; // Exclude questions without metadata
        }

        final questionCategory = CategoryMappingService.getUserFriendlyCategory(
            question.metadata!.primaryClassCode);

        return _activeFilters.contains(questionCategory);
      }).toList();
    }

    // Update filtered count
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
      final filtersJson = prefs.getString(_filterPrefsKey);

      if (filtersJson != null) {
        final filtersList = List<String>.from(json.decode(filtersJson));
        _activeFilters = filtersList.toSet();
        _applyFilters();
      }
    } catch (e) {
      debugPrint('Error loading filters from preferences: $e');
      // Reset to empty filters on error
      _activeFilters.clear();
    }
  }

  /// Save filters to SharedPreferences
  Future<void> _saveFiltersToPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filtersJson = json.encode(_activeFilters.toList());
      await prefs.setString(_filterPrefsKey, filtersJson);
    } catch (e) {
      debugPrint('Error saving filters to preferences: $e');
    }
  }

  /// Reset filter state (useful for error recovery)
  Future<void> resetFilterState() async {
    _activeFilters.clear();
    _filteredQuestions.clear();
    _originalQuestions.clear();
    _filtersLoaded = false;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_filterPrefsKey);
    } catch (e) {
      debugPrint('Error clearing filter preferences: $e');
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _activeFilters.clear();
    _originalQuestions.clear();
    _filteredQuestions.clear();
    super.dispose();
  }
}
