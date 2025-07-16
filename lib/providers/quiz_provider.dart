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

      List<QuestionIdentifier> allIdentifiers = [];
      final englishParams = {"test": 1, "domain": "INI,CAS,EOI,SEC"};
      final mathParams = {"test": 2, "domain": "H,P,Q,S"};

      switch (questionType) {
        case QuestionType.english:
          allIdentifiers = await _apiService.getAllQuestionIdentifiers(
              test: englishParams['test'] as int,
              domain: englishParams['domain'] as String);
          break;
        case QuestionType.math:
          allIdentifiers = await _apiService.getAllQuestionIdentifiers(
              test: mathParams['test'] as int,
              domain: mathParams['domain'] as String);
          break;
        case QuestionType.both:
          final results = await Future.wait([
            _apiService.getAllQuestionIdentifiers(
                test: englishParams['test'] as int,
                domain: englishParams['domain'] as String),
            _apiService.getAllQuestionIdentifiers(
                test: mathParams['test'] as int,
                domain: mathParams['domain'] as String)
          ]);
          allIdentifiers = results.expand((list) => list).toList();
          break;
      }

      // Exclude active questions if setting is enabled
      if (settingsProvider != null && settingsProvider.excludeActiveQuestions) {
        final liveList = await _apiService.getLiveQuestionIdentifiers();
        final liveIds = [
          ...liveList.mathIds,
          ...liveList.englishIds,
        ].map((q) => q.id).toSet();
        allIdentifiers =
            allIdentifiers.where((id) => !liveIds.contains(id.id)).toList();

        // Exclude questions with type 'ibn'
        allIdentifiers =
            allIdentifiers.where((id) => id.type != IdType.ibn).toList();
      }

      final seenIds = await _cacheService.getSeenQuestionIds();
      // Filter the identifier list based on seen string IDs
      final unseenQuestions = allIdentifiers
          .where((identifier) => !seenIds.contains(identifier.id))
          .toList();

      // Initialize FilterProvider and set questions
      if (filterProvider != null) {
        await filterProvider.initialize();
        filterProvider.setQuestions(unseenQuestions);
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
      final nextIdentifier = _questionPool.removeLast();
      _currentQuestion = await _apiService.getQuestionDetails(nextIdentifier);
      _state = QuizState.ready;
    } catch (e) {
      _state = QuizState.error;
      _errorMessage = "Failed to load the next question.";
    } finally {
      notifyListeners();
    }
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
}
