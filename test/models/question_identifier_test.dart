import 'package:flutter_test/flutter_test.dart';
import 'package:sat_quiz/models/question_identifier.dart';
import 'package:sat_quiz/models/question_metadata.dart';

void main() {
  group('QuestionIdentifier', () {
    group('constructor with metadata', () {
      test('should create QuestionIdentifier with metadata', () {
        // Arrange
        final metadata = QuestionMetadata(
          skillDescription: 'Test Skill',
          primaryClassDescription: 'Test Category',
          difficulty: 'E',
          skillCode: 'TST',
          primaryClassCode: 'TC',
        );

        // Act
        final identifier = QuestionIdentifier(
          id: 'test123',
          type: IdType.external,
          metadata: metadata,
        );

        // Assert
        expect(identifier.id, 'test123');
        expect(identifier.type, IdType.external);
        expect(identifier.metadata, equals(metadata));
        expect(identifier.metadata!.skillDescription, 'Test Skill');
      });

      test('should create QuestionIdentifier without metadata', () {
        // Act
        final identifier = QuestionIdentifier(
          id: 'test456',
          type: IdType.ibn,
        );

        // Assert
        expect(identifier.id, 'test456');
        expect(identifier.type, IdType.ibn);
        expect(identifier.metadata, isNull);
      });
    });

    group('IdType enum', () {
      test('should have correct enum values', () {
        expect(IdType.values, contains(IdType.external));
        expect(IdType.values, contains(IdType.ibn));
        expect(IdType.values.length, 2);
      });
    });
  });
}
