// lib/models/question_identifier.dart

import 'question_metadata.dart';

// Enum to define the type of identifier we are working with.
enum IdType { external, ibn }

/// A class to hold either an `external_id` or an `ibn`, and identify its type.
/// This prevents passing raw strings and makes the logic much safer and clearer.
class QuestionIdentifier {
  final String id;
  final IdType type;
  final QuestionMetadata? metadata;

  QuestionIdentifier({
    required this.id,
    required this.type,
    this.metadata,
  });
}
