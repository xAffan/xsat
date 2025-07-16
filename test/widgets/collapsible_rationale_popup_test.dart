import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sat_quiz/widgets/collapsible_rationale_popup.dart';

void main() {
  group('CollapsibleRationalePopup', () {
    testWidgets('should render when visible', (WidgetTester tester) async {
      const testRationale = '<p>This is a test rationale</p>';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CollapsibleRationalePopup(
                  rationale: testRationale,
                  isVisible: true,
                ),
              ],
            ),
          ),
        ),
      );

      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Should find the rationale title
      expect(find.text('Rationale'), findsOneWidget);

      // Should find the toggle icon
      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
    });

    testWidgets('should not render when not visible',
        (WidgetTester tester) async {
      const testRationale = '<p>This is a test rationale</p>';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CollapsibleRationalePopup(
                  rationale: testRationale,
                  isVisible: false,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should not find the rationale title when not visible
      expect(find.text('Rationale'), findsNothing);
    });

    testWidgets('should expand and collapse when tapped',
        (WidgetTester tester) async {
      const testRationale = '<p>This is a test rationale content</p>';
      bool toggleCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CollapsibleRationalePopup(
                  rationale: testRationale,
                  isVisible: true,
                  onToggle: () => toggleCalled = true,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially collapsed, content should not be visible
      expect(find.text('This is a test rationale content'), findsNothing);

      // Tap to expand
      await tester.tap(find.text('Rationale'));
      await tester.pumpAndSettle();

      // Content should now be visible
      expect(find.text('This is a test rationale content'), findsOneWidget);
      expect(toggleCalled, isTrue);

      // Reset toggle flag
      toggleCalled = false;

      // Tap to collapse
      await tester.tap(find.text('Rationale'));
      await tester.pumpAndSettle();

      // Content should be hidden again
      expect(find.text('This is a test rationale content'), findsNothing);
      expect(toggleCalled, isTrue);
    });

    testWidgets('should start expanded when initiallyExpanded is true',
        (WidgetTester tester) async {
      const testRationale = '<p>This is a test rationale content</p>';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CollapsibleRationalePopup(
                  rationale: testRationale,
                  isVisible: true,
                  initiallyExpanded: true,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Content should be visible initially
      expect(find.text('This is a test rationale content'), findsOneWidget);
    });

    testWidgets('should handle empty rationale gracefully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CollapsibleRationalePopup(
                  rationale: '',
                  isVisible: true,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should still render the header
      expect(find.text('Rationale'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
    });

    testWidgets('should animate visibility changes',
        (WidgetTester tester) async {
      const testRationale = '<p>Test rationale</p>';
      bool isVisible = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Stack(
                  children: [
                    CollapsibleRationalePopup(
                      rationale: testRationale,
                      isVisible: isVisible,
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => isVisible = !isVisible),
                      child: Text('Toggle'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      // Initially not visible
      expect(find.text('Rationale'), findsNothing);

      // Toggle visibility
      await tester.tap(find.text('Toggle'));
      await tester.pump(); // Start animation

      // Should be animating in
      await tester.pumpAndSettle();

      // Should now be visible
      expect(find.text('Rationale'), findsOneWidget);
    });
  });
}
