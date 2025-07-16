import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/api_service.dart';
import '../../lib/models/question_identifier.dart';

void main() {
  group('ApiService - Metadata Extraction Tests', () {
    late ApiService apiService;

    setUp(() {
      apiService = ApiService();
    });

    group('createQuestionIdentifierWithMetadata', () {
      test('should create QuestionIdentifier with complete metadata', () {
        // Arrange
        final json = {
          'external_id': 'test_123',
          'skill_desc': 'Form, Structure, and Sense',
          'primary_class_cd_desc': 'Standard English Conventions',
          'difficulty': 'M',
          'skill_cd': 'FSS',
          'primary_class_cd': 'SEC',
        };

        // Act
        final result = apiService.createQuestionIdentifierWithMetadata(json);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals('test_123'));
        expect(result.type, equals(IdType.external));
        expect(result.metadata, isNotNull);
        expect(result.metadata!.skillDescription,
            equals('Form, Structure, and Sense'));
        expect(result.metadata!.primaryClassDescription,
            equals('Standard English Conventions'));
        expect(result.metadata!.difficulty, equals('M'));
        expect(result.metadata!.skillCode, equals('FSS'));
        expect(result.metadata!.primaryClassCode, equals('SEC'));
      });

      test('should create QuestionIdentifier with partial metadata', () {
        // Arrange
        final json = {
          'external_id': 'test_456',
          'skill_desc': 'Reading Comprehension',
          'difficulty': 'H',
          // Missing other metadata fields
        };

        // Act
        final result = apiService.createQuestionIdentifierWithMetadata(json);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals('test_456'));
        expect(result.type, equals(IdType.external));
        expect(result.metadata, isNotNull);
        expect(
            result.metadata!.skillDescription, equals('Reading Comprehension'));
        expect(result.metadata!.primaryClassDescription,
            equals('Unknown Category'));
        expect(result.metadata!.difficulty, equals('H'));
        expect(result.metadata!.skillCode, equals(''));
        expect(result.metadata!.primaryClassCode, equals(''));
      });

      test('should create QuestionIdentifier with ibn type', () {
        // Arrange
        final json = {
          'ibn': 'ibn_789',
          'skill_desc': 'Algebra',
          'primary_class_cd_desc': 'Advanced Math',
          'difficulty': 'E',
          'skill_cd': 'ALG',
          'primary_class_cd': 'AM',
        };

        // Act
        final result = apiService.createQuestionIdentifierWithMetadata(json);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals('ibn_789'));
        expect(result.type, equals(IdType.ibn));
        expect(result.metadata, isNotNull);
        expect(result.metadata!.skillDescription, equals('Algebra'));
        expect(
            result.metadata!.primaryClassDescription, equals('Advanced Math'));
        expect(result.metadata!.difficulty, equals('E'));
        expect(result.metadata!.skillCode, equals('ALG'));
        expect(result.metadata!.primaryClassCode, equals('AM'));
      });

      test(
          'should create QuestionIdentifier without metadata when no metadata fields present',
          () {
        // Arrange
        final json = {
          'external_id': 'test_no_metadata',
          // No metadata fields
        };

        // Act
        final result = apiService.createQuestionIdentifierWithMetadata(json);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals('test_no_metadata'));
        expect(result.type, equals(IdType.external));
        expect(result.metadata, isNull);
      });

      test('should return null for invalid data with no identifier', () {
        // Arrange
        final json = {
          'skill_desc': 'Some skill',
          // No external_id or ibn
        };

        // Act
        final result = apiService.createQuestionIdentifierWithMetadata(json);

        // Assert
        expect(result, isNull);
      });

      test('should handle malformed metadata gracefully', () {
        // Arrange
        final json = {
          'external_id': 'test_malformed',
          'skill_desc': 123, // Invalid type
          'primary_class_cd_desc': null,
          'difficulty': 'M',
        };

        // Act
        final result = apiService.createQuestionIdentifierWithMetadata(json);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals('test_malformed'));
        expect(result.type, equals(IdType.external));
        expect(result.metadata, isNotNull);
        expect(result.metadata!.skillDescription,
            equals('123')); // Converted to string
        expect(result.metadata!.primaryClassDescription,
            equals('Unknown Category'));
        expect(result.metadata!.difficulty, equals('M'));
      });
    });

    group('extractQuestionMetadata', () {
      test('should extract complete metadata', () {
        // Arrange
        final json = {
          'skill_desc': 'Problem Solving',
          'primary_class_cd_desc': 'Geometry and Trigonometry',
          'difficulty': 'H',
          'skill_cd': 'PS',
          'primary_class_cd': 'GT',
        };

        // Act
        final result = apiService.extractQuestionMetadata(json);

        // Assert
        expect(result, isNotNull);
        expect(result!.skillDescription, equals('Problem Solving'));
        expect(result.primaryClassDescription,
            equals('Geometry and Trigonometry'));
        expect(result.difficulty, equals('H'));
        expect(result.skillCode, equals('PS'));
        expect(result.primaryClassCode, equals('GT'));
      });

      test('should return null when no metadata fields present', () {
        // Arrange
        final json = {
          'external_id': 'test_123',
          'other_field': 'value',
        };

        // Act
        final result = apiService.extractQuestionMetadata(json);

        // Assert
        expect(result, isNull);
      });

      test('should extract partial metadata with defaults', () {
        // Arrange
        final json = {
          'skill_desc': 'Data Analysis',
          // Missing other fields
        };

        // Act
        final result = apiService.extractQuestionMetadata(json);

        // Assert
        expect(result, isNotNull);
        expect(result!.skillDescription, equals('Data Analysis'));
        expect(result.primaryClassDescription, equals('Unknown Category'));
        expect(result.difficulty, equals('M')); // Default
        expect(result.skillCode, equals(''));
        expect(result.primaryClassCode, equals(''));
      });

      test('should handle null values gracefully', () {
        // Arrange
        final json = {
          'skill_desc': null,
          'primary_class_cd_desc': 'Information and Ideas',
          'difficulty': null,
          'skill_cd': 'II',
          'primary_class_cd': null,
        };

        // Act
        final result = apiService.extractQuestionMetadata(json);

        // Assert
        expect(result, isNotNull);
        expect(result!.skillDescription, equals('Unknown Skill'));
        expect(result.primaryClassDescription, equals('Information and Ideas'));
        expect(result.difficulty, equals('M')); // Default
        expect(result.skillCode, equals('II'));
        expect(result.primaryClassCode, equals(''));
      });
    });

    group('Error Handling', () {
      test('should handle JSON parsing errors gracefully', () {
        // Arrange
        final malformedJson = {
          'external_id': 'test_error',
          'skill_desc': {'nested': 'object'}, // This might cause issues
        };

        // Act & Assert - Should not throw
        expect(
            () =>
                apiService.createQuestionIdentifierWithMetadata(malformedJson),
            returnsNormally);
      });

      test('should continue processing when metadata extraction fails', () {
        // Arrange
        final json = {
          'external_id': 'test_continue',
          'skill_desc': 'Valid skill',
        };

        // Act
        final result = apiService.createQuestionIdentifierWithMetadata(json);

        // Assert - Should still create identifier even if metadata fails
        expect(result, isNotNull);
        expect(result!.id, equals('test_continue'));
        expect(result.type, equals(IdType.external));
      });
    });
  });
}
