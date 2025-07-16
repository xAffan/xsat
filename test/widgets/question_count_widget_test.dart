import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sat_quiz/providers/filter_provider.dart';
import 'package:sat_quiz/widgets/question_count_widget.dart';
import 'package:sat_quiz/models/question_identifier.dart';
import 'package:sat_quiz/models/question_metadata.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('QuestionCountWidget', () {
    late FilterProvider filterProvider;
    late List<QuestionIdentifier> testQuestions;

    setUp(() {
      filterProvider = FilterProvider();

      // Create test questions with different categories
      testQuestions = [
        QuestionIdentifier(
          id: '1',
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
          id: '2',
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
          id: '3',
          type: IdType.external,
          metadata: QuestionMetadata(
            skillDescription: 'Linear Equations',
            primaryClassDescription: 'Algebra',
            difficulty: 'H',
            skillCode: 'LE',
            primaryClassCode: 'ALG',
          ),
        ),
      ];

      filterProvider.setQuestions(testQuestions);
    });

    testWidgets('should display total count when no filters are active',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: filterProvider,
            child: const Scaffold(
              body: QuestionCountWidget(),
            ),
          ),
        ),
      );

      expect(find.text('3 questions'), findsOneWidget);
    });

    testWidgets(
        'should display filtered and total counts when filters are active',
        (WidgetTester tester) async {
      // Add a filter first
      await filterProvider.addFilter('Information and Ideas');

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: filterProvider,
            child: const Scaffold(
              body: QuestionCountWidget(),
            ),
          ),
        ),
      );

      expect(find.text('1 of 3 questions'), findsOneWidget);
    });

    testWidgets('should always show both counts when showBothCounts is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: filterProvider,
            child: const Scaffold(
              body: QuestionCountWidget(showBothCounts: true),
            ),
          ),
        ),
      );

      // Should show both counts even though no filters are active
      expect(find.text('3 of 3 questions'), findsOneWidget);
    });

    testWidgets('should update when filter state changes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: filterProvider,
            child: const Scaffold(
              body: QuestionCountWidget(),
            ),
          ),
        ),
      );

      // Initially shows total count
      expect(find.text('3 questions'), findsOneWidget);

      // Add a filter
      await filterProvider.addFilter('Information and Ideas');
      await tester.pump();

      // Now shows filtered count
      expect(find.text('1 of 3 questions'), findsOneWidget);

      // Clear filters
      await filterProvider.clearFilters();
      await tester.pump();

      // Back to showing total count
      expect(find.text('3 questions'), findsOneWidget);
    });

    testWidgets('should show loading state when no question data is available',
        (WidgetTester tester) async {
      // Create a new provider with no questions
      final emptyProvider = FilterProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: emptyProvider,
            child: const Scaffold(
              body: QuestionCountWidget(),
            ),
          ),
        ),
      );

      expect(find.text('Loading questions...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should apply custom text style when provided',
        (WidgetTester tester) async {
      const customStyle = TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: filterProvider,
            child: const Scaffold(
              body: QuestionCountWidget(textStyle: customStyle),
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('3 questions'));
      expect(textWidget.style?.fontSize, equals(18));
      expect(textWidget.style?.fontWeight, equals(FontWeight.bold));
      expect(textWidget.style?.color, equals(Colors.blue));
    });

    testWidgets('should show custom loading widget when provided',
        (WidgetTester tester) async {
      // Create a new provider with no questions
      final emptyProvider = FilterProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: emptyProvider,
            child: Scaffold(
              body: QuestionCountWidget(
                loadingWidget: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.amber,
                  child: const Text('Custom loading...'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Custom loading...'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
