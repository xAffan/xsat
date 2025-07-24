import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xsat/widgets/no_results_widget.dart';

void main() {
  group('NoResultsWidget', () {
    testWidgets('displays default message when no custom message provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NoResultsWidget(
              hasActiveFilters: false,
            ),
          ),
        ),
      );

      expect(find.text('No Questions Found'), findsOneWidget);
      expect(
          find.text(
              'No questions are currently available. Please check your connection.'),
          findsOneWidget);
      expect(find.byIcon(Icons.filter_list_off), findsOneWidget);
    });

    testWidgets('displays custom message when provided',
        (WidgetTester tester) async {
      const customMessage = 'Custom no results message';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NoResultsWidget(
              hasActiveFilters: false,
              customMessage: customMessage,
            ),
          ),
        ),
      );

      expect(find.text('No Questions Found'), findsOneWidget);
      expect(find.text(customMessage), findsOneWidget);
    });

    testWidgets('shows clear filters button when filters are active',
        (WidgetTester tester) async {
      bool clearFiltersCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoResultsWidget(
              hasActiveFilters: true,
              onClearFilters: () {
                clearFiltersCalled = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Clear All Filters'), findsOneWidget);
      expect(find.byIcon(Icons.clear_all), findsOneWidget);

      // Test button functionality
      await tester.tap(find.text('Clear All Filters'));
      await tester.pump();

      expect(clearFiltersCalled, isTrue);
    });

    testWidgets('hides clear filters button when no filters are active',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NoResultsWidget(
              hasActiveFilters: false,
            ),
          ),
        ),
      );

      expect(find.text('Clear All Filters'), findsNothing);
    });

    testWidgets('hides clear filters button when showClearFilters is false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoResultsWidget(
              hasActiveFilters: true,
              showClearFilters: false,
              onClearFilters: () {},
            ),
          ),
        ),
      );

      expect(find.text('Clear All Filters'), findsNothing);
    });

    

    

    testWidgets('shows help text when filters are active',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NoResultsWidget(
              hasActiveFilters: true,
            ),
          ),
        ),
      );

      expect(
          find.text(
              'Try removing some filters to see more questions.'),
          findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    });

    testWidgets('hides help text when no filters are active',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NoResultsWidget(
              hasActiveFilters: false,
            ),
          ),
        ),
      );

      expect(
          find.text(
              'Try removing some filters to see more questions.'),
          findsNothing);
    });

    testWidgets('displays appropriate message for filtered scenario',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NoResultsWidget(
              hasActiveFilters: true,
            ),
          ),
        ),
      );

      expect(
          find.text(
              'No questions match the selected filters. Try adjusting your filter selection or clearing all filters to see more questions.'),
          findsOneWidget);
    });

    testWidgets('handles null callbacks gracefully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NoResultsWidget(
              hasActiveFilters: true,
              onClearFilters: null,
            ),
          ),
        ),
      );

      // Should not show buttons when callbacks are null
      expect(find.text('Clear All Filters'), findsNothing);
    });

    testWidgets('applies correct styling and layout',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: NoResultsWidget(
              hasActiveFilters: true,
              onClearFilters: () {},
            ),
          ),
        ),
      );

      // Verify text content
      expect(find.text('No Questions Found'), findsOneWidget);
      expect(find.text('Clear All Filters'), findsOneWidget);

      // Verify icon presence
      expect(find.byIcon(Icons.filter_list_off), findsOneWidget);
      expect(find.byIcon(Icons.clear_all), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);

      // Check that buttons are present - they are wrapped in SizedBox so we check for the text
      expect(find.text('Clear All Filters'), findsOneWidget);
    });
  });
}
