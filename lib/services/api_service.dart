// lib/services/api_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/question.dart';
import '../models/question_identifier.dart';
import '../models/question_live_list.dart';
import '../models/question_metadata.dart';
import '../providers/settings_provider.dart'; // For QuestionType enum
import '../utils/logger.dart';
import '../utils/exceptions.dart';

class ApiService {
  final String _qbankBaseUrl =
      "https://qbank-api.collegeboard.org/msreportingquestionbank-prod/questionbank";
  final String _saicBaseUrl = "https://saic.collegeboard.org/disclosed";

  /// Fetches live question identifiers with comprehensive error handling
  Future<QuestionLiveList> getLiveQuestionIdentifiers() async {
    try {
      final url = Uri.parse("$_qbankBaseUrl/lookup");
      AppLogger.debug('Fetching live question identifiers from: $url',
          tag: 'ApiService');

      final response = await http.get(url).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          AppLogger.error('Timeout while fetching live question identifiers',
              tag: 'ApiService');
          throw TimeoutException(
              'Request timeout', const Duration(seconds: 30));
        },
      );

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          return QuestionLiveList.fromJson(jsonData);
        } catch (e, stackTrace) {
          AppLogger.error(
            'Failed to parse live question list JSON response',
            tag: 'ApiService',
            error: e,
            stackTrace: stackTrace,
          );
          throw FormatException('Invalid JSON response format: $e');
        }
      } else {
        AppLogger.error(
          'HTTP error ${response.statusCode} while fetching live question list',
          tag: 'ApiService',
        );
        throw HttpException(
            'HTTP ${response.statusCode}: Failed to load live question list');
      }
    } on SocketException catch (e, stackTrace) {
      AppLogger.error(
        'Network error while fetching live question identifiers',
        tag: 'ApiService',
        error: e,
        stackTrace: stackTrace,
      );
      throw NetworkException('Network connection failed: ${e.message}');
    } on TimeoutException catch (e, stackTrace) {
      AppLogger.error(
        'Timeout while fetching live question identifiers',
        tag: 'ApiService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Unexpected error while fetching live question identifiers',
        tag: 'ApiService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Fetches the list of all question identifiers (either external_id or ibn).
  /// Enhanced to capture and process question metadata from API responses with comprehensive error handling.
  Future<List<QuestionIdentifier>> getAllQuestionIdentifiers(
      {required int test, required String domain}) async {
    try {
      final url = Uri.parse("$_qbankBaseUrl/digital/get-questions");
      final requestBody = {"asmtEventId": 99, "test": test, "domain": domain};

      AppLogger.debug(
        'Fetching question identifiers for test: $test, domain: $domain',
        tag: 'ApiService',
      );

      final response = await http
          .post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),
      )
          .timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          AppLogger.error(
            'Timeout while fetching question identifiers for test: $test',
            tag: 'ApiService',
          );
          throw TimeoutException(
              'Request timeout', const Duration(seconds: 45));
        },
      );

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = json.decode(response.body);
          AppLogger.debug(
            'Successfully fetched ${data.length} raw question entries',
            tag: 'ApiService',
          );

          final identifiers = <QuestionIdentifier>[];
          int processedCount = 0;
          int errorCount = 0;

          for (final jsonItem in data) {
            try {
              final identifier =
                  createQuestionIdentifierWithMetadata(jsonItem, test);
              if (identifier != null) {
                identifiers.add(identifier);
                processedCount++;
              }
            } catch (e) {
              errorCount++;
              AppLogger.warning(
                'Failed to process question identifier: $e',
                tag: 'ApiService',
                error: e,
              );
            }
          }

          AppLogger.info(
            'Processed $processedCount question identifiers successfully, $errorCount errors',
            tag: 'ApiService',
          );

          if (identifiers.isEmpty && data.isNotEmpty) {
            throw DataException(
              'No valid question identifiers could be processed from API response',
            );
          }

          return identifiers;
        } catch (e, stackTrace) {
          AppLogger.error(
            'Failed to parse question identifiers JSON response',
            tag: 'ApiService',
            error: e,
            stackTrace: stackTrace,
          );
          throw DataException('Invalid JSON response format: $e',
              originalError: e);
        }
      } else {
        AppLogger.error(
          'HTTP error ${response.statusCode} while fetching question identifiers for test: $test',
          tag: 'ApiService',
        );
        throw ApiException(
          'Failed to load question list for test: $test',
          statusCode: response.statusCode,
        );
      }
    } on SocketException catch (e, stackTrace) {
      AppLogger.error(
        'Network error while fetching question identifiers',
        tag: 'ApiService',
        error: e,
        stackTrace: stackTrace,
      );
      throw NetworkException('Network connection failed: ${e.message}');
    } on TimeoutException catch (e, stackTrace) {
      AppLogger.error(
        'Timeout while fetching question identifiers',
        tag: 'ApiService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      if (e is AppException) {
        rethrow;
      }
      AppLogger.error(
        'Unexpected error while fetching question identifiers',
        tag: 'ApiService',
        error: e,
        stackTrace: stackTrace,
      );
      throw ApiException('Unexpected error: $e', originalError: e);
    }
  }

  /// Creates a QuestionIdentifier with metadata from API response JSON.
  /// Returns null for invalid data that should be filtered out.
  QuestionIdentifier? createQuestionIdentifierWithMetadata(
      Map<String, dynamic> json, int test) {
    try {
      // Validate input
      if (json.isEmpty) {
        AppLogger.warning(
            'Empty JSON object provided for question identifier creation',
            tag: 'ApiService');
        return null;
      }

      // Determine the identifier and type
      String? id;
      IdType? type;

      if (json['external_id'] != null) {
        id = json['external_id'].toString().trim();
        type = IdType.external;
      } else if (json['ibn'] != null) {
        id = json['ibn'].toString().trim();
        type = IdType.ibn;
      }

      // Return null if no valid identifier found
      if (id == null || id.isEmpty || type == null) {
        AppLogger.warning('No valid identifier found in JSON object',
            tag: 'ApiService');
        return null;
      }

      // Extract and create metadata with proper error handling
      QuestionMetadata? metadata;
      try {
        metadata = extractQuestionMetadata(json);
      } catch (e) {
        // Log the error but continue processing without metadata
        AppLogger.warning(
          'Failed to extract metadata for question $id: $e',
          tag: 'ApiService',
          error: e,
        );
        metadata = null;
      }

      return QuestionIdentifier(
        id: id,
        type: type,
        metadata: metadata,
        subjectType: test == 1 ? QuestionType.english : QuestionType.math,
      );
    } catch (e, stackTrace) {
      // Log the error and return null to filter out this entry
      AppLogger.error(
        'Error processing question identifier: $e',
        tag: 'ApiService',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Extracts question metadata from API response JSON.
  /// Handles missing or malformed metadata fields gracefully.
  QuestionMetadata? extractQuestionMetadata(Map<String, dynamic> json) {
    try {
      // Check if any metadata fields are present
      final hasMetadata = json.containsKey('skill_desc') ||
          json.containsKey('primary_class_cd_desc') ||
          json.containsKey('difficulty') ||
          json.containsKey('skill_cd') ||
          json.containsKey('primary_class_cd');

      // Return null if no metadata fields are present
      if (!hasMetadata) {
        AppLogger.debug('No metadata fields found in JSON object',
            tag: 'ApiService');
        return null;
      }

      // Validate that at least some essential fields have non-null values
      final hasValidData = (json['skill_desc'] != null &&
              json['skill_desc'].toString().isNotEmpty) ||
          (json['primary_class_cd_desc'] != null &&
              json['primary_class_cd_desc'].toString().isNotEmpty) ||
          (json['primary_class_cd'] != null &&
              json['primary_class_cd'].toString().isNotEmpty);

      if (!hasValidData) {
        AppLogger.debug('Metadata fields present but all empty or null',
            tag: 'ApiService');
        return null;
      }

      return QuestionMetadata.fromJson(json);
    } catch (e, stackTrace) {
      // Log the error and return null if metadata creation fails
      AppLogger.error(
        'Failed to create QuestionMetadata: $e',
        tag: 'ApiService',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Fetches the details for a single question using its identifier with comprehensive error handling.
  Future<Question> getQuestionDetails(QuestionIdentifier identifier) async {
    try {
      AppLogger.debug(
        'Fetching question details for ${identifier.type.name}: ${identifier.id}',
        tag: 'ApiService',
      );

      Question question;
      switch (identifier.type) {
        case IdType.external:
          question = await _fetchByExternalId(identifier.id);
          break;
        case IdType.ibn:
          question = await _fetchByIbn(identifier.id);
          break;
      }

      // Preserve metadata from identifier if the fetched question doesn't have metadata
      if (question.metadata == null && identifier.metadata != null) {
        AppLogger.debug(
          'Preserving metadata from identifier for question: ${identifier.id}',
          tag: 'ApiService',
        );
        question = Question(
          externalId: question.externalId,
          stimulus: question.stimulus,
          stem: question.stem,
          answerOptions: question.answerOptions,
          correctKey: question.correctKey,
          rationale: question.rationale,
          type: question.type,
          metadata: identifier.metadata, // Use metadata from identifier
        );
      }

      return question;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to fetch question details for ${identifier.type.name}: ${identifier.id}',
        tag: 'ApiService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Enhanced method for fetching by external_id with comprehensive error handling.
  Future<Question> _fetchByExternalId(String externalId) async {
    try {
      final url = Uri.parse("$_qbankBaseUrl/pdf-download");
      final requestBody = {
        "external_ids": [externalId]
      };

      AppLogger.debug('Fetching question by external_id: $externalId',
          tag: 'ApiService');

      final response = await http
          .post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          AppLogger.error(
            'Timeout while fetching question details for external_id: $externalId',
            tag: 'ApiService',
          );
          throw TimeoutException(
              'Request timeout', const Duration(seconds: 30));
        },
      );

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = json.decode(response.body);
          if (data.isEmpty) {
            throw DataException('Empty response for external_id: $externalId');
          }

          // Debug logging to see what fields are available
          final questionData = data.first as Map<String, dynamic>;
          AppLogger.debug('Question JSON keys: ${questionData.keys.toList()}',
              tag: 'ApiService');

          // Check for metadata fields specifically
          final metadataFields = [
            'skill_desc',
            'primary_class_cd_desc',
            'difficulty',
            'skill_cd',
            'primary_class_cd'
          ];
          final availableMetadataFields = metadataFields
              .where((field) => questionData.containsKey(field))
              .toList();
          AppLogger.debug('Available metadata fields: $availableMetadataFields',
              tag: 'ApiService');

          return Question.fromJson(questionData);
        } catch (e, stackTrace) {
          AppLogger.error(
            'Failed to parse question details JSON for external_id: $externalId',
            tag: 'ApiService',
            error: e,
            stackTrace: stackTrace,
          );
          throw DataException('Invalid JSON response format: $e',
              originalError: e);
        }
      } else {
        AppLogger.error(
          'HTTP error ${response.statusCode} while fetching question details for external_id: $externalId',
          tag: 'ApiService',
        );
        throw ApiException(
          'Failed to load question details for external_id: $externalId',
          statusCode: response.statusCode,
        );
      }
    } on SocketException catch (e, stackTrace) {
      AppLogger.error(
        'Network error while fetching question details for external_id: $externalId',
        tag: 'ApiService',
        error: e,
        stackTrace: stackTrace,
      );
      throw NetworkException('Network connection failed: ${e.message}');
    } on TimeoutException catch (e, stackTrace) {
      AppLogger.error(
        'Timeout while fetching question details for external_id: $externalId',
        tag: 'ApiService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      if (e is AppException) {
        rethrow;
      }
      AppLogger.error(
        'Unexpected error while fetching question details for external_id: $externalId',
        tag: 'ApiService',
        error: e,
        stackTrace: stackTrace,
      );
      throw ApiException('Unexpected error: $e', originalError: e);
    }
  }

  /// Enhanced method for fetching by IBN with comprehensive error handling.
  Future<Question> _fetchByIbn(String ibn) async {
    try {
      final url = Uri.parse("$_saicBaseUrl/$ibn.json");
      AppLogger.debug('Fetching question by ibn: $ibn', tag: 'ApiService');

      final response = await http.get(url).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          AppLogger.error(
            'Timeout while fetching question details for ibn: $ibn',
            tag: 'ApiService',
          );
          throw TimeoutException(
              'Request timeout', const Duration(seconds: 30));
        },
      );

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = json.decode(response.body);
          if (data.isEmpty) {
            throw DataException('Empty response for ibn: $ibn');
          }
          final normalizedData = _transformIbnResponse(data.first);
          return Question.fromJson(normalizedData);
        } catch (e, stackTrace) {
          AppLogger.error(
            'Failed to parse question details JSON for ibn: $ibn',
            tag: 'ApiService',
            error: e,
            stackTrace: stackTrace,
          );
          throw DataException('Invalid JSON response format: $e',
              originalError: e);
        }
      } else {
        AppLogger.error(
          'HTTP error ${response.statusCode} while fetching question details for ibn: $ibn',
          tag: 'ApiService',
        );
        throw ApiException(
          'Failed to load question details for ibn: $ibn',
          statusCode: response.statusCode,
        );
      }
    } on SocketException catch (e, stackTrace) {
      AppLogger.error(
        'Network error while fetching question details for ibn: $ibn',
        tag: 'ApiService',
        error: e,
        stackTrace: stackTrace,
      );
      throw NetworkException('Network connection failed: ${e.message}');
    } on TimeoutException catch (e, stackTrace) {
      AppLogger.error(
        'Timeout while fetching question details for ibn: $ibn',
        tag: 'ApiService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      if (e is AppException) {
        rethrow;
      }
      AppLogger.error(
        'Unexpected error while fetching question details for ibn: $ibn',
        tag: 'ApiService',
        error: e,
        stackTrace: stackTrace,
      );
      throw ApiException('Unexpected error: $e', originalError: e);
    }
  }

  /// ** FIXED: Normalizer to transform the IBN JSON structure to our standard format. **
  Map<String, dynamic> _transformIbnResponse(Map<String, dynamic> ibnJson) {
    // Safely access the 'answer' object as a nullable map to prevent crashes.
    final answerData = ibnJson['answer'] as Map<String, dynamic>?;

    // Safely build the list of answer options.
    List<Map<String, dynamic>> answerOptions = [];
    // Proceed only if answerData is not null.
    if (answerData != null) {
      // Safely access 'choices', ensuring it's a Map.
      final choicesData = answerData['choices'] as Map<String, dynamic>?;
      if (choicesData != null) {
        answerOptions = choicesData.entries.map((entry) {
          // Ensure the value of each choice is a Map before accessing its 'body'.
          final choiceValue = entry.value as Map<String, dynamic>?;
          return {
            'id': entry.key,
            'content': choiceValue?['body'] ??
                '', // Default to an empty string if 'body' is missing.
          };
        }).toList();
      }
    }

    // Determine the question type with more robust logic.
    String questionType;
    final style = answerData?['style']?.toString().toLowerCase();

    if (style == 'multiple choice') {
      questionType = 'mcq';
    } else if (style != null && style.isNotEmpty) {
      // Use the provided style if it's not 'multiple choice' (e.g., 'spr').
      questionType = style;
    } else {
      // If 'style' is missing, infer the type from the presence of answer options.
      // This correctly identifies text-input questions (SPR) vs. multiple-choice (MCQ).
      questionType = answerOptions.isNotEmpty ? 'mcq' : 'spr';
    }

    return {
      // Use null-coalescing for robust ID retrieval.
      'externalid': ibnJson['item_id'] ?? ibnJson['ibn'] ?? '',

      // Safely get stimulus and stem, defaulting to empty strings.
      'stimulus': ibnJson['body'] ?? '',
      'stem': ibnJson['prompt'] ?? '',

      'answerOptions': answerOptions,

      // Safely get the correct answer key using a collection-if for clean list creation.
      'keys': [
        if (answerData?['correct_choice'] != null) answerData!['correct_choice']
      ],

      // Safely get the rationale with a fallback message.
      'rationale': answerData?['rationale'] ?? 'No rationale provided.',

      'type': questionType,
    };
  }
}
