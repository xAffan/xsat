import 'package:hive/hive.dart';

part 'mistake.g.dart';

@HiveType(typeId: 0)
class Mistake extends HiveObject {
  @HiveField(0)
  final String question;

  @HiveField(1)
  final String userAnswer;

  @HiveField(2)
  final String correctAnswer;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final String rationale;

  @HiveField(5)
  final String userAnswerLabel;

  @HiveField(6)
  final String correctAnswerLabel;

  @HiveField(7)
  final String difficulty;

  @HiveField(8)
  final String category;

  @HiveField(9)
  final String subject;

  // New field: all answer options as label/content pairs
  @HiveField(10)
  final List<MistakeAnswerOption> answerOptions;

  // Fields for better sync functionality
  @HiveField(11)
  final String? questionId;

  @HiveField(12)
  final String? questionType;

  @HiveField(13)
  final String? questionIdType; // 'external' or 'ibn'

  Mistake({
    required this.question,
    required this.userAnswer,
    required this.correctAnswer,
    required this.timestamp,
    required this.rationale,
    required this.userAnswerLabel,
    required this.correctAnswerLabel,
    required this.difficulty,
    required this.category,
    required this.subject,
    required this.answerOptions,
    this.questionId,
    this.questionType,
    this.questionIdType,
  });
}

@HiveType(typeId: 1)
class MistakeAnswerOption {
  @HiveField(0)
  final String label;
  @HiveField(1)
  final String content;
  MistakeAnswerOption({required this.label, required this.content});
}
