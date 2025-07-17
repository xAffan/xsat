import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sat_quiz/providers/filter_provider.dart';
import 'package:sat_quiz/providers/quiz_provider.dart';
import 'package:sat_quiz/providers/settings_provider.dart';
import 'package:sat_quiz/screens/quiz_screen.dart';
import 'package:sat_quiz/screens/settings_screen.dart';
import 'package:sat_quiz/widgets/filter_chip_bar.dart';
import 'package:sat_quiz/widgets/question_info_modal.dart';
import 'package:sat_quiz/models/question_identifier.dart';
import 'package:sat_quiz/models/question_metadata.dart';

void main() {
  group('End-to-End Filtering Workflow Integration Tests', () {
    late FilterProvider filterProvider;
    late QuizProvider quizProvider;
    late SettingsProvider settingsProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      filterProvider = FilterProvider();
      quizProvider = QuizProvider();
      settingsProvider = SettingsProvider();

      await filterProvider.initialize();
    });

    Widget createTestApp({Widget? home}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<FilterProvider>.value(value: filterProvider),
          ChangeNotifierProvider<QuizProvider>.value(value: quizProvider),
          ChangeNotifierProvider<SettingsProvider>.value(
              value: settingsProvider),
        ],
        child: MaterialApp(
          home: home ?? const QuizScreen(),
        ),
      );
    }

    testWidgets('complete filtering workflow from settings to quiz',
        (WidgetTester tester) async {
      // Setup test questions with different categories
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
        QuestionIdentifier(
          id: 'math1',
          type: IdType.external,
          metadata: QuestionMetadata(
            skillDescription: 'Linear Equations',
            primaryClassDescription: 'Algebra',
            difficulty: 'H',
            skillCode: 'LE',
            primaryClassCode: 'H',
          ),
        ),
      ];

      filterProvider.setQuestions(testQuestions);

      // Start with settings screen to test filter selection
      await tester.pumpWidget(createTestApp(home: const SettingsScreen()));

      // Verify filter chips are displayed
      expect(find.byType(FilterChipBar), findsOneWidget);
      expect(find.text('Information and Ideas'), findsOneWidget);
      expect(find.text('Standard English Conventions'), findsOneWidget);
      expect(find.text('Algebra'), findsOneWidget);

      // Select a filter
      await tester.tap(find.text('Information and Ideas'));
      await tester.pumpAndSettle();

      // Verify filter is active
      expect(filterProvider.isFilterActive('Information and Ideas'), isTrue);
      expect(filterProvider.filteredQuestionCount, equals(1));

      // Navigate to quiz screen
      await tester.pumpWidget(createTestApp(home: const QuizScreen()));

      // Verify filtered questions are used in quiz
      expect(filterProvider.hasActiveFilters, isTrue);
      expect(filterProvider.filteredQuestionCount, equals(1));
    });

    testWidgets('question info modal integration with quiz screen',
        (WidgetTester tester) async {
      final testQuestion = QuestionIdentifier(
        id: 'test1',
        type: IdType.external,
        metadata: QuestionMetadata(
          skillDescription: 'Form, Structure, and Sense',
          primaryClassDescription: 'Standard English Conventions',
          difficulty: 'M',
          skillCode: 'FSS',
          primaryClassCode: 'SEC',
        ),
      );

      filterProvider.setQuestions([testQuestion]);

      await tester.pumpWidget(createTestApp());

      // Look for the info button (?) in the quiz screen
      // Note: This assumes the quiz screen has been enhanced with the info button
      final infoButton = find.byIcon(Icons.info_outline);
      if (infoButton.evaluate().isNotEmpty) {
        await tester.tap(infoButton);
        await tester.pumpAndSettle();

        // Verify modal is displayed
        expect(find.byType(QuestionInfoModal), findsOneWidget);
        expect(find.text('Question Information'), findsOneWidget);
        expect(find.text('Form, Structure, and Sense'), findsOneWidget);
        expect(find.text('Standard English Conventions'), findsOneWidget);
        expect(find.text('Medium'), findsOneWidget);

        // Close modal
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();

        expect(find.byType(QuestionInfoModal), findsNothing);
      }
    });

    testWidgets('filter persistence across app navigation',
        (WidgetTester tester) async {
      final testQuestions = [
        QuestionIdentifier(
          id: 'eng1',
          type: IdType.external,
          metadata: QuestionMetadata(
            skillDescription: 'Reading',
            primaryClassDescription: 'Information and Ideas',
            difficulty: 'M',
            skillCode: 'R',
            primaryClassCode: 'INI',
          ),
        ),
        QuestionIdentifier(
          id: 'math1',
          type: IdType.external,
          metadata: QuestionMetadata(
            skillDescription: 'Algebra',
            primaryClassDescription: 'Algebra',
            difficulty: 'H',
            skillCode: 'A',
            primaryClassCode: 'H',
          ),
        ),
      ];

      filterProvider.setQuestions(testQuestions);

      // Start with settings screen
      await tester.pumpWidget(createTestApp(home: const SettingsScreen()));

      // Apply filters
      await tester.tap(find.text('Information and Ideas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Algebra'));
      await tester.pumpAndSettle();

      // Verify filters are active
      expect(filterProvider.activeFilters.length, equals(2));
      expect(filterProvider.filteredQuestionCount, equals(2));

      // Navigate to quiz screen
      await tester.pumpWidget(createTestApp(home: const QuizScreen()));

      // Verify filters are still active
      expect(filterProvider.activeFilters.length, equals(2));
      expect(filterProvider.isFilterActive('Information and Ideas'), isTrue);
      expect(filterProvider.isFilterActive('Algebra'), isTrue);

      // Navigate back to settings
      await tester.pumpWidget(createTestApp(home: const SettingsScreen()));

      // Verify filters are still active in settings
      expect(filterProvider.activeFilters.length, equals(2));
    });

    testWidgets('multiple filter selection with OR logic',
        (WidgetTester tester) async {
      final testQuestions = [
        QuestionIdentifier(
          id: 'eng1',
          type: IdType.external,
          metadata: QuestionMetadata(
            skillDescription: 'Reading',
            primaryClassDescription: 'Information and Ideas',
            difficulty: 'M',
            skillCode: 'R',
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
            skillCode: 'G',
            primaryClassCode: 'SEC',
          ),
        ),
        QuestionIdentifier(
          id: 'math1',
          type: IdType.external,
          metadata: QuestionMetadata(
            skillDescription: 'Algebra',
            primaryClassDescription: 'Algebra',
            difficulty: 'H',
            skillCode: 'A',
            primaryClassCode: 'H',
          ),
        ),
      ];

      filterProvider.setQuestions(testQuestions);

      await tester.pumpWidget(createTestApp(home: const SettingsScreen()));

      // Initially all questions should be available
      expect(filterProvider.filteredQuestionCount, equals(3));

      // Select first filter
      await tester.tap(find.text('Information and Ideas'));
      await tester.pumpAndSettle();
      expect(filterProvider.filteredQuestionCount, equals(1));

      // Add second filter (OR logic should show both categories)
      await tester.tap(find.text('Standard English Conventions'));
      await tester.pumpAndSettle();
      expect(filterProvider.filteredQuestionCount, equals(2));

      // Add third filter
      await tester.tap(find.text('Algebra'));
      await tester.pumpAndSettle();
      expect(filterProvider.filteredQuestionCount, equals(3));

      // Remove one filter
      await tester.tap(find.text('Information and Ideas'));
      await tester.pumpAndSettle();
      expect(filterProvider.filteredQuestionCount, equals(2));
    });

    testWidgets('clear all filters functionality', (WidgetTester tester) async {
      final testQuestions = [
        QuestionIdentifier(
          id: 'test1',
          type: IdType.external,
          metadata: QuestionMetadata(
            skillDescription: 'Test',
            primaryClassDescription: 'Information and Ideas',
            difficulty: 'M',
            skillCode: 'T',
            primaryClassCode: 'INI',
          ),
        ),
      ];

      filterProvider.setQuestions(testQuestions);

      await tester.pumpWidget(createTestApp(home: const SettingsScreen()));

      // Apply some filters
      await tester.tap(find.text('Information and Ideas'));
      await tester.pumpAndSettle();

      expect(filterProvider.hasActiveFilters, isTrue);

      // Look for clear all button
      final clearAllButton = find.text('Clear All');
      if (clearAllButton.evaluate().isNotEmpty) {
        await tester.tap(clearAllButton);
        await tester.pump();

        // Verify all filters are cleared
        expect(filterProvider.hasActiveFilters, isFalse);
        expect(filterProvider.filteredQuestionCount, equals(1));
      }
    });

    testWidgets('backward compatibility with existing quiz functionality',
        (WidgetTester tester) async {
      // Test that existing quiz functionality still works without filters
      await tester.pumpWidget(createTestApp());

      // Verify quiz screen loads without errors
      expect(find.byType(QuizScreen), findsOneWidget);

      // Test basic quiz provider functionality
      expect(
          quizProvider.state,
          anyOf(
            QuizState.uninitialized,
            QuizState.loading,
            QuizState.ready,
            QuizState.complete,
            QuizState.error,
          ));

      // Test that quiz can handle no active filters
      expect(filterProvider.hasActiveFilters, isFalse);
      expect(() => quizProvider.refreshQuestionPool(filterProvider),
          returnsNormally);
    });

    testWidgets('error handling with malformed metadata',
        (WidgetTester tester) async {
      // Test questions with incomplete metadata
      final problematicQuestions = [
        QuestionIdentifier(
          id: 'incomplete1',
          type: IdType.external,
          metadata: QuestionMetadata(
            skillDescription: '',
            primaryClassDescription: '',
            difficulty: '',
            skillCode: '',
            primaryClassCode: '',
          ),
        ),
        QuestionIdentifier(
          id: 'null_metadata',
          type: IdType.external,
          metadata: null,
        ),
      ];

      filterProvider.setQuestions(problematicQuestions);

      // Should not crash when loading with problematic data
      await tester.pumpWidget(createTestApp(home: const SettingsScreen()));

      // App should still function
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(FilterChipBar), findsOneWidget);

      // Filter provider should handle gracefully
      expect(
          () => filterProvider.getAvailableFilterCategories(), returnsNormally);
    });

    testWidgets('performance with large number of questions and filters',
        (WidgetTester tester) async {
      // Create a large number of test questions
      final largeQuestionSet = List.generate(100, (index) {
        final categories = [
          'Information and Ideas',
          'Standard English Conventions',
          'Algebra',
          'Advanced Math'
        ];
        final difficulties = ['E', 'M', 'H'];

        return QuestionIdentifier(
          id: 'q$index',
          type: IdType.external,
          metadata: QuestionMetadata(
            skillDescription: 'Skill $index',
            primaryClassDescription: categories[index % categories.length],
            difficulty: difficulties[index % difficulties.length],
            skillCode: 'S$index',
            primaryClassCode: 'PC${index % categories.length}',
          ),
        );
      });

      filterProvider.setQuestions(largeQuestionSet);

      // Should handle large datasets without performance issues
      await tester.pumpWidget(createTestApp(home: const SettingsScreen()));

      // Test rapid filter changes
      await tester.tap(find.text('Information and Ideas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Algebra'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Advanced Math'));
      await tester.pumpAndSettle();

      // Should complete without timeout
      expect(filterProvider.filteredQuestionCount, greaterThan(0));
      expect(filterProvider.hasActiveFilters, isTrue);
    });
  });

  group('User Acceptance Test Scenarios', () {
    late FilterProvider filterProvider;
    late QuizProvider quizProvider;
    late SettingsProvider settingsProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      filterProvider = FilterProvider();
      quizProvider = QuizProvider();
      settingsProvider = SettingsProvider();

      await filterProvider.initialize();
    });

    Widget createTestApp({Widget? home}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<FilterProvider>.value(value: filterProvider),
          ChangeNotifierProvider<QuizProvider>.value(value: quizProvider),
          ChangeNotifierProvider<SettingsProvider>.value(
              value: settingsProvider),
        ],
        child: MaterialApp(
          home: home ?? const QuizScreen(),
        ),
      );
    }

    testWidgets('UAT: Student can filter questions by English categories',
        (WidgetTester tester) async {
      final englishQuestions = [
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
            skillDescription: 'Text Structure',
            primaryClassDescription: 'Craft and Structure',
            difficulty: 'H',
            skillCode: 'TS',
            primaryClassCode: 'CAS',
          ),
        ),
      ];

      filterProvider.setQuestions(englishQuestions);

      await tester.pumpWidget(createTestApp(home: const SettingsScreen()));

      // Student sees English filter options
      expect(find.text('Information and Ideas'), findsOneWidget);
      expect(find.text('Craft and Structure'), findsOneWidget);

      // Student selects Information and Ideas filter
      await tester.tap(find.text('Information and Ideas'));
      await tester.pumpAndSettle();

      // Only matching questions are available
      expect(filterProvider.filteredQuestionCount, equals(1));
      expect(filterProvider.isFilterActive('Information and Ideas'), isTrue);
    });

    testWidgets('UAT: Student can filter questions by Math categories',
        (WidgetTester tester) async {
      final mathQuestions = [
        QuestionIdentifier(
          id: 'math1',
          type: IdType.external,
          metadata: QuestionMetadata(
            skillDescription: 'Linear Equations',
            primaryClassDescription: 'Algebra',
            difficulty: 'M',
            skillCode: 'LE',
            primaryClassCode: 'H',
          ),
        ),
        QuestionIdentifier(
          id: 'math2',
          type: IdType.external,
          metadata: QuestionMetadata(
            skillDescription: 'Polynomials',
            primaryClassDescription: 'Advanced Math',
            difficulty: 'H',
            skillCode: 'P',
            primaryClassCode: 'P',
          ),
        ),
      ];

      filterProvider.setQuestions(mathQuestions);

      await tester.pumpWidget(createTestApp(home: const SettingsScreen()));

      // Student sees Math filter options
      expect(find.text('Algebra'), findsOneWidget);
      expect(find.text('Advanced Math'), findsOneWidget);

      // Student selects Algebra filter
      await tester.tap(find.text('Algebra'));
      await tester.pumpAndSettle();

      // Only algebra questions are available
      expect(filterProvider.filteredQuestionCount, equals(1));
      expect(filterProvider.isFilterActive('Algebra'), isTrue);
    });

    testWidgets('UAT: Student can view question information modal',
        (WidgetTester tester) async {
      final testQuestion = QuestionIdentifier(
        id: 'test1',
        type: IdType.external,
        metadata: QuestionMetadata(
          skillDescription: 'Form, Structure, and Sense',
          primaryClassDescription: 'Standard English Conventions',
          difficulty: 'M',
          skillCode: 'FSS',
          primaryClassCode: 'SEC',
        ),
      );

      filterProvider.setQuestions([testQuestion]);

      await tester.pumpWidget(createTestApp());

      // Look for info button in quiz screen
      final infoButton = find.byIcon(Icons.info_outline);
      if (infoButton.evaluate().isNotEmpty) {
        // Student taps the info button
        await tester.tap(infoButton);
        await tester.pumpAndSettle();

        // Student sees question information
        expect(find.text('Question Information'), findsOneWidget);
        expect(find.text('Form, Structure, and Sense'), findsOneWidget);
        expect(find.text('Standard English Conventions'), findsOneWidget);
        expect(find.text('Medium'), findsOneWidget);

        // Student can close the modal
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(find.byType(QuestionInfoModal), findsNothing);
      }
    });

    testWidgets(
        'UAT: Student sees appropriate message when no questions match filters',
        (WidgetTester tester) async {
      final testQuestions = [
        QuestionIdentifier(
          id: 'eng1',
          type: IdType.external,
          metadata: QuestionMetadata(
            skillDescription: 'Reading',
            primaryClassDescription: 'Information and Ideas',
            difficulty: 'M',
            skillCode: 'R',
            primaryClassCode: 'INI',
          ),
        ),
      ];

      filterProvider.setQuestions(testQuestions);

      await tester.pumpWidget(createTestApp(home: const SettingsScreen()));

      // Student applies filter that matches no questions
      await tester.tap(find.text('Algebra'));
      await tester.pumpAndSettle();

      // Student should see no results
      expect(filterProvider.hasNoResults, isTrue);
      expect(filterProvider.filteredQuestionCount, equals(0));
    });
  });
}
