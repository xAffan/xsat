import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sat_quiz/providers/filter_provider.dart';
import 'package:sat_quiz/providers/quiz_provider.dart';
import 'package:sat_quiz/providers/settings_provider.dart';
import 'package:sat_quiz/widgets/no_results_widget.dart';
import 'package:sat_quiz/screens/quiz_screen.dart';
import 'package:sat_quiz/models/question_identifier.dart';
import 'package:sat_quiz/models/question_metadata.dart';

void main() {
  group('No Results Integration Tests', () {
    late FilterProvider filterProvider;
    late QuizProvider quizProvider;
    late SettingsProvider settingsProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      filterProvider = FilterProvider();
      quizProvider = QuizProvider();
      settingsProvider = SettingsProvider();
    });

    Widget createTestApp({Widget? child}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<FilterProvider>.value(value: filterProvider),
          ChangeNotifierProvider<QuizProvider>.value(value: quizProvider),
          ChangeNotifierProvider<SettingsProvider>.value(
              value: settingsProvider),
        ],
        child: MaterialApp(
          home: child ?? const QuizScreen(),
        ),
      );
    }

    testWidgets(
        'should show NoResultsWidget when filters result in no questions',
        (WidgetTester tester) async {
      // Setup questions that don't match the filter we'll apply
      final testQuestions = [
        QuestionIdentifier(
          id: '1',
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

      // Set questions and apply a filter that won't match
      filterProvider.setQuestions(testQuestions);
      await filterProvider
          .addFilter('Algebra'); // Won't match the English question

      // Simulate quiz state that would show no results
      // Note: In a real integration test, we'd need to mock the API service
      // For this test, we'll directly set the quiz state to complete with no results message

      await tester.pumpWidget(createTestApp(
        child: Scaffold(
          body: NoResultsWidget(
            hasActiveFilters: filterProvider.hasActiveFilters,
            onClearFilters: () => filterProvider.clearFilters(),
            onRestart: () {},
            customMessage: 'No questions match the selected filters.',
          ),
        ),
      ));

      // Verify the no results widget is displayed
      expect(find.text('No Questions Found'), findsOneWidget);
      expect(find.text('No questions match the selected filters.'),
          findsOneWidget);
      expect(find.byIcon(Icons.filter_list_off), findsOneWidget);
      expect(find.text('Clear All Filters'), findsOneWidget);
      expect(find.text('Restart Quiz'), findsOneWidget);
    });

    testWidgets('should clear filters when Clear All Filters button is tapped',
        (WidgetTester tester) async {
      // Setup with active filters
      await filterProvider.addFilter('Algebra');
      expect(filterProvider.hasActiveFilters, isTrue);

      await tester.pumpWidget(createTestApp(
        child: Scaffold(
          body: NoResultsWidget(
            hasActiveFilters: filterProvider.hasActiveFilters,
            onClearFilters: () => filterProvider.clearFilters(),
            onRestart: () {},
          ),
        ),
      ));

      // Tap the clear filters button
      await tester.tap(find.text('Clear All Filters'));
      await tester.pump();

      // Verify filters were cleared
      expect(filterProvider.hasActiveFilters, isFalse);
      expect(filterProvider.activeFilters, isEmpty);
    });

    testWidgets('should handle filter state changes correctly',
        (WidgetTester tester) async {
      final testQuestions = [
        QuestionIdentifier(
          id: '1',
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
          id: '2',
          type: IdType.external,
          metadata: QuestionMetadata(
            skillDescription: 'Math',
            primaryClassDescription: 'Algebra',
            difficulty: 'M',
            skillCode: 'M',
            primaryClassCode: 'H',
          ),
        ),
      ];

      filterProvider.setQuestions(testQuestions);

      // Initially should have results (no filters)
      expect(filterProvider.hasNoResults, isFalse);
      expect(filterProvider.filteredQuestionCount, equals(2));

      // Apply filter that matches some questions
      await filterProvider.addFilter('Information and Ideas');
      expect(filterProvider.hasNoResults, isFalse);
      expect(filterProvider.filteredQuestionCount, equals(1));

      // Apply filter that matches no questions
      await filterProvider.clearFilters();
      await filterProvider.addFilter('Geometry and Trigonometry');
      expect(filterProvider.hasNoResults, isTrue);
      expect(filterProvider.filteredQuestionCount, equals(0));

      // Clear filters - should have results again
      await filterProvider.clearFilters();
      expect(filterProvider.hasNoResults, isFalse);
      expect(filterProvider.filteredQuestionCount, equals(2));
    });

    testWidgets('should show appropriate help text when filters are active',
        (WidgetTester tester) async {
      await filterProvider.addFilter('Algebra');

      await tester.pumpWidget(createTestApp(
        child: Scaffold(
          body: NoResultsWidget(
            hasActiveFilters: filterProvider.hasActiveFilters,
            onClearFilters: () => filterProvider.clearFilters(),
            onRestart: () {},
          ),
        ),
      ));

      // Should show help text for filtered scenario
      expect(
          find.text(
              'Try removing some filters to see more questions, or restart the quiz to load new content.'),
          findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    });

    testWidgets('should not show help text when no filters are active',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(
        child: Scaffold(
          body: NoResultsWidget(
            hasActiveFilters: false,
            onClearFilters: () {},
            onRestart: () {},
          ),
        ),
      ));

      // Should not show help text for non-filtered scenario
      expect(
          find.text(
              'Try removing some filters to see more questions, or restart the quiz to load new content.'),
          findsNothing);
      expect(find.byIcon(Icons.lightbulb_outline), findsNothing);
    });

    testWidgets('should handle multiple filter operations correctly',
        (WidgetTester tester) async {
      final testQuestions = [
        QuestionIdentifier(
          id: '1',
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
          id: '2',
          type: IdType.external,
          metadata: QuestionMetadata(
            skillDescription: 'Grammar',
            primaryClassDescription: 'Standard English Conventions',
            difficulty: 'E',
            skillCode: 'G',
            primaryClassCode: 'SEC',
          ),
        ),
      ];

      filterProvider.setQuestions(testQuestions);

      // Add multiple filters that match questions (OR logic)
      await filterProvider.addFilter('Information and Ideas');
      await filterProvider.addFilter('Standard English Conventions');
      expect(filterProvider.filteredQuestionCount, equals(2));
      expect(filterProvider.hasNoResults, isFalse);

      // Remove one filter
      await filterProvider.removeFilter('Standard English Conventions');
      expect(filterProvider.filteredQuestionCount, equals(1));
      expect(filterProvider.hasNoResults, isFalse);

      // Remove all filters by clearing
      await filterProvider.clearFilters();
      expect(filterProvider.filteredQuestionCount, equals(2));
      expect(filterProvider.hasNoResults, isFalse);

      // Add filter that matches no questions
      await filterProvider.addFilter('Geometry and Trigonometry');
      expect(filterProvider.filteredQuestionCount, equals(0));
      expect(filterProvider.hasNoResults, isTrue);
    });

    testWidgets('should persist filter state across widget rebuilds',
        (WidgetTester tester) async {
      await filterProvider.addFilter('Algebra');

      Widget buildWidget() {
        return createTestApp(
          child: Consumer<FilterProvider>(
            builder: (context, provider, child) {
              return Scaffold(
                body: Column(
                  children: [
                    Text('Active filters: ${provider.activeFilterCount}'),
                    Text('Has active filters: ${provider.hasActiveFilters}'),
                    if (provider.hasActiveFilters)
                      ElevatedButton(
                        onPressed: () => provider.clearFilters(),
                        child: const Text('Clear Filters'),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      }

      await tester.pumpWidget(buildWidget());

      // Verify initial state
      expect(find.text('Active filters: 1'), findsOneWidget);
      expect(find.text('Has active filters: true'), findsOneWidget);
      expect(find.text('Clear Filters'), findsOneWidget);

      // Trigger a rebuild by pumping the same widget
      await tester.pumpWidget(buildWidget());

      // State should be preserved
      expect(find.text('Active filters: 1'), findsOneWidget);
      expect(find.text('Has active filters: true'), findsOneWidget);

      // Clear filters
      await tester.tap(find.text('Clear Filters'));
      await tester.pump();

      // State should be updated
      expect(find.text('Active filters: 0'), findsOneWidget);
      expect(find.text('Has active filters: false'), findsOneWidget);
      expect(find.text('Clear Filters'), findsNothing);
    });
  });
}
