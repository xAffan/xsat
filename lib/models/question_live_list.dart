import './question_identifier.dart';
import '../providers/settings_provider.dart';

class QuestionLiveList {
  final List<QuestionIdentifier> mathIds;
  final List<QuestionIdentifier> englishIds;

  QuestionLiveList({
    required this.mathIds,
    required this.englishIds,
  });

  factory QuestionLiveList.fromJson(Map<String, dynamic> json) {
    return QuestionLiveList(
      mathIds: (json['mathLiveItems'] as List<dynamic>? ?? [])
          .map((id) => QuestionIdentifier(
              id: id as String,
              type: IdType.external,
              subjectType: QuestionType.math))
          .toList(),
      englishIds: (json['readingLiveItems'] as List<dynamic>? ?? [])
          .map((id) => QuestionIdentifier(
              id: id as String,
              type: IdType.external,
              subjectType: QuestionType.english))
          .toList(),
    );
  }
}
