import 'package:xsat/providers/settings_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xsat/providers/filter_provider.dart';
import 'package:xsat/models/question_identifier.dart';
import 'package:xsat/models/question_metadata.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock SharedPreferences
  SharedPreferences.setMockInitialValues({});
  group('FilterProvider Question Count Tracking', () {
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
            primaryClassCode: 'H',
          ),
        ),
        QuestionIdentifier(
          id: '4',
          type: IdType.external,
          metadata: QuestionMetadata(
            skillDescription: 'Quadratic Functions',
            primaryClassDescription: 'Advanced Math',
            difficulty: 'M',
            skillCode: 'QF',
            primaryClassCode: 'P',
          ),
        ),
        QuestionIdentifier(
          id: '5',
          type: IdType.external,
          // No metadata - should be excluded from filtered results
        ),
      ];

      filterProvider.setQuestionsWithMetadata(
        questions: testQuestions,
        liveQuestionIds: {},
        seenQuestionIds: {},
        questionType: QuestionType.both,
        excludeActiveQuestions: false,
      );
    });

    group('Question Count Tracking', () {
      test('should track total question count correctly', () {
        // Total count should be questions with valid metadata (4 out of 5)
        expect(filterProvider.totalQuestionCount, equals(4));

        // Add a new question with metadata
        final newQuestions = [
          ...testQuestions,
          QuestionIdentifier(
            id: '6',
            type: IdType.external,
            metadata: QuestionMetadata(
              skillDescription: 'Another Reading',
              primaryClassDescription: 'Information and Ideas',
              difficulty: 'E',
              skillCode: 'AR',
              primaryClassCode: 'INI',
            ),
          ),
        ];

        filterProvider.setQuestions(newQuestions);
        expect(filterProvider.totalQuestionCount, equals(5));
      });

      test('should return appropriate displayed count based on filter state',
          () async {
        // No filters - should return total count
        expect(filterProvider.displayedQuestionCount, equals(4));
        expect(filterProvider.displayedQuestionCount,
            equals(filterProvider.totalQuestionCount));

        // With filters - should return filtered count
        await filterProvider.addFilter('Information and Ideas');
        expect(filterProvider.displayedQuestionCount, equals(1));
        expect(filterProvider.displayedQuestionCount,
            equals(filterProvider.filteredQuestionCount));

        // Clear filters - should return total count again
        await filterProvider.clearFilters();
        expect(filterProvider.displayedQuestionCount, equals(4));
        expect(filterProvider.displayedQuestionCount,
            equals(filterProvider.totalQuestionCount));
      });
    });

    group('Question Count Display', () {
      test('should format question count text correctly', () async {
        // No filters
        expect(filterProvider.getQuestionCountText(), equals('4 of 4 questions'));

        // With filters
        await filterProvider.addFilter('Information and Ideas');
        expect(
            filterProvider.getQuestionCountText(), equals('1 of 4 questions'));

        // Multiple filters
        await filterProvider.addFilter('Standard English Conventions');
        expect(
            filterProvider.getQuestionCountText(), equals('2 of 4 questions'));

        // Clear filters
        await filterProvider.clearFilters();
        expect(filterProvider.getQuestionCountText(), equals('4 of 4 questions'));
      });

      test('should update counts when manually called', () async {
        // First add a filter so we can test the "X of Y" format
        await filterProvider.addFilter('Information and Ideas');

        // Then manually update the counts
        filterProvider.updateQuestionCounts(10, 5);

        expect(filterProvider.totalQuestionCount, equals(10));
        expect(filterProvider.filteredQuestionCount, equals(5));
        expect(
            filterProvider.getQuestionCountText(), equals('5 of 10 questions'));

        // Reset filters should still show updated counts
        await filterProvider.clearFilters();

        // Update counts again after clearing filters
        filterProvider.updateQuestionCounts(10, 10);
        expect(filterProvider.getQuestionCountText(), equals('10 of 10 questions'));
      });

      test('should update counts automatically when filters change', () async {
        expect(filterProvider.totalQuestionCount, equals(4));
        expect(filterProvider.filteredQuestionCount, equals(4));

        // Add filter
        await filterProvider.addFilter('Information and Ideas');
        expect(filterProvider.totalQuestionCount, equals(4)); // Total unchanged
        expect(filterProvider.filteredQuestionCount,
            equals(1)); // Filtered updated

        // Add another filter
        await filterProvider.addFilter('Standard English Conventions');
        expect(filterProvider.filteredQuestionCount, equals(2));

        // Remove filter
        await filterProvider.removeFilter('Information and Ideas');
        expect(filterProvider.filteredQuestionCount, equals(1));

        // Clear filters
        await filterProvider.clearFilters();
        expect(filterProvider.filteredQuestionCount, equals(4));
      });
    });
  });
}
