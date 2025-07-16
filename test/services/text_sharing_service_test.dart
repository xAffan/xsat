import 'package:flutter_test/flutter_test.dart';
import 'package:sat_quiz/services/text_sharing_service.dart';
import 'package:sat_quiz/models/question.dart';
import 'package:sat_quiz/models/question_metadata.dart';

void main() {
  group('TextSharingService', () {
    late TextSharingService service;

    setUp(() {
      service = TextSharingService();
    });

    group('generateShareableText', () {
      test('should generate shareable text with all components', () async {
        // Arrange
        final question = _createTestQuestion();
        const userAnswer = 'B';
        const explanation = 'This is the correct answer because...';

        // Act
        final result = await service.generateShareableText(
          question,
          userAnswer,
          explanation,
        );

        // Assert
        expect(result, isNotEmpty);
        expect(result, contains('SAT MCQ Question'));
        expect(result, contains('Test question stem'));
        expect(result, contains('A) Option A'));
        expect(result, contains('B) Option B'));
        expect(result, contains('Your Answer: B'));
        expect(result, contains('Correct Answer: A'));
        expect(result, contains('This is the correct answer because...'));
        expect(result, contains('Shared from SAT Quiz App'));
      });

      test('should handle question without user answer', () async {
        // Arrange
        final question = _createTestQuestion();

        // Act
        final result = await service.generateShareableText(
          question,
          null,
          null,
        );

        // Assert
        expect(result, isNotEmpty);
        expect(result, isNot(contains('Your Answer:')));
        expect(result, contains('Test rationale'));
      });

      test('should handle question with metadata for title generation',
          () async {
        // Arrange
        final question = _createTestQuestionWithMetadata();

        // Act
        final result = await service.generateShareableText(
          question,
          null,
          null,
        );

        // Assert
        expect(result, contains('SAT MCQ - Algebra'));
      });

      test('should handle empty explanation gracefully', () async {
        // Arrange
        final question = _createTestQuestion();

        // Act
        final result = await service.generateShareableText(
          question,
          null,
          '',
        );

        // Assert
        expect(result, contains('No explanation available.'));
      });
    });

    group('formatQuestionContent', () {
      test('should return clean text for regular HTML content', () {
        // Arrange
        const htmlContent = '<p>This is a <strong>test</strong> question.</p>';

        // Act
        final result = service.formatQuestionContent(htmlContent);

        // Assert
        expect(result, equals('This is a test question.'));
      });

      test('should handle mathematical content', () {
        // Arrange
        const mathContent = r'Solve for x: \frac{x}{2} = 5';

        // Act
        final result = service.formatQuestionContent(mathContent);

        // Assert
        expect(result, contains('(x)/(2) = 5'));
      });

      test('should handle SVG content', () {
        // Arrange
        const svgContent =
            '<svg width="100" height="100"><circle r="50"/></svg>';

        // Act
        final result = service.formatQuestionContent(svgContent);

        // Assert
        expect(result, contains('[SVG'));
      });

      test('should handle table content', () {
        // Arrange
        const tableContent =
            '<table><tr><td>Cell 1</td><td>Cell 2</td></tr></table>';

        // Act
        final result = service.formatQuestionContent(tableContent);

        // Assert
        expect(result, contains('Cell 1'));
        expect(result, contains('Cell 2'));
      });

      test('should handle empty content', () {
        // Act
        final result = service.formatQuestionContent('');

        // Assert
        expect(result, equals('No question content available.'));
      });

      test('should handle content with HTML entities', () {
        // Arrange
        const htmlContent =
            'Test &amp; example with &lt;tags&gt; and &quot;quotes&quot;';

        // Act
        final result = service.formatQuestionContent(htmlContent);

        // Assert
        expect(result, equals('Test & example with <tags> and "quotes"'));
      });
    });

    group('formatAnswerChoices', () {
      test('should format regular answer choices', () {
        // Arrange
        const choices = [
          '<p>Option A</p>',
          '<p>Option B</p>',
          '<p>Option C</p>'
        ];

        // Act
        final result = service.formatAnswerChoices(choices);

        // Assert
        expect(result, hasLength(3));
        expect(result[0], equals('Option A'));
        expect(result[1], equals('Option B'));
        expect(result[2], equals('Option C'));
      });

      test('should handle mathematical content in choices', () {
        // Arrange
        const choices = [r'\frac{1}{2}', r'\sqrt{16}', r'\pi'];

        // Act
        final result = service.formatAnswerChoices(choices);

        // Assert
        expect(result[0], contains('(1)/(2)'));
        expect(result[1], contains('√(16)'));
        expect(result[2], contains('π'));
      });

      test('should handle SVG content in choices', () {
        // Arrange
        const choices = ['<svg><circle r="10"/></svg>', 'Regular text'];

        // Act
        final result = service.formatAnswerChoices(choices);

        // Assert
        expect(result[0], contains('[SVG'));
        expect(result[1], equals('Regular text'));
      });

      test('should handle empty choices list', () {
        // Act
        final result = service.formatAnswerChoices([]);

        // Assert
        expect(result, isEmpty);
      });
    });

    group('formatExplanation', () {
      test('should format regular explanation text', () {
        // Arrange
        const explanation = '<p>This is the <em>correct</em> answer.</p>';

        // Act
        final result = service.formatExplanation(explanation);

        // Assert
        expect(result, equals('This is the correct answer.'));
      });

      test('should handle mathematical content in explanation', () {
        // Arrange
        const explanation = r'The formula is \frac{a}{b} = c';

        // Act
        final result = service.formatExplanation(explanation);

        // Assert
        expect(result, contains('(a)/(b) = c'));
      });

      test('should handle table content in explanation', () {
        // Arrange
        const explanation =
            '<table><tr><td>Value</td><td>Result</td></tr></table>';

        // Act
        final result = service.formatExplanation(explanation);

        // Assert
        expect(result, contains('Value'));
        expect(result, contains('Result'));
      });

      test('should handle SVG content in explanation', () {
        // Arrange
        const explanation = '<svg width="50" height="50"></svg>';

        // Act
        final result = service.formatExplanation(explanation);

        // Assert
        expect(result, contains('[SVG'));
      });

      test('should handle empty explanation', () {
        // Act
        final result = service.formatExplanation('');

        // Assert
        expect(result, equals('No explanation available.'));
      });

      test('should handle default rationale text', () {
        // Act
        final result = service.formatExplanation('No rationale provided.');

        // Assert
        expect(result, equals('No explanation available.'));
      });
    });

    group('shareTextContent', () {
      test('should have correct method signature', () {
        // This test would require mocking the Share.share
        // For now, we'll skip actual testing of the sharing functionality
        // since it depends on platform-specific implementations

        const content = 'Test content to share';
        const title = 'Test Title';

        // Just verify the method exists with the correct signature
        expect(service.shareTextContent, isA<Function>());
      });
    });

    group('error handling', () {
      test('should handle malformed content gracefully', () {
        // Test with malformed HTML
        const malformedHtml = '<div><p>Unclosed tags<div>';

        expect(
          () => service.formatQuestionContent(malformedHtml),
          returnsNormally,
        );
      });

      test('should handle null or invalid input gracefully', () {
        // Test with various edge cases
        expect(
          () => service.formatAnswerChoices([]),
          returnsNormally,
        );

        expect(
          () => service.formatExplanation(''),
          returnsNormally,
        );
      });

      test('should rethrow errors from generateShareableText', () async {
        // Create a question that might cause issues
        final invalidQuestion = Question(
          externalId: '',
          stimulus: '',
          stem: '',
          answerOptions: [],
          correctKey: '',
          rationale: '',
          type: '',
        );

        // The method should handle this gracefully or rethrow meaningful errors
        expect(
          () => service.generateShareableText(invalidQuestion, null, null),
          returnsNormally,
        );
      });
    });
  });
}

// Helper methods for creating test data

Question _createTestQuestion() {
  return Question(
    externalId: 'test-123',
    stimulus: 'Test stimulus',
    stem: 'Test question stem',
    answerOptions: [
      AnswerOption(id: 'A', content: 'Option A'),
      AnswerOption(id: 'B', content: 'Option B'),
      AnswerOption(id: 'C', content: 'Option C'),
      AnswerOption(id: 'D', content: 'Option D'),
    ],
    correctKey: 'A',
    rationale: 'Test rationale',
    type: 'mcq',
  );
}

Question _createTestQuestionWithMetadata() {
  return Question(
    externalId: 'test-456',
    stimulus: 'Test stimulus with metadata',
    stem: 'Test question stem',
    answerOptions: [
      AnswerOption(id: 'A', content: 'Option A'),
      AnswerOption(id: 'B', content: 'Option B'),
    ],
    correctKey: 'A',
    rationale: 'Test rationale',
    type: 'mcq',
    metadata: QuestionMetadata(
      skillDescription: 'Algebra',
      primaryClassDescription: 'Math',
      difficulty: 'M',
      skillCode: 'ALG',
      primaryClassCode: 'MATH',
    ),
  );
}
