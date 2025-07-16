/// Model for structuring shareable content data
class ShareableContent {
  final String title;
  final String questionText;
  final List<String> answerChoices;
  final String? userAnswer;
  final String? correctAnswer;
  final String? explanation;
  final String formattedContent;

  ShareableContent({
    required this.title,
    required this.questionText,
    required this.answerChoices,
    this.userAnswer,
    this.correctAnswer,
    this.explanation,
    required this.formattedContent,
  });

  /// Converts the shareable content to a formatted text string
  String toShareableText() {
    return formattedContent;
  }

  /// Creates a ShareableContent from individual components
  factory ShareableContent.create({
    required String title,
    required String questionText,
    required List<String> answerChoices,
    String? userAnswer,
    String? correctAnswer,
    String? explanation,
  }) {
    final buffer = StringBuffer();

    // Add title
    buffer.writeln(title);
    buffer.writeln('=' * title.length);
    buffer.writeln();

    // Add question
    buffer.writeln('Question:');
    buffer.writeln(questionText);
    buffer.writeln();

    // Add answer choices
    if (answerChoices.isNotEmpty) {
      buffer.writeln('Answer Choices:');
      for (int i = 0; i < answerChoices.length; i++) {
        final choice = String.fromCharCode(65 + i); // A, B, C, D...
        buffer.writeln('$choice) ${answerChoices[i]}');
      }
      buffer.writeln();
    }

    // Add user answer if provided
    if (userAnswer != null && userAnswer.isNotEmpty) {
      buffer.writeln('Your Answer: $userAnswer');
      buffer.writeln();
    }

    // Add correct answer if provided
    if (correctAnswer != null && correctAnswer.isNotEmpty) {
      buffer.writeln('Correct Answer: $correctAnswer');
      buffer.writeln();
    }

    // Add explanation if provided
    if (explanation != null && explanation.isNotEmpty) {
      buffer.writeln('Explanation:');
      buffer.writeln(explanation);
      buffer.writeln();
    }

    // Add footer
    buffer.writeln('---');
    buffer.writeln('Shared from SAT Quiz App');

    return ShareableContent(
      title: title,
      questionText: questionText,
      answerChoices: answerChoices,
      userAnswer: userAnswer,
      correctAnswer: correctAnswer,
      explanation: explanation,
      formattedContent: buffer.toString(),
    );
  }
}
