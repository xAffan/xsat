import 'question_metadata.dart';

class Question {
  final String externalId;
  final String stimulus;
  final String stem;
  final List<AnswerOption> answerOptions;
  final String correctKey;
  final String rationale;
  final String type;
  final QuestionMetadata? metadata;

  Question({
    required this.externalId,
    required this.stimulus,
    required this.stem,
    required this.answerOptions,
    required this.correctKey,
    required this.rationale,
    required this.type,
    this.metadata,
  });

  /// A more robust factory for creating a Question from JSON.
  factory Question.fromJson(Map<String, dynamic> json) {
    // Safely parse the list of answer options.
    final optionsList = json['answerOptions'] as List?;
    List<AnswerOption> options = [];
    if (optionsList != null) {
      options = optionsList
          // Filter out any non-map or null items to prevent crashes.
          .whereType<Map<String, dynamic>>()
          .map((item) => AnswerOption.fromJson(item))
          .toList();
    }

    // Safely access the 'keys' list to find the correct answer.
    String correctKey = (json['keys'] as List?)?.isNotEmpty == true
        ? json['keys'][0]?.toString() ?? ''
        : '';

    // If correctKey is still empty, try to extract it from the rationale
    if (correctKey.isEmpty) {
      final rationale = json['rationale']?.toString() ?? '';
      final regex = RegExp(r"The correct answer is ((?:(?!\.\s).)+)\.\s");
      final match = regex.firstMatch(rationale);
      if (match != null) {
        correctKey = match.group(1)?.trim() ?? '';
      }
    }

    // Create metadata if available in JSON
    QuestionMetadata? metadata;
    if (json.containsKey('skill_desc') ||
        json.containsKey('primary_class_cd_desc') ||
        json.containsKey('difficulty') ||
        json.containsKey('skill_cd') ||
        json.containsKey('primary_class_cd')) {
      metadata = QuestionMetadata.fromJson(json);
    }

    return Question(
      // Ensure all values are converted to strings with safe fallbacks.
      externalId: json['externalid']?.toString() ?? '',

      stimulus: (json['stimulus']?.toString() ?? ''),

      stem: json['stem']?.toString() ?? '',

      answerOptions: options,

      correctKey: correctKey,

      rationale: json['rationale']?.toString() ?? 'No rationale provided.',

      // CRITICAL FIX: Use the null-aware operator (?.) before .toLowerCase()
      type: json['type']?.toString().toLowerCase() ?? 'mcq',

      metadata: metadata,
    );
  }
}

class AnswerOption {
  final String id;
  final String content;

  AnswerOption({required this.id, required this.content});

  /// A robust factory for creating an AnswerOption from JSON.
  factory AnswerOption.fromJson(Map<String, dynamic> json) {
    return AnswerOption(
      // Safely convert ID and content to strings, handling nulls.
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
    );
  }
}
