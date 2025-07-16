import 'package:flutter_test/flutter_test.dart';
import 'package:sat_quiz/services/category_mapping_service.dart';

void main() {
  group('CategoryMappingService', () {
    group('getUserFriendlyCategory', () {
      test('should return correct user-friendly category for valid API codes',
          () {
        expect(CategoryMappingService.getUserFriendlyCategory('INI'),
            equals('Information and Ideas'));
        expect(CategoryMappingService.getUserFriendlyCategory('CAS'),
            equals('Craft and Structure'));
        expect(CategoryMappingService.getUserFriendlyCategory('EOI'),
            equals('Expression of Ideas'));
        expect(CategoryMappingService.getUserFriendlyCategory('SEC'),
            equals('Standard English Conventions'));
        expect(CategoryMappingService.getUserFriendlyCategory('H'),
            equals('Algebra'));
        expect(CategoryMappingService.getUserFriendlyCategory('P'),
            equals('Advanced Math'));
        expect(CategoryMappingService.getUserFriendlyCategory('Q'),
            equals('Problem-Solving and Data Analysis'));
        expect(CategoryMappingService.getUserFriendlyCategory('S'),
            equals('Geometry and Trigonometry'));
      });

      test('should return original code for unknown API codes', () {
        expect(CategoryMappingService.getUserFriendlyCategory('UNKNOWN'),
            equals('UNKNOWN'));
        expect(CategoryMappingService.getUserFriendlyCategory('XYZ'),
            equals('XYZ'));
        expect(CategoryMappingService.getUserFriendlyCategory(''), equals(''));
      });

      test('should handle null-like values gracefully', () {
        expect(CategoryMappingService.getUserFriendlyCategory('null'),
            equals('null'));
      });
    });

    group('getApiCode', () {
      test('should return correct API code for valid categories', () {
        expect(CategoryMappingService.getApiCode('Information and Ideas'),
            equals('INI'));
        expect(CategoryMappingService.getApiCode('Craft and Structure'),
            equals('CAS'));
        expect(CategoryMappingService.getApiCode('Expression of Ideas'),
            equals('EOI'));
        expect(
            CategoryMappingService.getApiCode('Standard English Conventions'),
            equals('SEC'));
        expect(CategoryMappingService.getApiCode('Algebra'), equals('H'));
        expect(CategoryMappingService.getApiCode('Advanced Math'), equals('P'));
        expect(
            CategoryMappingService.getApiCode(
                'Problem-Solving and Data Analysis'),
            equals('Q'));
        expect(CategoryMappingService.getApiCode('Geometry and Trigonometry'),
            equals('S'));
      });

      test('should return original category for unknown categories', () {
        expect(CategoryMappingService.getApiCode('Unknown Category'),
            equals('Unknown Category'));
        expect(CategoryMappingService.getApiCode(''), equals(''));
      });

      test('should be case sensitive', () {
        expect(CategoryMappingService.getApiCode('algebra'),
            equals('algebra')); // lowercase should not match
        expect(CategoryMappingService.getApiCode('ALGEBRA'),
            equals('ALGEBRA')); // uppercase should not match
      });
    });

    group('getFilterableCategories', () {
      test('should return English categories when subject type is English', () {
        final englishCategories =
            CategoryMappingService.getFilterableCategories('English');
        expect(englishCategories, hasLength(4));
        expect(englishCategories, contains('Information and Ideas'));
        expect(englishCategories, contains('Craft and Structure'));
        expect(englishCategories, contains('Expression of Ideas'));
        expect(englishCategories, contains('Standard English Conventions'));
      });

      test('should return Math categories when subject type is Math', () {
        final mathCategories =
            CategoryMappingService.getFilterableCategories('Math');
        expect(mathCategories, hasLength(4));
        expect(mathCategories, contains('Algebra'));
        expect(mathCategories, contains('Advanced Math'));
        expect(mathCategories, contains('Problem-Solving and Data Analysis'));
        expect(mathCategories, contains('Geometry and Trigonometry'));
      });

      test('should return empty list for unknown subject types', () {
        expect(
            CategoryMappingService.getFilterableCategories('Science'), isEmpty);
        expect(
            CategoryMappingService.getFilterableCategories('History'), isEmpty);
        expect(CategoryMappingService.getFilterableCategories(''), isEmpty);
      });

      test('should return all categories when no subject type is specified',
          () {
        final allCategories = CategoryMappingService.getFilterableCategories();
        expect(allCategories, hasLength(8));
        // Should contain all English categories
        expect(allCategories, contains('Information and Ideas'));
        expect(allCategories, contains('Craft and Structure'));
        expect(allCategories, contains('Expression of Ideas'));
        expect(allCategories, contains('Standard English Conventions'));
        // Should contain all Math categories
        expect(allCategories, contains('Algebra'));
        expect(allCategories, contains('Advanced Math'));
        expect(allCategories, contains('Problem-Solving and Data Analysis'));
        expect(allCategories, contains('Geometry and Trigonometry'));
      });

      test('should return all categories when null is passed', () {
        final allCategories =
            CategoryMappingService.getFilterableCategories(null);
        expect(allCategories, hasLength(8));
      });
    });

    group('getSubjectTypes', () {
      test('should return all available subject types', () {
        final subjectTypes = CategoryMappingService.getSubjectTypes();
        expect(subjectTypes, hasLength(2));
        expect(subjectTypes, contains('English'));
        expect(subjectTypes, contains('Math'));
      });
    });

    group('isValidCategory', () {
      test('should return true for valid categories', () {
        expect(CategoryMappingService.isValidCategory('Information and Ideas'),
            isTrue);
        expect(CategoryMappingService.isValidCategory('Algebra'), isTrue);
        expect(
            CategoryMappingService.isValidCategory(
                'Standard English Conventions'),
            isTrue);
        expect(
            CategoryMappingService.isValidCategory('Geometry and Trigonometry'),
            isTrue);
      });

      test('should return false for invalid categories', () {
        expect(CategoryMappingService.isValidCategory('Unknown Category'),
            isFalse);
        expect(CategoryMappingService.isValidCategory(''), isFalse);
        expect(CategoryMappingService.isValidCategory('algebra'),
            isFalse); // case sensitive
      });
    });

    group('isValidApiCode', () {
      test('should return true for valid API codes', () {
        expect(CategoryMappingService.isValidApiCode('INI'), isTrue);
        expect(CategoryMappingService.isValidApiCode('H'), isTrue);
        expect(CategoryMappingService.isValidApiCode('SEC'), isTrue);
        expect(CategoryMappingService.isValidApiCode('S'), isTrue);
      });

      test('should return false for invalid API codes', () {
        expect(CategoryMappingService.isValidApiCode('UNKNOWN'), isFalse);
        expect(CategoryMappingService.isValidApiCode(''), isFalse);
        expect(CategoryMappingService.isValidApiCode('ini'),
            isFalse); // case sensitive
      });
    });

    group('getSubjectTypeForCategory', () {
      test('should return correct subject type for English categories', () {
        expect(
            CategoryMappingService.getSubjectTypeForCategory(
                'Information and Ideas'),
            equals('English'));
        expect(
            CategoryMappingService.getSubjectTypeForCategory(
                'Craft and Structure'),
            equals('English'));
        expect(
            CategoryMappingService.getSubjectTypeForCategory(
                'Expression of Ideas'),
            equals('English'));
        expect(
            CategoryMappingService.getSubjectTypeForCategory(
                'Standard English Conventions'),
            equals('English'));
      });

      test('should return correct subject type for Math categories', () {
        expect(CategoryMappingService.getSubjectTypeForCategory('Algebra'),
            equals('Math'));
        expect(
            CategoryMappingService.getSubjectTypeForCategory('Advanced Math'),
            equals('Math'));
        expect(
            CategoryMappingService.getSubjectTypeForCategory(
                'Problem-Solving and Data Analysis'),
            equals('Math'));
        expect(
            CategoryMappingService.getSubjectTypeForCategory(
                'Geometry and Trigonometry'),
            equals('Math'));
      });

      test('should return null for unknown categories', () {
        expect(
            CategoryMappingService.getSubjectTypeForCategory(
                'Unknown Category'),
            isNull);
        expect(CategoryMappingService.getSubjectTypeForCategory(''), isNull);
        expect(CategoryMappingService.getSubjectTypeForCategory('algebra'),
            isNull); // case sensitive
      });
    });

    group('bidirectional mapping consistency', () {
      test(
          'should maintain consistency between category-to-API and API-to-category mappings',
          () {
        final categories = [
          'Information and Ideas',
          'Craft and Structure',
          'Expression of Ideas',
          'Standard English Conventions',
          'Algebra',
          'Advanced Math',
          'Problem-Solving and Data Analysis',
          'Geometry and Trigonometry',
        ];

        for (final category in categories) {
          final apiCode = CategoryMappingService.getApiCode(category);
          final backToCategory =
              CategoryMappingService.getUserFriendlyCategory(apiCode);
          expect(backToCategory, equals(category),
              reason: 'Bidirectional mapping failed for category: $category');
        }
      });

      test(
          'should maintain consistency between API-to-category and category-to-API mappings',
          () {
        final apiCodes = ['INI', 'CAS', 'EOI', 'SEC', 'H', 'P', 'Q', 'S'];

        for (final apiCode in apiCodes) {
          final category =
              CategoryMappingService.getUserFriendlyCategory(apiCode);
          final backToApiCode = CategoryMappingService.getApiCode(category);
          expect(backToApiCode, equals(apiCode),
              reason: 'Bidirectional mapping failed for API code: $apiCode');
        }
      });
    });

    group('edge cases', () {
      test('should handle empty strings consistently', () {
        expect(CategoryMappingService.getUserFriendlyCategory(''), equals(''));
        expect(CategoryMappingService.getApiCode(''), equals(''));
        expect(CategoryMappingService.isValidCategory(''), isFalse);
        expect(CategoryMappingService.isValidApiCode(''), isFalse);
        expect(CategoryMappingService.getSubjectTypeForCategory(''), isNull);
      });

      test('should handle whitespace-only strings', () {
        expect(
            CategoryMappingService.getUserFriendlyCategory(' '), equals(' '));
        expect(CategoryMappingService.getApiCode(' '), equals(' '));
        expect(CategoryMappingService.isValidCategory(' '), isFalse);
        expect(CategoryMappingService.isValidApiCode(' '), isFalse);
      });

      test('should handle special characters', () {
        const specialString = '!@#\$%^&*()';
        expect(CategoryMappingService.getUserFriendlyCategory(specialString),
            equals(specialString));
        expect(CategoryMappingService.getApiCode(specialString),
            equals(specialString));
      });
    });
  });
}
