// lib/models/question_identifier.dart

import 'question_metadata.dart';
import '../providers/settings_provider.dart'; // For QuestionType enum

// Enum to define the type of identifier we are working with.
enum IdType { external, ibn }

/// A class to hold either an `external_id` or an `ibn`, and identify its type.
/// This prevents passing raw strings and makes the logic much safer and clearer.
class QuestionIdentifier {
  final String id;
  final IdType type;
  final QuestionMetadata? metadata;
  final QuestionType subjectType; // English or Math

  QuestionIdentifier({
    required this.id,
    required this.type,
    this.metadata,
    this.subjectType =
        QuestionType.both, // Default to both for backward compatibility
  });
}
