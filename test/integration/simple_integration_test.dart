import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sat_quiz/providers/filter_provider.dart';
import 'package:sat_quiz/models/question_identifier.dart';
import 'package:sat_quiz/models/question_metadata.dart';

void main() {
  group('Simple Integration Tests', () {
    testWidgets('FilterProvider integration test', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      final filterProvider = FilterProvider();
      await filterProvider.initialize();

      final testQuestions = [
        QuestionIdentifier(
          id: 'test1',
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
      await filterProvider.addFilter('Information and Ideas');

      expect(filterProvider.hasActiveFilters, isTrue);
      expect(filterProvider.filteredQuestionCount, equals(1));
    });
  });
}
