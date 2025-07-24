import 'package:flutter_test/flutter_test.dart';
import 'package:xsat/models/question.dart';
import 'package:xsat/models/question_metadata.dart';

void main() {
  group('Question', () {
    group('fromJson with metadata', () {
      test(
          'should create Question with metadata when metadata fields are present',
          () {
        // Arrange
        final json = {
          'externalid': 'test123',
          'stimulus': 'Test stimulus',
          'stem': 'Test question stem',
          'answerOptions': [
            {'id': 'A', 'content': 'Option A'},
            {'id': 'B', 'content': 'Option B'},
          ],
          'keys': ['A'],
          'rationale': 'Test rationale',
          'type': 'MCQ',
          'skill_desc': 'Test Skill',
          'primary_class_cd_desc': 'Test Category',
          'difficulty': 'M',
          'skill_cd': 'TST',
          'primary_class_cd': 'TC',
        };

        // Act
        final question = Question.fromJson(json);

        // Assert
        expect(question.externalId, 'test123');
        expect(question.metadata, isNotNull);
        expect(question.metadata!.skillDescription, 'Test Skill');
        expect(question.metadata!.primaryClassDescription, 'Test Category');
        expect(question.metadata!.difficulty, 'M');
        expect(question.metadata!.skillCode, 'TST');
        expect(question.metadata!.primaryClassCode, 'TC');
      });

      test(
          'should create Question without metadata when no metadata fields are present',
          () {
        // Arrange
        final json = {
          'externalid': 'test123',
          'stimulus': 'Test stimulus',
          'stem': 'Test question stem',
          'answerOptions': [
            {'id': 'A', 'content': 'Option A'},
            {'id': 'B', 'content': 'Option B'},
          ],
          'keys': ['A'],
          'rationale': 'Test rationale',
          'type': 'MCQ',
        };

        // Act
        final question = Question.fromJson(json);

        // Assert
        expect(question.externalId, 'test123');
        expect(question.metadata, isNull);
      });

      test(
          'should create Question with metadata when only some metadata fields are present',
          () {
        // Arrange
        final json = {
          'externalid': 'test123',
          'stimulus': 'Test stimulus',
          'stem': 'Test question stem',
          'answerOptions': [
            {'id': 'A', 'content': 'Option A'},
          ],
          'keys': ['A'],
          'rationale': 'Test rationale',
          'type': 'MCQ',
          'skill_desc': 'Partial Skill',
          // Missing other metadata fields
        };

        // Act
        final question = Question.fromJson(json);

        // Assert
        expect(question.metadata, isNotNull);
        expect(question.metadata!.skillDescription, 'Partial Skill');
        expect(question.metadata!.primaryClassDescription, 'Unknown Category');
        expect(question.metadata!.difficulty, 'M');
      });
    });

    group('constructor with metadata', () {
      test('should create Question with metadata', () {
        // Arrange
        final metadata = QuestionMetadata(
          skillDescription: 'Test Skill',
          primaryClassDescription: 'Test Category',
          difficulty: 'H',
          skillCode: 'TST',
          primaryClassCode: 'TC',
        );

        final answerOptions = [
          AnswerOption(id: 'A', content: 'Option A'),
          AnswerOption(id: 'B', content: 'Option B'),
        ];

        // Act
        final question = Question(
          externalId: 'test123',
          stimulus: 'Test stimulus',
          stem: 'Test stem',
          answerOptions: answerOptions,
          correctKey: 'A',
          rationale: 'Test rationale',
          type: 'mcq',
          metadata: metadata,
        );

        // Assert
        expect(question.metadata, equals(metadata));
        expect(question.metadata!.skillDescription, 'Test Skill');
      });

      test('should create Question without metadata', () {
        // Arrange
        final answerOptions = [
          AnswerOption(id: 'A', content: 'Option A'),
        ];

        // Act
        final question = Question(
          externalId: 'test123',
          stimulus: 'Test stimulus',
          stem: 'Test stem',
          answerOptions: answerOptions,
          correctKey: 'A',
          rationale: 'Test rationale',
          type: 'mcq',
        );

        // Assert
        expect(question.metadata, isNull);
      });
    });
  });
}
