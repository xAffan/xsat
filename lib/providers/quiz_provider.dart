// lib/providers/quiz_provider.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/question.dart';
import '../models/question_identifier.dart'; // Import new model
import '../services/api_service.dart';
import '../services/cache_service.dart';
import 'settings_provider.dart';
import 'filter_provider.dart';

enum QuizState { loading, error, ready, answered, complete, uninitialized }

class QuizProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final CacheService _cacheService = CacheService();

  // The pool is now a list of typed identifiers
  List<QuestionIdentifier> _questionPool = [];
  Question? _currentQuestion;
  QuizState _state = QuizState.uninitialized;
  String? _selectedAnswerId;
  String? _errorMessage;

  Question? get currentQuestion => _currentQuestion;
  QuizState get state => _state;
  String? get selectedAnswerId => _selectedAnswerId;
  String? get errorMessage => _errorMessage;
  int get remainingQuestionCount => _questionPool.length;

  Future<void> initializeQuiz(QuestionType questionType,
      {SettingsProvider? settingsProvider,
      FilterProvider? filterProvider}) async {
    try {
      _state = QuizState.loading;
      notifyListeners();

      // Always fetch BOTH English and Math questions
      final englishParams = {"test": 1, "domain": "INI,CAS,EOI,SEC"};
      final mathParams = {"test": 2, "domain": "H,P,Q,S"};

      final results = await Future.wait([
        _apiService.getAllQuestionIdentifiers(
            test: englishParams['test'] as int,
            domain: englishParams['domain'] as String),
        _apiService.getAllQuestionIdentifiers(
            test: mathParams['test'] as int,
            domain: mathParams['domain'] as String)
      ]);

      List<QuestionIdentifier> allIdentifiers =
          results.expand((list) => list).toList();

      // Pre-fetch excluded questions list (always, regardless of setting)
      final liveList = await _apiService.getLiveQuestionIdentifiers();
      final liveIds = [
        ...liveList.mathIds,
        ...liveList.englishIds,
      ].map((q) => q.id).toSet();

      final seenIds = (await _cacheService.getSeenQuestionIds()).toSet();
      // Filter the identifier list based on seen string IDs
      final unseenQuestions = allIdentifiers
          .where((identifier) => !seenIds.contains(identifier.id))
          .toList();

      // Initialize FilterProvider and set questions
      if (filterProvider != null) {
        await filterProvider.initialize();
        // Set questions with additional metadata for filtering
        filterProvider.setQuestionsWithMetadata(
            questions: allIdentifiers,
            liveQuestionIds: liveIds,
            seenQuestionIds: seenIds,
            questionType:
                settingsProvider?.questionType ?? QuestionType.both,
            excludeActiveQuestions:
                settingsProvider?.excludeActiveQuestions ?? false);
        _questionPool = List.from(filterProvider.filteredQuestions);
      } else {
        _questionPool = unseenQuestions;
      }

      // Check if filtered question pool is empty
      if (_questionPool.isEmpty &&
          filterProvider != null &&
          filterProvider.hasActiveFilters) {
        _state = QuizState.complete;
        _errorMessage = "No questions match the selected filters.";
        notifyListeners();
        return;
      }

      _questionPool.shuffle(Random());

      await _loadNextQuestion();
    } catch (e) {
      _state = QuizState.error;
      _errorMessage =
          "Could not start the quiz. Please check your connection. $e";
      notifyListeners();
    }
  }

  Future<void> _loadNextQuestion() async {
    if (_questionPool.isEmpty) {
      _state = QuizState.complete;
      notifyListeners();
      return;
    }

    _state = QuizState.loading;
    _selectedAnswerId = null;
    notifyListeners(); // Notify UI that we are loading the next question

    try {
      final nextIdentifier = _selectNextQuestionBalanced();
      _currentQuestion = await _apiService.getQuestionDetails(nextIdentifier);
      _state = QuizState.ready;
    } catch (e) {
      _state = QuizState.error;
      _errorMessage = "Failed to load the next question.";
    } finally {
      notifyListeners();
    }
  }

  /// Selects the next question with balanced English/Math distribution when content type is 'both'
  QuestionIdentifier _selectNextQuestionBalanced() {
    if (_questionPool.isEmpty) {
      throw StateError('Question pool is empty');
    }

    // If only one question left, return it
    if (_questionPool.length == 1) {
      return _questionPool.removeLast();
    }

    // Separate English and Math questions
    final englishQuestions = _questionPool
        .where((q) => q.subjectType == QuestionType.english)
        .toList();
    final mathQuestions =
        _questionPool.where((q) => q.subjectType == QuestionType.math).toList();

    // If we only have one type of question, select from available pool
    if (englishQuestions.isEmpty && mathQuestions.isNotEmpty) {
      final selected = mathQuestions[Random().nextInt(mathQuestions.length)];
      _questionPool.remove(selected);
      return selected;
    }

    if (mathQuestions.isEmpty && englishQuestions.isNotEmpty) {
      final selected =
          englishQuestions[Random().nextInt(englishQuestions.length)];
      _questionPool.remove(selected);
      return selected;
    }

    // If we have both types, implement 50/50 logic
    if (englishQuestions.isNotEmpty && mathQuestions.isNotEmpty) {
      // Simple 50/50 random selection
      final useEnglish = Random().nextBool();

      final selectedPool = useEnglish ? englishQuestions : mathQuestions;
      final selected = selectedPool[Random().nextInt(selectedPool.length)];
      _questionPool.remove(selected);
      return selected;
    }

    // Fallback: just remove the last question (shouldn't reach here)
    return _questionPool.removeLast();
  }

  void nextQuestion() {
    if (_currentQuestion != null) {
      // Cache the unique ID from the Question object
      _cacheService.addSeenQuestionId(_currentQuestion!.externalId);
    }
    _loadNextQuestion();
  }

  // selectAnswer and submitAnswer remain unchanged
  void selectAnswer(String answerId) {
    if (_state == QuizState.ready) {
      _selectedAnswerId = answerId;
      notifyListeners();
    }
  }

  void submitAnswer() {
    if (_selectedAnswerId != null) {
      _state = QuizState.answered;
      notifyListeners();
    }
  }

  /// Refresh question pool when filters change
  Future<void> refreshQuestionPool(FilterProvider filterProvider) async {
    try {
      _state = QuizState.loading;
      notifyListeners();

      // Get filtered questions from FilterProvider
      _questionPool = List.from(filterProvider.filteredQuestions);

      // Remove current question from pool if it exists to avoid duplication
      if (_currentQuestion != null) {
        _questionPool.removeWhere((q) => q.id == _currentQuestion!.externalId);
      }

      _questionPool.shuffle(Random());

      // If no questions match filters, show complete state
      if (_questionPool.isEmpty) {
        _state = QuizState.complete;
        _errorMessage = "No questions match the selected filters.";
      } else {
        // If we have a current question and it matches filters, keep it
        // Otherwise load next question
        if (_currentQuestion != null &&
            filterProvider.filteredQuestions
                .any((q) => q.id == _currentQuestion!.externalId)) {
          _state = QuizState.ready;
        } else {
          await _loadNextQuestion();
        }
      }

      notifyListeners();
    } catch (e) {
      _state = QuizState.error;
      _errorMessage = "Failed to refresh question pool.";
      notifyListeners();
    }
  }

  /// Updates the question pool based on current filter state
  /// This allows instant filter changes without restarting the quiz
  void updateQuestionPool(FilterProvider filterProvider) {
    if (_state == QuizState.uninitialized || _state == QuizState.loading) {
      return; // Can't update pool if not initialized
    }

    final newQuestionPool = filterProvider.filteredQuestions;

    // Check if the current question is still in the pool
    final currentQuestionInPool = _currentQuestion != null &&
        newQuestionPool.any((q) => q.id == _currentQuestion!.externalId);

    if (!currentQuestionInPool && _currentQuestion != null) {
      // Current question is no longer in the pool, need to load a new one
      _questionPool = List.from(newQuestionPool);
      if (_questionPool.isNotEmpty) {
        _questionPool.shuffle(Random());
        _loadNextQuestion();
      } else {
        _state = QuizState.complete;
        _errorMessage = "No questions match the selected filters.";
        _currentQuestion = null;
      }
    } else {
      // Current question is still valid, just update the pool
      _questionPool = List.from(newQuestionPool);
      if (_questionPool.isEmpty) {
        _state = QuizState.complete;
        _errorMessage = "No questions match the selected filters.";
      } else {
        _questionPool.shuffle(Random());
      }
    }

    notifyListeners();
  }
}
