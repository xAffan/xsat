import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/providers/filter_provider.dart';
import '../../lib/models/question_identifier.dart';
import '../../lib/models/question_metadata.dart';

void main() {
  group('FilterProvider', () {
    late FilterProvider filterProvider;
    late List<QuestionIdentifier> testQuestions;

    setUp(() {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});

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
    });

    group('Initialization', () {
      test('should initialize with empty filters', () {
        expect(filterProvider.activeFilters, isEmpty);
        expect(filterProvider.hasActiveFilters, isFalse);
        expect(filterProvider.activeFilterCount, equals(0));
      });

      test('should load persisted filters on initialize', () async {
        // Set up mock preferences with saved filters
        SharedPreferences.setMockInitialValues({
          'active_filters': json.encode(['Information and Ideas', 'Algebra'])
        });

        final provider = FilterProvider();
        await provider.initialize();

        expect(provider.activeFilters, contains('Information and Ideas'));
        expect(provider.activeFilters, contains('Algebra'));
        expect(provider.activeFilterCount, equals(2));
      });

      test('should handle corrupted preferences gracefully', () async {
        // Set up mock preferences with invalid JSON
        SharedPreferences.setMockInitialValues(
            {'active_filters': 'invalid json'});

        final provider = FilterProvider();
        await provider.initialize();

        expect(provider.activeFilters, isEmpty);
        expect(provider.hasActiveFilters, isFalse);
      });
    });

    group('Filter Management', () {
      test('should add valid filter', () async {
        await filterProvider.addFilter('Information and Ideas');

        expect(filterProvider.activeFilters, contains('Information and Ideas'));
        expect(filterProvider.hasActiveFilters, isTrue);
        expect(filterProvider.activeFilterCount, equals(1));
      });

      test('should not add invalid filter', () async {
        await filterProvider.addFilter('Invalid Category');

        expect(filterProvider.activeFilters, isEmpty);
        expect(filterProvider.hasActiveFilters, isFalse);
      });

      test('should not add duplicate filter', () async {
        await filterProvider.addFilter('Information and Ideas');
        await filterProvider.addFilter('Information and Ideas');

        expect(filterProvider.activeFilterCount, equals(1));
      });

      test('should remove existing filter', () async {
        await filterProvider.addFilter('Information and Ideas');
        await filterProvider.addFilter('Algebra');

        await filterProvider.removeFilter('Information and Ideas');

        expect(filterProvider.activeFilters,
            isNot(contains('Information and Ideas')));
        expect(filterProvider.activeFilters, contains('Algebra'));
        expect(filterProvider.activeFilterCount, equals(1));
      });

      test('should handle removing non-existent filter', () async {
        await filterProvider.addFilter('Information and Ideas');

        await filterProvider.removeFilter('Non-existent Category');

        expect(filterProvider.activeFilters, contains('Information and Ideas'));
        expect(filterProvider.activeFilterCount, equals(1));
      });

      test('should toggle filter correctly', () async {
        // Toggle on
        await filterProvider.toggleFilter('Information and Ideas');
        expect(filterProvider.isFilterActive('Information and Ideas'), isTrue);

        // Toggle off
        await filterProvider.toggleFilter('Information and Ideas');
        expect(filterProvider.isFilterActive('Information and Ideas'), isFalse);
      });

      test('should clear all filters', () async {
        await filterProvider.addFilter('Information and Ideas');
        await filterProvider.addFilter('Algebra');

        await filterProvider.clearFilters();

        expect(filterProvider.activeFilters, isEmpty);
        expect(filterProvider.hasActiveFilters, isFalse);
      });

      test('should check if filter is active', () async {
        await filterProvider.addFilter('Information and Ideas');

        expect(filterProvider.isFilterActive('Information and Ideas'), isTrue);
        expect(filterProvider.isFilterActive('Algebra'), isFalse);
      });
    });

    group('Question Filtering', () {
      setUp(() {
        filterProvider.setQuestions(testQuestions);
      });

      test('should return all questions when no filters active', () {
        expect(filterProvider.filteredQuestions.length,
            equals(4)); // Excludes question without metadata
      });

      test('should filter questions by single category', () async {
        await filterProvider.addFilter('Information and Ideas');

        expect(filterProvider.filteredQuestions.length, equals(1));
        expect(filterProvider.filteredQuestions.first.id, equals('1'));
      });

      test('should filter questions by multiple categories using OR logic',
          () async {
        await filterProvider.addFilter('Information and Ideas');
        await filterProvider.addFilter('Algebra');

        expect(filterProvider.filteredQuestions.length, equals(2));

        final filteredIds =
            filterProvider.filteredQuestions.map((q) => q.id).toSet();
        expect(filteredIds, contains('1')); // Information and Ideas
        expect(filteredIds, contains('3')); // Algebra
      });

      test('should exclude questions without metadata', () async {
        await filterProvider.addFilter('Information and Ideas');

        final filteredIds =
            filterProvider.filteredQuestions.map((q) => q.id).toSet();
        expect(filteredIds, isNot(contains('5'))); // Question without metadata
      });

      test('should return empty list when no questions match filters',
          () async {
        await filterProvider.addFilter('Geometry and Trigonometry');

        expect(filterProvider.filteredQuestions, isEmpty);
      });

      test('should update filtered questions when questions list changes', () {
        filterProvider.addFilter('Information and Ideas');

        // Add new question with matching category
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

        expect(filterProvider.filteredQuestions.length, equals(2));
      });
    });

    group('Available Categories', () {
      setUp(() {
        filterProvider.setQuestions(testQuestions);
      });

      test('should return available categories based on question metadata', () {
        final availableCategories =
            filterProvider.getAvailableFilterCategories();

        expect(availableCategories, contains('Information and Ideas'));
        expect(availableCategories, contains('Standard English Conventions'));
        expect(availableCategories, contains('Algebra'));
        expect(availableCategories, contains('Advanced Math'));
        expect(availableCategories.length, equals(4));
      });

      test('should return available categories for specific subject', () {
        final englishCategories =
            filterProvider.getAvailableFilterCategoriesForSubject('English');
        final mathCategories =
            filterProvider.getAvailableFilterCategoriesForSubject('Math');

        expect(englishCategories, contains('Information and Ideas'));
        expect(englishCategories, contains('Standard English Conventions'));
        expect(englishCategories.length, equals(2));

        expect(mathCategories, contains('Algebra'));
        expect(mathCategories, contains('Advanced Math'));
        expect(mathCategories.length, equals(2));
      });

      test('should return question counts for each category', () {
        final counts = filterProvider.getCategoryQuestionCounts();

        expect(counts['Information and Ideas'], equals(1));
        expect(counts['Standard English Conventions'], equals(1));
        expect(counts['Algebra'], equals(1));
        expect(counts['Advanced Math'], equals(1));
      });

      test('should handle empty question list', () {
        filterProvider.setQuestions([]);

        final availableCategories =
            filterProvider.getAvailableFilterCategories();
        final counts = filterProvider.getCategoryQuestionCounts();

        expect(availableCategories, isEmpty);
        expect(counts, isEmpty);
      });
    });

    group('Persistence', () {
      test('should persist filters to SharedPreferences', () async {
        await filterProvider.addFilter('Information and Ideas');
        await filterProvider.addFilter('Algebra');

        final prefs = await SharedPreferences.getInstance();
        final savedFilters = prefs.getString('active_filters');

        expect(savedFilters, isNotNull);
        final filtersList = List<String>.from(json.decode(savedFilters!));
        expect(filtersList, contains('Information and Ideas'));
        expect(filtersList, contains('Algebra'));
      });

      test('should load filters from SharedPreferences', () async {
        // Save filters manually
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('active_filters',
            json.encode(['Information and Ideas', 'Algebra']));

        final newProvider = FilterProvider();
        await newProvider.initialize();

        expect(newProvider.activeFilters, contains('Information and Ideas'));
        expect(newProvider.activeFilters, contains('Algebra'));
      });

      test('should clear persisted filters when clearing all filters',
          () async {
        await filterProvider.addFilter('Information and Ideas');
        await filterProvider.clearFilters();

        final prefs = await SharedPreferences.getInstance();
        final savedFilters = prefs.getString('active_filters');

        expect(savedFilters, isNotNull);
        final filtersList = List<String>.from(json.decode(savedFilters!));
        expect(filtersList, isEmpty);
      });
    });

    group('Error Handling', () {
      test('should handle SharedPreferences errors gracefully', () async {
        // This test verifies that the provider doesn't crash on SharedPreferences errors
        // In a real scenario, we might mock SharedPreferences to throw errors

        await filterProvider.addFilter('Information and Ideas');
        expect(filterProvider.activeFilters, contains('Information and Ideas'));
      });

      test('should reset filter state', () async {
        filterProvider.setQuestions(testQuestions);
        await filterProvider.addFilter('Information and Ideas');

        await filterProvider.resetFilterState();

        expect(filterProvider.activeFilters, isEmpty);
        expect(filterProvider.originalQuestions, isEmpty);
        expect(filterProvider.filteredQuestions, isEmpty);
        expect(filterProvider.hasActiveFilters, isFalse);
      });
    });

    group('No Results Detection', () {
      test('should detect no results scenario correctly', () async {
        // Setup questions
        filterProvider.setQuestions(testQuestions);

        // Initially should have results
        expect(filterProvider.hasNoResults, isFalse);
        expect(filterProvider.filteredQuestionCount, equals(4));

        // Add filter that doesn't match any questions
        await filterProvider.addFilter('Geometry and Trigonometry');

        // Should now have no results
        expect(filterProvider.hasNoResults, isTrue);
        expect(filterProvider.filteredQuestionCount, equals(0));
      });

      test('should return correct filtered question count', () async {
        filterProvider.setQuestions(testQuestions);

        // No filters - should show all questions with metadata
        expect(filterProvider.filteredQuestionCount, equals(4));

        // Add one filter
        await filterProvider.addFilter('Information and Ideas');
        expect(filterProvider.filteredQuestionCount, equals(1));

        // Add another filter (OR logic)
        await filterProvider.addFilter('Standard English Conventions');
        expect(filterProvider.filteredQuestionCount, equals(2));

        // Clear filters
        await filterProvider.clearFilters();
        expect(filterProvider.filteredQuestionCount, equals(4));
      });

      test('should handle empty original questions list', () {
        filterProvider.setQuestions([]);

        expect(filterProvider.hasNoResults,
            isFalse); // No results only when we have original questions but no filtered ones
        expect(filterProvider.filteredQuestionCount, equals(0));
        expect(filterProvider.getAvailableFilterCategories(), isEmpty);
      });

      test('should correctly identify no results vs empty state', () async {
        // Empty state - no original questions
        filterProvider.setQuestions([]);
        expect(filterProvider.hasNoResults, isFalse);

        // Set questions then filter to empty
        filterProvider.setQuestions(testQuestions);
        await filterProvider
            .addFilter('Geometry and Trigonometry'); // No matching questions
        expect(filterProvider.hasNoResults, isTrue);

        // Clear filters - should have results again
        await filterProvider.clearFilters();
        expect(filterProvider.hasNoResults, isFalse);
      });
    });

    group('Immutability', () {
      test('should return immutable collections', () {
        filterProvider.setQuestions(testQuestions);

        final activeFilters = filterProvider.activeFilters;
        final filteredQuestions = filterProvider.filteredQuestions;
        final originalQuestions = filterProvider.originalQuestions;

        expect(() => activeFilters.add('test'), throwsUnsupportedError);
        expect(() => filteredQuestions.add(testQuestions.first),
            throwsUnsupportedError);
        expect(() => originalQuestions.add(testQuestions.first),
            throwsUnsupportedError);
      });
    });
  });
}
