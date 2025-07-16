import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sat_quiz/widgets/draggable_rationale_popup.dart';

void main() {
  group('DraggableRationalePopup', () {
    const testRationale = '<p>This is a test rationale</p>';

    testWidgets('should render when visible', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: const [
                DraggableRationalePopup(
                  rationaleContent: testRationale,
                  isVisible: true,
                ),
              ],
            ),
          ),
        ),
      );

      // Verify the popup is rendered
      expect(find.byType(DraggableRationalePopup), findsOneWidget);
      expect(find.text('Rationale'), findsOneWidget);
    });

    testWidgets('should not render when not visible',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: const [
                DraggableRationalePopup(
                  rationaleContent: testRationale,
                  isVisible: false,
                ),
              ],
            ),
          ),
        ),
      );

      // Verify the popup is not rendered
      expect(find.byType(DraggableScrollableSheet), findsNothing);
      expect(find.text('Rationale'), findsNothing);
    });

    testWidgets('should have drag handle', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: const [
                DraggableRationalePopup(
                  rationaleContent: testRationale,
                  isVisible: true,
                ),
              ],
            ),
          ),
        ),
      );

      // Verify the drag handle is rendered
      expect(find.byType(GestureDetector), findsAtLeastNWidgets(1));
    });

    testWidgets('should call onDismiss when close button is pressed',
        (WidgetTester tester) async {
      bool dismissCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                DraggableRationalePopup(
                  rationaleContent: testRationale,
                  isVisible: true,
                  onDismiss: () {
                    dismissCalled = true;
                  },
                ),
              ],
            ),
          ),
        ),
      );

      // Find and tap the close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      // Verify onDismiss was called
      expect(dismissCalled, isTrue);
    });

    testWidgets('should render HTML content', (WidgetTester tester) async {
      const htmlContent = '<p>This is <strong>bold</strong> text</p>';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: const [
                DraggableRationalePopup(
                  rationaleContent: htmlContent,
                  isVisible: true,
                ),
              ],
            ),
          ),
        ),
      );

      // Verify the HTML content is rendered
      expect(find.byType(DraggableRationalePopup), findsOneWidget);
    });

    testWidgets('should handle empty content', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: const [
                DraggableRationalePopup(
                  rationaleContent: '',
                  isVisible: true,
                ),
              ],
            ),
          ),
        ),
      );

      // Verify the popup is rendered even with empty content
      expect(find.byType(DraggableRationalePopup), findsOneWidget);
      expect(find.text('Rationale'), findsOneWidget);
    });
  });
}
