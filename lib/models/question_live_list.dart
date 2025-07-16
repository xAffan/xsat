import './question_identifier.dart';

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
          .map((id) =>
              QuestionIdentifier(id: id as String, type: IdType.external))
          .toList(),
      englishIds: (json['readingLiveItems'] as List<dynamic>? ?? [])
          .map((id) =>
              QuestionIdentifier(id: id as String, type: IdType.external))
          .toList(),
    );
  }
}
