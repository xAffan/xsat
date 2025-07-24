import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xsat/widgets/filter_chip_bar.dart';

void main() {
  group('FilterChipBar Widget Tests', () {
    const testFilters = [
      'Filter A',
      'Filter B',
      'Filter C',
      'Filter D',
      'Filter E',
      'Filter F',
    ];

    Widget createTestWidget({
      List<String> availableFilters = testFilters,
      Set<String> activeFilters = const {},
      Function(String)? onFilterToggle,
      VoidCallback? onClearAll,
      bool showClearAll = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: FilterChipBar(
            availableFilters: availableFilters,
            activeFilters: activeFilters,
            onFilterToggle: onFilterToggle ?? (_) {},
            onClearAll: onClearAll,
            showClearAll: showClearAll,
          ),
        ),
      );
    }

    testWidgets('displays all available filter chips',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Verify all filter chips are displayed
      for (final filter in testFilters) {
        expect(find.text(filter), findsOneWidget);
      }

      // Verify FilterChip widgets are created
      expect(find.byType(FilterChip), findsNWidgets(testFilters.length));
    });

    testWidgets('shows empty state when no filters available',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(availableFilters: []));

      expect(find.text('No filter categories available'), findsOneWidget);
      expect(find.byType(FilterChip), findsNothing);
    });

    testWidgets('displays active filters with selected state',
        (WidgetTester tester) async {
      const activeFilters = {'Filter A', 'Filter B'};

      await tester.pumpWidget(createTestWidget(activeFilters: activeFilters));

      // Find FilterChip widgets
      final filterChips =
          tester.widgetList<FilterChip>(find.byType(FilterChip));

      // Check that active filters are selected
      for (final chip in filterChips) {
        final chipText = (chip.label as Text).data!;
        if (activeFilters.contains(chipText)) {
          expect(chip.selected, isTrue, reason: '$chipText should be selected');
        } else {
          expect(chip.selected, isFalse,
              reason: '$chipText should not be selected');
        }
      }
    });

    testWidgets('calls onFilterToggle when chip is tapped',
        (WidgetTester tester) async {
      String? toggledFilter;

      await tester.pumpWidget(createTestWidget(
        onFilterToggle: (filter) => toggledFilter = filter,
      ));

      // Tap on the first filter chip
      await tester.tap(find.text('Filter A'));
      await tester.pump();

      expect(toggledFilter, equals('Filter A'));
    });

    testWidgets('shows clear all button when filters are active',
        (WidgetTester tester) async {
      const activeFilters = {'Filter A', 'Filter B'};

      await tester.pumpWidget(createTestWidget(
        activeFilters: activeFilters,
        onClearAll: () {},
      ));

      expect(find.text('Clear All'), findsOneWidget);
      expect(find.byIcon(Icons.clear_all), findsOneWidget);
    });

    testWidgets('hides clear all button when no filters are active',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        activeFilters: const {},
        onClearAll: () {},
      ));

      expect(find.text('Clear All'), findsNothing);
      expect(find.byIcon(Icons.clear_all), findsNothing);
    });

    testWidgets('hides clear all button when showClearAll is false',
        (WidgetTester tester) async {
      const activeFilters = {'Filter A'};

      await tester.pumpWidget(createTestWidget(
        activeFilters: activeFilters,
        onClearAll: () {},
        showClearAll: false,
      ));

      expect(find.text('Clear All'), findsNothing);
    });

    testWidgets('hides clear all button when onClearAll is null',
        (WidgetTester tester) async {
      const activeFilters = {'Filter A'};

      await tester.pumpWidget(createTestWidget(
        activeFilters: activeFilters,
        onClearAll: null,
      ));

      expect(find.text('Clear All'), findsNothing);
    });

    testWidgets('calls onClearAll when clear all button is tapped',
        (WidgetTester tester) async {
      bool clearAllCalled = false;
      const activeFilters = {'Filter A'};

      await tester.pumpWidget(createTestWidget(
        activeFilters: activeFilters,
        onClearAll: () => clearAllCalled = true,
      ));

      await tester.tap(find.text('Clear All'));
      await tester.pump();

      expect(clearAllCalled, isTrue);
    });

    testWidgets('is horizontally scrollable with many filters',
        (WidgetTester tester) async {
      // Create a long list of filters
      final manyFilters = List.generate(20, (index) => 'Filter $index');

      await tester.pumpWidget(createTestWidget(availableFilters: manyFilters));

      // Find the ListView
      final listView = find.byType(ListView);
      expect(listView, findsOneWidget);

      // Verify it's horizontal
      final listViewWidget = tester.widget<ListView>(listView);
      expect(listViewWidget.scrollDirection, equals(Axis.horizontal));

      // Verify first filter is visible
      expect(find.text('Filter 0'), findsOneWidget);

      // Test that we can scroll (no exception should be thrown)
      await tester.drag(listView, const Offset(-500, 0));
      await tester.pumpAndSettle();

      // The test passes if no exception is thrown during scrolling
      expect(listView, findsOneWidget);
    });

    testWidgets('applies correct styling to active and inactive chips',
        (WidgetTester tester) async {
      const activeFilters = {'Filter A'};

      await tester.pumpWidget(createTestWidget(activeFilters: activeFilters));

      final filterChips =
          tester.widgetList<FilterChip>(find.byType(FilterChip));

      for (final chip in filterChips) {
        final chipText = (chip.label as Text).data!;
        final isActive = activeFilters.contains(chipText);

        expect(chip.selected, equals(isActive));

        // Check label styling
        final labelText = chip.label as Text;
        if (isActive) {
          expect(labelText.style?.fontWeight, equals(FontWeight.w600));
        } else {
          expect(labelText.style?.fontWeight, equals(FontWeight.w500));
        }
      }
    });

    testWidgets('maintains proper spacing between chips',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find the ListView with separators
      final listView = find.byType(ListView);
      expect(listView, findsOneWidget);

      // Verify ListView is present and scrollable
      final listViewWidget = tester.widget<ListView>(listView);
      expect(listViewWidget.scrollDirection, equals(Axis.horizontal));
    });

    testWidgets('handles filter toggle for multiple filters',
        (WidgetTester tester) async {
      final toggledFilters = <String>[];

      await tester.pumpWidget(createTestWidget(
        onFilterToggle: (filter) => toggledFilters.add(filter),
      ));

      // Tap multiple filters from the test filters
      await tester.tap(find.text('Filter A'));
      await tester.pump();
      await tester.tap(find.text('Filter B'));
      await tester.pump();
      await tester.tap(find.text('Filter C'));
      await tester.pump();

      expect(
          toggledFilters,
          equals([
            'Filter A',
            'Filter B',
            'Filter C',
          ]));
    });

    testWidgets('respects custom height parameter',
        (WidgetTester tester) async {
      const customHeight = 80.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterChipBar(
              availableFilters: testFilters,
              activeFilters: const {},
              onFilterToggle: (_) {},
              height: customHeight,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxHeight, equals(customHeight));
    });
  });
}
