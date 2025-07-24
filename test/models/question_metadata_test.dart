import 'package:flutter_test/flutter_test.dart';
import 'package:xsat/models/question_metadata.dart';

void main() {
  group('QuestionMetadata', () {
    group('fromJson', () {
      test('should create QuestionMetadata with complete data', () {
        // Arrange
        final json = {
          'skill_desc': 'Form, Structure, and Sense',
          'primary_class_cd_desc': 'Standard English Conventions',
          'difficulty': 'H',
          'skill_cd': 'FSS',
          'primary_class_cd': 'SEC',
        };

        // Act
        final metadata = QuestionMetadata.fromJson(json);

        // Assert
        expect(metadata.skillDescription, 'Form, Structure, and Sense');
        expect(
            metadata.primaryClassDescription, 'Standard English Conventions');
        expect(metadata.difficulty, 'H');
        expect(metadata.skillCode, 'FSS');
        expect(metadata.primaryClassCode, 'SEC');
      });

      test('should handle missing fields with default values', () {
        // Arrange
        final json = <String, dynamic>{};

        // Act
        final metadata = QuestionMetadata.fromJson(json);

        // Assert
        expect(metadata.skillDescription, 'Unknown Skill');
        expect(metadata.primaryClassDescription, 'Unknown Category');
        expect(metadata.difficulty, 'M');
        expect(metadata.skillCode, '');
        expect(metadata.primaryClassCode, '');
      });

      test('should handle null values with default values', () {
        // Arrange
        final json = {
          'skill_desc': null,
          'primary_class_cd_desc': null,
          'difficulty': null,
          'skill_cd': null,
          'primary_class_cd': null,
        };

        // Act
        final metadata = QuestionMetadata.fromJson(json);

        // Assert
        expect(metadata.skillDescription, 'Unknown Skill');
        expect(metadata.primaryClassDescription, 'Unknown Category');
        expect(metadata.difficulty, 'M');
        expect(metadata.skillCode, '');
        expect(metadata.primaryClassCode, '');
      });

      test('should handle partial data with mixed null and valid values', () {
        // Arrange
        final json = {
          'skill_desc': 'Algebra Basics',
          'primary_class_cd_desc': null,
          'difficulty': 'E',
          'skill_cd': null,
          'primary_class_cd': 'ALG',
        };

        // Act
        final metadata = QuestionMetadata.fromJson(json);

        // Assert
        expect(metadata.skillDescription, 'Algebra Basics');
        expect(metadata.primaryClassDescription, 'Unknown Category');
        expect(metadata.difficulty, 'E');
        expect(metadata.skillCode, '');
        expect(metadata.primaryClassCode, 'ALG');
      });

      test('should convert non-string values to strings', () {
        // Arrange
        final json = {
          'skill_desc': 123,
          'primary_class_cd_desc': true,
          'difficulty': 456,
          'skill_cd': 789,
          'primary_class_cd': false,
        };

        // Act
        final metadata = QuestionMetadata.fromJson(json);

        // Assert
        expect(metadata.skillDescription, '123');
        expect(metadata.primaryClassDescription, 'true');
        expect(metadata.difficulty, '456');
        expect(metadata.skillCode, '789');
        expect(metadata.primaryClassCode, 'false');
      });
    });

    group('toJson', () {
      test('should convert QuestionMetadata to JSON correctly', () {
        // Arrange
        final metadata = QuestionMetadata(
          skillDescription: 'Test Skill',
          primaryClassDescription: 'Test Category',
          difficulty: 'M',
          skillCode: 'TST',
          primaryClassCode: 'TC',
        );

        // Act
        final json = metadata.toJson();

        // Assert
        expect(json['skill_desc'], 'Test Skill');
        expect(json['primary_class_cd_desc'], 'Test Category');
        expect(json['difficulty'], 'M');
        expect(json['skill_cd'], 'TST');
        expect(json['primary_class_cd'], 'TC');
      });
    });

    group('equality and hashCode', () {
      test('should be equal when all fields match', () {
        // Arrange
        final metadata1 = QuestionMetadata(
          skillDescription: 'Test Skill',
          primaryClassDescription: 'Test Category',
          difficulty: 'M',
          skillCode: 'TST',
          primaryClassCode: 'TC',
        );

        final metadata2 = QuestionMetadata(
          skillDescription: 'Test Skill',
          primaryClassDescription: 'Test Category',
          difficulty: 'M',
          skillCode: 'TST',
          primaryClassCode: 'TC',
        );

        // Act & Assert
        expect(metadata1, equals(metadata2));
        expect(metadata1.hashCode, equals(metadata2.hashCode));
      });

      test('should not be equal when fields differ', () {
        // Arrange
        final metadata1 = QuestionMetadata(
          skillDescription: 'Test Skill',
          primaryClassDescription: 'Test Category',
          difficulty: 'M',
          skillCode: 'TST',
          primaryClassCode: 'TC',
        );

        final metadata2 = QuestionMetadata(
          skillDescription: 'Different Skill',
          primaryClassDescription: 'Test Category',
          difficulty: 'M',
          skillCode: 'TST',
          primaryClassCode: 'TC',
        );

        // Act & Assert
        expect(metadata1, isNot(equals(metadata2)));
      });
    });

    group('toString', () {
      test('should return formatted string representation', () {
        // Arrange
        final metadata = QuestionMetadata(
          skillDescription: 'Test Skill',
          primaryClassDescription: 'Test Category',
          difficulty: 'M',
          skillCode: 'TST',
          primaryClassCode: 'TC',
        );

        // Act
        final result = metadata.toString();

        // Assert
        expect(result, contains('QuestionMetadata'));
        expect(result, contains('skillDescription: Test Skill'));
        expect(result, contains('primaryClassDescription: Test Category'));
        expect(result, contains('difficulty: M'));
        expect(result, contains('skillCode: TST'));
        expect(result, contains('primaryClassCode: TC'));
      });
    });
  });
}
