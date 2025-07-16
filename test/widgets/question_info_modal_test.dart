import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sat_quiz/models/question_metadata.dart';
import 'package:sat_quiz/widgets/question_info_modal.dart';

void main() {
  group('QuestionInfoModal', () {
    // Helper function to create a test app with the modal
    Widget createTestApp(QuestionMetadata? metadata) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => QuestionInfoModal.show(context, metadata),
              child: const Text('Show Modal'),
            ),
          ),
        ),
      );
    }

    // Sample complete metadata for testing
    final completeMetadata = QuestionMetadata(
      skillDescription: 'Form, Structure, and Sense',
      primaryClassDescription: 'Standard English Conventions',
      difficulty: 'M',
      skillCode: 'FSS',
      primaryClassCode: 'SEC',
    );

    // Sample partial metadata for testing
    final partialMetadata = QuestionMetadata(
      skillDescription: 'Unknown Skill',
      primaryClassDescription: 'Unknown Category',
      difficulty: 'H',
      skillCode: '',
      primaryClassCode: '',
    );

    testWidgets('displays modal with complete metadata',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(completeMetadata));

      // Tap button to show modal
      await tester.tap(find.text('Show Modal'));
      await tester.pumpAndSettle();

      // Verify modal is displayed
      expect(find.byType(QuestionInfoModal), findsOneWidget);
      expect(find.text('Question Information'), findsOneWidget);

      // Verify all metadata fields are displayed
      expect(find.text('Skill'), findsOneWidget);
      expect(find.text('Form, Structure, and Sense'), findsOneWidget);

      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Standard English Conventions'), findsOneWidget);

      expect(find.text('Difficulty'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);

      // Verify icons are present
      expect(find.byIcon(Icons.psychology), findsOneWidget);
      expect(find.byIcon(Icons.category), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('displays modal with partial metadata',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(partialMetadata));

      // Tap button to show modal
      await tester.tap(find.text('Show Modal'));
      await tester.pumpAndSettle();

      // Verify modal is displayed
      expect(find.byType(QuestionInfoModal), findsOneWidget);

      // Verify partial metadata is displayed with defaults
      expect(find.text('Unknown Skill'), findsOneWidget);
      expect(find.text('Unknown Category'), findsOneWidget);
      expect(find.text('Hard'), findsOneWidget);
    });

    testWidgets('displays no metadata message when metadata is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(null));

      // Tap button to show modal
      await tester.tap(find.text('Show Modal'));
      await tester.pumpAndSettle();

      // Verify modal is displayed
      expect(find.byType(QuestionInfoModal), findsOneWidget);

      // Verify no metadata message is shown
      expect(
          find.text('Question information is not available for this question.'),
          findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);

      // Verify metadata sections are not displayed
      expect(find.text('Skill'), findsNothing);
      expect(find.text('Category'), findsNothing);
      expect(find.text('Difficulty'), findsNothing);
    });

    testWidgets('can be dismissed by close button',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(completeMetadata));

      // Show modal
      await tester.tap(find.text('Show Modal'));
      await tester.pumpAndSettle();

      // Verify modal is displayed
      expect(find.byType(QuestionInfoModal), findsOneWidget);

      // Tap close button in header
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Verify modal is dismissed
      expect(find.byType(QuestionInfoModal), findsNothing);
    });

    testWidgets('can be dismissed by close text button',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(completeMetadata));

      // Show modal
      await tester.tap(find.text('Show Modal'));
      await tester.pumpAndSettle();

      // Verify modal is displayed
      expect(find.byType(QuestionInfoModal), findsOneWidget);

      // Tap close text button
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Verify modal is dismissed
      expect(find.byType(QuestionInfoModal), findsNothing);
    });

    testWidgets('can be dismissed by tapping outside (barrier dismissible)',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(completeMetadata));

      // Show modal
      await tester.tap(find.text('Show Modal'));
      await tester.pumpAndSettle();

      // Verify modal is displayed
      expect(find.byType(QuestionInfoModal), findsOneWidget);

      // Tap outside the modal (on the barrier)
      await tester
          .tapAt(const Offset(50, 50)); // Top-left corner, outside modal
      await tester.pumpAndSettle();

      // Verify modal is dismissed
      expect(find.byType(QuestionInfoModal), findsNothing);
    });

    testWidgets('formats difficulty codes correctly',
        (WidgetTester tester) async {
      // Test Easy difficulty
      final easyMetadata = QuestionMetadata(
        skillDescription: 'Test Skill',
        primaryClassDescription: 'Test Category',
        difficulty: 'E',
        skillCode: 'TS',
        primaryClassCode: 'TC',
      );

      await tester.pumpWidget(createTestApp(easyMetadata));
      await tester.tap(find.text('Show Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Easy'), findsOneWidget);

      // Dismiss modal
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Test Hard difficulty
      final hardMetadata = QuestionMetadata(
        skillDescription: 'Test Skill',
        primaryClassDescription: 'Test Category',
        difficulty: 'H',
        skillCode: 'TS',
        primaryClassCode: 'TC',
      );

      await tester.pumpWidget(createTestApp(hardMetadata));
      await tester.tap(find.text('Show Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Hard'), findsOneWidget);
    });

    testWidgets('handles unknown difficulty gracefully',
        (WidgetTester tester) async {
      final unknownDifficultyMetadata = QuestionMetadata(
        skillDescription: 'Test Skill',
        primaryClassDescription: 'Test Category',
        difficulty: 'X', // Unknown difficulty code
        skillCode: 'TS',
        primaryClassCode: 'TC',
      );

      await tester.pumpWidget(createTestApp(unknownDifficultyMetadata));
      await tester.tap(find.text('Show Modal'));
      await tester.pumpAndSettle();

      // Should display the original difficulty code
      expect(find.text('X'), findsOneWidget);
    });

    testWidgets('handles empty difficulty gracefully',
        (WidgetTester tester) async {
      final emptyDifficultyMetadata = QuestionMetadata(
        skillDescription: 'Test Skill',
        primaryClassDescription: 'Test Category',
        difficulty: '', // Empty difficulty
        skillCode: 'TS',
        primaryClassCode: 'TC',
      );

      await tester.pumpWidget(createTestApp(emptyDifficultyMetadata));
      await tester.tap(find.text('Show Modal'));
      await tester.pumpAndSettle();

      // Should display "Unknown" for empty difficulty
      expect(find.text('Unknown'), findsOneWidget);
    });

    testWidgets('modal has proper styling and layout',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(completeMetadata));

      // Show modal
      await tester.tap(find.text('Show Modal'));
      await tester.pumpAndSettle();

      // Verify Dialog widget is used
      expect(find.byType(Dialog), findsOneWidget);

      // Verify proper structure
      expect(find.byType(Container), findsWidgets);
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Row), findsWidgets);

      // Verify close button has tooltip
      final closeButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(closeButton.tooltip, equals('Close'));
    });
  });
}
