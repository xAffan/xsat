/// Model class for storing additional question metadata from API responses
class QuestionMetadata {
  final String skillDescription;
  final String primaryClassDescription;
  final String difficulty;
  final String skillCode;
  final String primaryClassCode;

  QuestionMetadata({
    required this.skillDescription,
    required this.primaryClassDescription,
    required this.difficulty,
    required this.skillCode,
    required this.primaryClassCode,
  });

  /// Factory constructor to create QuestionMetadata from JSON with null-safe field extraction
  /// and default values for missing or null fields
  factory QuestionMetadata.fromJson(Map<String, dynamic> json) {
    return QuestionMetadata(
      skillDescription: json['skill_desc']?.toString() ?? 'Unknown Skill',
      primaryClassDescription:
          json['primary_class_cd_desc']?.toString() ?? 'Unknown Category',
      difficulty: json['difficulty']?.toString() ?? 'M', // Default to Medium
      skillCode: json['skill_cd']?.toString() ?? '',
      primaryClassCode: json['primary_class_cd']?.toString() ?? '',
    );
  }

  /// Convert QuestionMetadata to JSON
  Map<String, dynamic> toJson() {
    return {
      'skill_desc': skillDescription,
      'primary_class_cd_desc': primaryClassDescription,
      'difficulty': difficulty,
      'skill_cd': skillCode,
      'primary_class_cd': primaryClassCode,
    };
  }

  @override
  String toString() {
    return 'QuestionMetadata(skillDescription: $skillDescription, '
        'primaryClassDescription: $primaryClassDescription, '
        'difficulty: $difficulty, skillCode: $skillCode, '
        'primaryClassCode: $primaryClassCode)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuestionMetadata &&
        other.skillDescription == skillDescription &&
        other.primaryClassDescription == primaryClassDescription &&
        other.difficulty == difficulty &&
        other.skillCode == skillCode &&
        other.primaryClassCode == primaryClassCode;
  }

  @override
  int get hashCode {
    return skillDescription.hashCode ^
        primaryClassDescription.hashCode ^
        difficulty.hashCode ^
        skillCode.hashCode ^
        primaryClassCode.hashCode;
  }
}
