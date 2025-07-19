import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/question.dart';
import '../models/shareable_content.dart';
import '../services/content_renderer.dart';
import '../utils/logger.dart';

/// Service for text-based sharing functionality
class TextSharingService {
  static const String _logTag = 'TextSharingService';

  /// Generates shareable text content from a question, user answer, and explanation
  ///
  /// This method combines all the question components into a formatted text
  /// that can be shared across different platforms while preserving complex content.
  Future<String> generateShareableText(
    Question question,
    String? userAnswer,
    String? explanation,
  ) async {
    try {
      AppLogger.info(
          'Generating shareable text for question: ${question.externalId}',
          tag: _logTag);

      // Format the question content using string interpolation
      final formattedQuestion =
          formatQuestionContent('${question.stimulus} ${question.stem}');

      // Format answer choices
      final formattedChoices = formatAnswerChoices(
        question.answerOptions.map((option) => option.content).toList(),
      );

      // Format explanation (use provided explanation or question rationale)
      final formattedExplanation = formatExplanation(
        explanation ?? question.rationale,
      );

      // Create shareable content
      final shareableContent = ShareableContent.create(
        title: _generateTitle(question),
        questionText: formattedQuestion,
        answerChoices: formattedChoices,
        userAnswer: userAnswer,
        correctAnswer: question.correctKey,
        explanation: formattedExplanation,
      );

      return shareableContent.toShareableText();
    } catch (e) {
      AppLogger.error('Error generating shareable text: $e', tag: _logTag);
      rethrow;
    }
  }

  /// Formats question content to properly handle complex content types
  ///
  /// This method processes the question text and renders any complex content
  /// such as mathematical expressions, tables, or SVG graphics.
  String formatQuestionContent(String content) {
    try {
      AppLogger.info('Formatting question content', tag: _logTag);

      if (content.isEmpty) {
        return 'No question content available.';
      }

      // Check if content contains mathematical expressions
      if (_containsMathContent(content)) {
        return ContentRenderer.renderMathContent(content);
      }

      // Check if content contains HTML tables
      if (_containsTableContent(content)) {
        final tableData = _extractTableData(content);
        return ContentRenderer.renderTableContent(tableData);
      }

      // Check if content contains SVG
      if (_containsSvgContent(content)) {
        return ContentRenderer.renderSvgContent(content);
      }

      // For regular HTML content, strip HTML tags and return clean text
      return _stripHtmlTags(content);
    } catch (e) {
      AppLogger.error('Error formatting question content: $e', tag: _logTag);
      return content; // Return original content as fallback
    }
  }

  /// Formats answer choices into a structured list
  ///
  /// This method processes the answer options and formats them consistently
  /// for sharing, handling any complex content within the choices.
  List<String> formatAnswerChoices(List<String> choices) {
    try {
      AppLogger.info('Formatting ${choices.length} answer choices', tag: _logTag);

      return choices.map((choice) {
        // Handle mathematical content in choices
        if (_containsMathContent(choice)) {
          return ContentRenderer.renderMathContent(choice);
        }

        // Handle SVG content in choices
        if (_containsSvgContent(choice)) {
          return ContentRenderer.renderSvgContent(choice);
        }

        // Strip HTML tags for regular content
        return _stripHtmlTags(choice);
      }).toList();
    } catch (e) {
      AppLogger.error('Error formatting answer choices: $e', tag: _logTag);
      return choices; // Return original choices as fallback
    }
  }

  /// Formats explanation content for sharing
  ///
  /// This method processes the rationale/explanation text and renders
  /// any complex content appropriately for text-based sharing.
  String formatExplanation(String explanation) {
    try {
      AppLogger.info('Formatting explanation content', tag: _logTag);

      if (explanation.isEmpty || explanation == 'No rationale provided.') {
        return 'No explanation available.';
      }

      // Handle mathematical content in explanation
      if (_containsMathContent(explanation)) {
        return ContentRenderer.renderMathContent(explanation);
      }

      // Handle table content in explanation
      if (_containsTableContent(explanation)) {
        final tableData = _extractTableData(explanation);
        return ContentRenderer.renderTableContent(tableData);
      }

      // Handle SVG content in explanation
      if (_containsSvgContent(explanation)) {
        return ContentRenderer.renderSvgContent(explanation);
      }

      // Strip HTML tags for regular content
      return _stripHtmlTags(explanation);
    } catch (e) {
      AppLogger.error('Error formatting explanation: $e', tag: _logTag);
      return explanation; // Return original explanation as fallback
    }
  }

  /// Shares text content using the platform's sharing mechanism
  ///
  /// This method uses the share_plus package to share the formatted text
  /// content with appropriate fallback handling.
  Future<void> shareTextContent(String content, String title) async {
    try {
      AppLogger.info('Sharing text content with title: $title', tag: _logTag);

      // Use Share.share() with the correct API
      await Share.share(content);

      AppLogger.info('Text content shared successfully', tag: _logTag);
    } catch (e) {
      AppLogger.error('Error sharing text content: $e', tag: _logTag);

      // Fallback: copy to clipboard
      try {
        await Clipboard.setData(ClipboardData(text: content));
        AppLogger.info('Content copied to clipboard as fallback', tag: _logTag);
        throw ShareFallbackException('Content copied to clipboard');
      } catch (clipboardError) {
        AppLogger.error('Failed to copy to clipboard: $clipboardError',
            tag: _logTag);
        throw Exception('Failed to share content: $e');
      }
    }
  }

  // Private helper methods

  /// Generates an appropriate title for the question
  String _generateTitle(Question question) {
    final questionType = question.type.toUpperCase();
    final hasMetadata = question.metadata != null;

    if (hasMetadata && question.metadata!.skillDescription.isNotEmpty) {
      return 'SAT $questionType - ${question.metadata!.skillDescription}';
    }

    if (hasMetadata && question.metadata!.primaryClassDescription.isNotEmpty) {
      return 'SAT $questionType - ${question.metadata!.primaryClassDescription}';
    }

    return 'SAT $questionType Question';
  }

  /// Checks if content contains mathematical expressions
  bool _containsMathContent(String content) {
    return content.contains(r'\frac') ||
        content.contains(r'\sqrt') ||
        content.contains(r'\sum') ||
        content.contains(r'\int') ||
        content.contains(r'\pi') ||
        content.contains(r'\alpha') ||
        content.contains(r'\beta') ||
        content.contains(r'\gamma') ||
        content.contains(r'\delta') ||
        content.contains(r'\theta') ||
        content.contains(r'\lambda') ||
        content.contains(r'\mu') ||
        content.contains(r'\sigma') ||
        content.contains(r'\infty') ||
        content.contains(r'\leq') ||
        content.contains(r'\geq') ||
        content.contains(r'\neq') ||
        content.contains(r'\approx') ||
        content.contains(r'\pm') ||
        content.contains(r'\(') ||
        content.contains(r'\[') ||
        content.contains(r'$') ||
        content.contains('<math') ||
        content.contains('<mml:');
  }

  /// Checks if content contains table elements
  bool _containsTableContent(String content) {
    return content.contains('<table') ||
        content.contains('<tr') ||
        content.contains('<td') ||
        content.contains('<th');
  }

  /// Checks if content contains SVG elements
  bool _containsSvgContent(String content) {
    return content.contains('<svg') || content.contains('.svg');
  }

  /// Extracts table data from HTML content
  Map<String, dynamic> _extractTableData(String content) {
    return {'html': content};
  }

  /// Strips HTML tags from content and returns clean text
  String _stripHtmlTags(String content) {
    // Simple HTML tag removal - replace with proper HTML parsing if needed
    return content
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

/// Custom exception for sharing fallback scenarios
class ShareFallbackException implements Exception {
  final String message;
  const ShareFallbackException(this.message);

  @override
  String toString() => message;
}
