import 'dart:math' as math;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import '../models/content_block.dart';
import '../utils/logger.dart';

/// Service for rendering complex content types including math, tables, and SVG
class ContentRenderer {
  static const String _logTag = 'ContentRenderer';

  /// Renders mathematical content from LaTeX or MathML to a text representation
  ///
  /// This method processes mathematical expressions and converts them to a format
  /// suitable for text-based sharing while preserving mathematical meaning.
  static String renderMathContent(String mathExpression) {
    try {
      Logger.info(
          'Rendering math content: ${mathExpression.substring(0, mathExpression.length > 50 ? 50 : mathExpression.length)}...',
          tag: _logTag);

      // Handle LaTeX expressions
      if (mathExpression.contains(r'\frac') ||
          mathExpression.contains(r'\sqrt') ||
          mathExpression.contains(r'\sum') ||
          mathExpression.contains(r'\int') ||
          mathExpression.contains(r'\pi') ||
          mathExpression.contains(r'\alpha') ||
          mathExpression.contains(r'\beta') ||
          mathExpression.contains(r'\gamma') ||
          mathExpression.contains(r'\delta') ||
          mathExpression.contains(r'\theta') ||
          mathExpression.contains(r'\lambda') ||
          mathExpression.contains(r'\mu') ||
          mathExpression.contains(r'\sigma') ||
          mathExpression.contains(r'\infty') ||
          mathExpression.contains(r'\leq') ||
          mathExpression.contains(r'\geq') ||
          mathExpression.contains(r'\neq') ||
          mathExpression.contains(r'\approx') ||
          mathExpression.contains(r'\pm') ||
          mathExpression.contains(r'\(') ||
          mathExpression.contains(r'\[') ||
          mathExpression.contains(r'$$')) {
        return _renderLatexExpression(mathExpression);
      }

      // Handle MathML expressions
      if (mathExpression.contains('<math') ||
          mathExpression.contains('<mml:')) {
        return _renderMathMLExpression(mathExpression);
      }

      // Handle HTML with math tags
      if (mathExpression.contains('<') && mathExpression.contains('>')) {
        return _renderHtmlMathExpression(mathExpression);
      }

      // Return as-is if no special math formatting detected
      return mathExpression;
    } catch (e) {
      Logger.error('Error rendering math content: $e', tag: _logTag);
      return '[Math Expression: ${mathExpression.length > 100 ? '${mathExpression.substring(0, 100)}...' : mathExpression}]';
    }
  }

  /// Renders table content from HTML or structured data to formatted text
  ///
  /// This method converts table data into a text format that preserves
  /// the table structure using ASCII formatting.
  static String renderTableContent(Map<String, dynamic> tableData) {
    try {
      Logger.info('Rendering table content', tag: _logTag);

      // Handle HTML table string
      if (tableData.containsKey('html')) {
        return _renderHtmlTable(tableData['html'] as String);
      }

      // Handle structured table data
      if (tableData.containsKey('rows') && tableData.containsKey('headers')) {
        return _renderStructuredTable(
          tableData['headers'] as List<String>,
          tableData['rows'] as List<List<String>>,
        );
      }

      // Handle simple key-value table
      if (tableData.containsKey('data')) {
        return _renderKeyValueTable(tableData['data'] as Map<String, dynamic>);
      }

      return '[Table: ${tableData.toString()}]';
    } catch (e) {
      Logger.error('Error rendering table content: $e', tag: _logTag);
      return '[Table: Unable to render]';
    }
  }

  /// Renders SVG content to a text description or converts to image data
  ///
  /// This method processes SVG content and either provides a text description
  /// or converts it to a format suitable for sharing.
  static String renderSvgContent(String svgData) {
    try {
      Logger.info('Rendering SVG content', tag: _logTag);

      // Extract title or description from SVG if available
      final document = html_parser.parse(svgData);
      final svgElement = document.querySelector('svg');

      if (svgElement != null) {
        // Try to get title or description
        final title = svgElement.querySelector('title')?.text;
        final desc = svgElement.querySelector('desc')?.text;

        if (title != null && title.isNotEmpty) {
          return '[SVG: $title]';
        }

        if (desc != null && desc.isNotEmpty) {
          return '[SVG: $desc]';
        }

        // Try to extract dimensions for context
        final width = svgElement.attributes['width'];
        final height = svgElement.attributes['height'];

        if (width != null && height != null) {
          return '[SVG Image: ${width}x$height]';
        }
      }

      return '[SVG Image]';
    } catch (e) {
      Logger.error('Error rendering SVG content: $e', tag: _logTag);
      return '[SVG: Unable to render]';
    }
  }

  /// Renders mixed content containing multiple content types
  ///
  /// This method processes a list of content blocks and renders each
  /// according to its type, combining them into a cohesive text format.
  static String renderMixedContent(List<ContentBlock> blocks) {
    try {
      Logger.info('Rendering mixed content with ${blocks.length} blocks',
          tag: _logTag);

      final buffer = StringBuffer();

      for (int i = 0; i < blocks.length; i++) {
        final block = blocks[i];

        switch (block.type) {
          case ContentType.text:
            buffer.write(block.content);
            break;
          case ContentType.math:
            buffer.write(renderMathContent(block.content));
            break;
          case ContentType.table:
            if (block.metadata != null) {
              buffer.write(renderTableContent(block.metadata!));
            } else {
              buffer.write('[Table]');
            }
            break;
          case ContentType.svg:
            buffer.write(renderSvgContent(block.content));
            break;
          case ContentType.image:
            final alt = block.metadata?['alt'] ?? 'Image';
            buffer.write('[Image: $alt]');
            break;
        }

        // Add spacing between blocks except for the last one
        if (i < blocks.length - 1) {
          buffer.write('\n\n');
        }
      }

      return buffer.toString();
    } catch (e) {
      Logger.error('Error rendering mixed content: $e', tag: _logTag);
      return blocks.map((block) => block.render()).join('\n\n');
    }
  }

  // Private helper methods

  /// Renders LaTeX mathematical expressions to text
  static String _renderLatexExpression(String latex) {
    // Remove LaTeX delimiters first
    String cleaned = latex
        .replaceAll(r'\(', '')
        .replaceAll(r'\)', '')
        .replaceAll(r'\[', '')
        .replaceAll(r'\]', '')
        .replaceAll(r'$$', '')
        .replaceAll('\n', '');

    // Handle fractions first (more complex pattern)
    cleaned = _processFractions(cleaned);

    // Handle square roots
    cleaned = _processSquareRoots(cleaned);

    // Convert common LaTeX symbols to Unicode
    cleaned = cleaned
        .replaceAll(r'\sum', '∑')
        .replaceAll(r'\int', '∫')
        .replaceAll(r'\pi', 'π')
        .replaceAll(r'\alpha', 'α')
        .replaceAll(r'\beta', 'β')
        .replaceAll(r'\gamma', 'γ')
        .replaceAll(r'\delta', 'δ')
        .replaceAll(r'\theta', 'θ')
        .replaceAll(r'\lambda', 'λ')
        .replaceAll(r'\mu', 'μ')
        .replaceAll(r'\sigma', 'σ')
        .replaceAll(r'\infty', '∞')
        .replaceAll(r'\leq', '≤')
        .replaceAll(r'\geq', '≥')
        .replaceAll(r'\neq', '≠')
        .replaceAll(r'\approx', '≈')
        .replaceAll(r'\pm', '±');

    return cleaned.trim();
  }

  /// Processes LaTeX fractions and converts them to readable format
  static String _processFractions(String input) {
    String result = input;

    // Handle \frac{numerator}{denominator} pattern
    final fracRegex = RegExp(
        r'\\frac\{([^{}]*(?:\{[^{}]*\}[^{}]*)*)\}\{([^{}]*(?:\{[^{}]*\}[^{}]*)*)\}');

    while (fracRegex.hasMatch(result)) {
      result = result.replaceAllMapped(fracRegex, (match) {
        final numerator = match.group(1) ?? '';
        final denominator = match.group(2) ?? '';
        return '($numerator)/($denominator)';
      });
    }

    return result;
  }

  /// Processes LaTeX square roots and converts them to readable format
  static String _processSquareRoots(String input) {
    String result = input;

    // Handle \sqrt{content} pattern
    final sqrtRegex = RegExp(r'\\sqrt\{([^{}]*(?:\{[^{}]*\}[^{}]*)*)\}');

    while (sqrtRegex.hasMatch(result)) {
      result = result.replaceAllMapped(sqrtRegex, (match) {
        final content = match.group(1) ?? '';
        return '√($content)';
      });
    }

    return result;
  }

  /// Renders MathML expressions to text
  static String _renderMathMLExpression(String mathml) {
    try {
      final document = html_parser.parse(mathml);
      final mathElement = document.querySelector('math') ??
          document.querySelector('mml\\:math');

      if (mathElement != null) {
        return _extractMathMLText(mathElement);
      }

      return mathml;
    } catch (e) {
      return '[MathML Expression]';
    }
  }

  /// Extracts text content from MathML elements
  static String _extractMathMLText(html_dom.Element element) {
    final buffer = StringBuffer();

    // If element has direct text content, use it
    if (element.children.isEmpty && element.text.isNotEmpty) {
      return element.text;
    }

    for (final child in element.children) {
      switch (child.localName) {
        case 'mi': // identifier
        case 'mn': // number
        case 'mo': // operator
        case 'mtext': // text
          buffer.write(child.text);
          break;
        case 'mfrac': // fraction
          final numerator = child.children.isNotEmpty
              ? _extractMathMLText(child.children[0])
              : '';
          final denominator = child.children.length > 1
              ? _extractMathMLText(child.children[1])
              : '';
          buffer.write('($numerator)/($denominator)');
          break;
        case 'msqrt': // square root
          final content = child.children.isNotEmpty
              ? _extractMathMLText(child.children[0])
              : '';
          buffer.write('√($content)');
          break;
        case 'msup': // superscript
          final base = child.children.isNotEmpty
              ? _extractMathMLText(child.children[0])
              : '';
          final exp = child.children.length > 1
              ? _extractMathMLText(child.children[1])
              : '';
          buffer.write('$base^$exp');
          break;
        case 'msub': // subscript
          final base = child.children.isNotEmpty
              ? _extractMathMLText(child.children[0])
              : '';
          final sub = child.children.length > 1
              ? _extractMathMLText(child.children[1])
              : '';
          buffer.write('${base}_$sub');
          break;
        default:
          // Recursively process other elements
          if (child.children.isNotEmpty) {
            buffer.write(_extractMathMLText(child));
          } else {
            buffer.write(child.text);
          }
      }
    }

    return buffer.toString();
  }

  /// Renders HTML containing math expressions
  static String _renderHtmlMathExpression(String html) {
    try {
      final document = html_parser.parse(html);
      return document.body?.text ?? html;
    } catch (e) {
      return html;
    }
  }

  /// Renders HTML table to formatted text
  static String _renderHtmlTable(String htmlTable) {
    try {
      final document = html_parser.parse(htmlTable);
      final table = document.querySelector('table');

      if (table == null) return '[Table: No table found]';

      final rows = <List<String>>[];

      // Extract headers
      final headerRow =
          table.querySelector('thead tr') ?? table.querySelector('tr');
      if (headerRow != null) {
        final headers = headerRow
            .querySelectorAll('th, td')
            .map((cell) => cell.text.trim())
            .toList();
        if (headers.isNotEmpty) {
          rows.add(headers);
        }
      }

      // Extract data rows
      final dataRows = table.querySelectorAll('tbody tr, tr');
      for (final row in dataRows) {
        if (row == headerRow) {
          continue; // Skip header row if it was already processed
        }

        final cells = row
            .querySelectorAll('td, th')
            .map((cell) => cell.text.trim())
            .toList();
        if (cells.isNotEmpty) {
          rows.add(cells);
        }
      }

      return _formatTableRows(rows);
    } catch (e) {
      return '[Table: Unable to parse HTML]';
    }
  }

  /// Renders structured table data to formatted text
  static String _renderStructuredTable(
      List<String> headers, List<List<String>> rows) {
    final allRows = <List<String>>[headers, ...rows];
    return _formatTableRows(allRows);
  }

  /// Renders key-value table data to formatted text
  static String _renderKeyValueTable(Map<String, dynamic> data) {
    final buffer = StringBuffer();

    for (final entry in data.entries) {
      buffer.writeln('${entry.key}: ${entry.value}');
    }

    return buffer.toString().trim();
  }

  /// Formats table rows into ASCII table format
  static String _formatTableRows(List<List<String>> rows) {
    if (rows.isEmpty) return '[Empty Table]';

    // Calculate column widths
    final columnWidths = <int>[];
    for (final row in rows) {
      for (int i = 0; i < row.length; i++) {
        if (i >= columnWidths.length) {
          columnWidths.add(0);
        }
        columnWidths[i] = math.max(columnWidths[i], row[i].length);
      }
    }

    final buffer = StringBuffer();

    // Create separator line
    final separator =
        '+${columnWidths.map((width) => '-' * (width + 2)).join('+')}+';

    for (int rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];

      // Add separator before first row and after header
      if (rowIndex == 0 || rowIndex == 1) {
        buffer.writeln(separator);
      }

      // Add row content
      buffer.write('|');
      for (int colIndex = 0; colIndex < columnWidths.length; colIndex++) {
        final cellContent = colIndex < row.length ? row[colIndex] : '';
        final paddedContent = cellContent.padRight(columnWidths[colIndex]);
        buffer.write(' $paddedContent |');
      }
      buffer.writeln();
    }

    // Add final separator
    buffer.writeln(separator);

    return buffer.toString();
  }
}
