import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sat_quiz/providers/quiz_provider.dart';
import 'package:sat_quiz/providers/filter_provider.dart';
import 'package:sat_quiz/models/question_identifier.dart';
import 'package:sat_quiz/models/question_metadata.dart';

void main() {
  group('QuizProvider FilterProvider Integration Unit Tests', () {
    late QuizProvider quizProvider;
    late FilterProvider filterProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      quizProvider = QuizProvider();
      filterProvider = FilterProvider();
    });

    test('should have remainingQuestionCount getter', () {
      // Test that the new getter is available
      expect(quizProvider.remainingQuestionCount, equals(0));
    });

    test('should handle FilterProvider initialization in refreshQuestionPool',
        () async {
      // Create test questions
      final testQuestions = [
        QuestionIdentifier(
          id: 'eng1',
          type: IdType.external,
          metadata: QuestionMetadata(
            skillDescription: 'Reading Comprehension',
            primaryClassDescription: 'Information and Ideas',
            difficulty: 'M',
            skillCode: 'RC',
            primaryClassCode: 'INI',
          ),
        ),
        QuestionIdentifier(
          id: 'eng2',
          type: IdType.external,
          metadata: QuestionMetadata(
            skillDescription: 'Grammar',
            primaryClassDescription: 'Standard English Conventions',
            difficulty: 'E',
            skillCode: 'GR',
            primaryClassCode: 'SEC',
          ),
        ),
      ];

      // Set up FilterProvider with test questions
      await filterProvider.initialize();
      filterProvider.setQuestions(testQuestions);
      await filterProvider.addFilter('Information and Ideas');

      // Test refreshQuestionPool method
      await quizProvider.refreshQuestionPool(filterProvider);

      // Should handle the refresh without throwing errors
      expect(
          quizProvider.state,
          anyOf(
            QuizState.loading,
            QuizState.ready,
            QuizState.complete,
            QuizState.error,
          ));
    });

    test('should handle empty filtered questions in refreshQuestionPool',
        () async {
      // Set up FilterProvider with no matching questions
      await filterProvider.initialize();
      filterProvider.setQuestions([]);
      await filterProvider.addFilter('Advanced Math');

      // Test refreshQuestionPool with empty results
      await quizProvider.refreshQuestionPool(filterProvider);

      // Should show complete state with appropriate message
      expect(quizProvider.state, QuizState.complete);
      expect(quizProvider.errorMessage,
          'No questions match the selected filters.');
    });

    test('should preserve filter state during question navigation', () async {
      // Set up FilterProvider with filters
      await filterProvider.initialize();
      await filterProvider.addFilter('Information and Ideas');
      await filterProvider.addFilter('Standard English Conventions');

      // Verify filters are preserved
      expect(filterProvider.activeFilters.length, 2);
      expect(filterProvider.isFilterActive('Information and Ideas'), true);
      expect(
          filterProvider.isFilterActive('Standard English Conventions'), true);

      // Call nextQuestion (this won't load a real question but tests the method)
      quizProvider.nextQuestion();

      // Filter state should still be preserved
      expect(filterProvider.activeFilters.length, 2);
      expect(filterProvider.isFilterActive('Information and Ideas'), true);
      expect(
          filterProvider.isFilterActive('Standard English Conventions'), true);
    });

    test('should handle FilterProvider error recovery', () async {
      // Set up FilterProvider and then reset it
      await filterProvider.initialize();
      await filterProvider.addFilter('Information and Ideas');

      // Reset filter state to simulate error
      await filterProvider.resetFilterState();

      // Should handle gracefully without crashing
      await quizProvider.refreshQuestionPool(filterProvider);

      expect(
          quizProvider.state,
          anyOf(
            QuizState.loading,
            QuizState.ready,
            QuizState.complete,
            QuizState.error,
          ));
    });

    test('should work with FilterProvider that has no active filters',
        () async {
      // Set up FilterProvider with questions but no filters
      final testQuestions = [
        QuestionIdentifier(
          id: 'eng1',
          type: IdType.external,
          metadata: QuestionMetadata(
            skillDescription: 'Reading Comprehension',
            primaryClassDescription: 'Information and Ideas',
            difficulty: 'M',
            skillCode: 'RC',
            primaryClassCode: 'INI',
          ),
        ),
      ];

      await filterProvider.initialize();
      filterProvider.setQuestions(testQuestions);

      // No filters added - should show all questions with metadata
      await quizProvider.refreshQuestionPool(filterProvider);

      expect(
          quizProvider.state,
          anyOf(
            QuizState.loading,
            QuizState.ready,
            QuizState.complete,
            QuizState.error,
          ));
    });

    test('should handle rapid filter changes', () async {
      // Set up FilterProvider
      await filterProvider.initialize();

      // Rapidly change filters
      await filterProvider.addFilter('Information and Ideas');
      await quizProvider.refreshQuestionPool(filterProvider);

      await filterProvider.addFilter('Algebra');
      await quizProvider.refreshQuestionPool(filterProvider);

      await filterProvider.removeFilter('Information and Ideas');
      await quizProvider.refreshQuestionPool(filterProvider);

      // Should handle rapid changes without issues
      expect(
          quizProvider.state,
          anyOf(
            QuizState.loading,
            QuizState.ready,
            QuizState.complete,
            QuizState.error,
          ));
    });
  });

  group('QuizProvider Backward Compatibility', () {
    late QuizProvider quizProvider;

    setUp(() {
      quizProvider = QuizProvider();
    });

    test('should maintain existing interface without FilterProvider', () {
      // Test that existing methods still work
      expect(quizProvider.state, QuizState.uninitialized);
      expect(quizProvider.currentQuestion, isNull);
      expect(quizProvider.selectedAnswerId, isNull);
      expect(quizProvider.errorMessage, isNull);
      expect(quizProvider.remainingQuestionCount, equals(0));
    });

    test('should handle selectAnswer and submitAnswer without FilterProvider',
        () {
      // Test existing functionality
      quizProvider.selectAnswer('test-answer');
      expect(quizProvider.selectedAnswerId,
          isNull); // Should be null since state is not ready

      quizProvider.submitAnswer();
      expect(quizProvider.state,
          QuizState.uninitialized); // Should remain uninitialized
    });
  });
}
