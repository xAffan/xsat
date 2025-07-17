import 'dart:core';
import 'dart:convert';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:image/image.dart' as img;

class HtmlProcessor {
  /// A map to convert simple verbal expressions from `alttext` into symbols.
  static const Map<String, String> _simpleReplacements = {
    // Simple standalone terms
    'percent sign': '%',
    'degree sign': '°',

    // Simple units that are often wrapped in <math> tags
    'centimeters': 'cm',
    'meters': 'm',
    'kilometers': 'km',
    'inches': 'in',
    'feet': 'ft',
    'yards': 'yd',
    'miles': 'mi',

    // Add other simple, direct replacements here.
  };

  /// Pre-processes an HTML string with a "smart helper" approach using proper HTML parsing.
  static String process(String html, {bool darkMode = false}) {
    // Parse the HTML document
    final document = html_parser.parse(html);

    // --- Step 1: Process MathML elements with robust, pattern-based logic ---
    _processMathElements(document);

    // --- Step 2: Fix MathML rendering issues ---
    _fixMathMLRendering(document);

    // --- Step 3: Fix trigonometric functions in MathML safely ---
    _fixTrigonometricFunctions(document);

    // --- Step 3.1: Add space before closing </math> tags ---
    _addSpaceToMathML(document);

    // --- Step 4: Fix nested tables that cause crashes ---
    _fixNestedTables(document);

    // --- Step 5: Remove screen reader only elements ---
    _removeScreenReaderElements(document);

    // --- Step 6: Style images for better visibility in dark mode ---
    if (darkMode) {
      _styleImages(document);
      // --- Step 7 (NEW): Invert colors for SVGs for visibility in dark mode ---
      _styleSvgElements(document);
    }

    // --- Step 8: Remove problematic attributes only
    _fixStyles(document);

    // --- Step 9: Remove figure elements without their children
    _fixFigures(document);

    // --- Step 10: Remove all classes since they are not used in Flutter HTML ---
    _removeAllClasses(document);

    // Return the processed HTML
    return document.body?.innerHtml ?? document.outerHtml;
  }

  /// Removes all class attributes from elements in the document.
  static void _removeAllClasses(dom.Document document) {
    final allElements = document.querySelectorAll('*');
    for (final element in allElements) {
      if (element.attributes.containsKey('class')) {
        element.attributes.remove('class');
      }
    }
  }

  static void _fixFigures(dom.Document document) {
    // Remove <figure> elements without affecting their children
    final figures = document.querySelectorAll('figure');
    for (final figure in figures) {
      if (figure.children.isEmpty) {
        figure.remove();
      } else {
        // If it has children, just remove the <figure> tag but keep the children
        final parent = figure.parent;
        if (parent != null) {
          for (final child in figure.children) {
            parent.insertBefore(child, figure);
          }
          figure.remove();
        }
      }
    }
  }

  /// This fixes the styles of stuff inside tables
  static void _fixStyles(dom.Document document) {
    final allElements = document.querySelectorAll('*');
    for (final element in allElements) {
      // Remove width and height from style attribute if present
      if (element.attributes.containsKey('style')) {
        var style = element.attributes['style']!;
        // Remove width and height CSS properties using regex
        style = style.replaceAll(
            RegExp(r'width\s*:\s*[^;]+;?', caseSensitive: false), '');
        style = style.replaceAll(
            RegExp(r'height\s*:\s*[^;]+;?', caseSensitive: false), '');
        // Clean up any leftover semicolons or whitespace
        style = style.replaceAll(RegExp(r';{2,}'), ';').trim();
        if (style.endsWith(';')) style = style.substring(0, style.length - 1);
        if (style.trim().isEmpty) {
          element.attributes.remove('style');
        } else {
          element.attributes['style'] = style;
        }
      }
    }
  }

  static void _fixNestedTables(dom.Document document) {
    // Find all tables that are nested inside other tables
    final nestedTables = document.querySelectorAll('table table');

    for (final innerTable in nestedTables) {
      // Find the root table that contains this nested table
      dom.Element? rootTable = innerTable.parent;
      while (rootTable != null && rootTable.localName != 'table') {
        rootTable = rootTable.parent;
      }
      if (rootTable == null) continue;

      // Make sure we have a tbody in the root table
      dom.Element? tbody = rootTable.querySelector('tbody');
      if (tbody == null) {
        tbody = dom.Element.tag('tbody');
        rootTable.append(tbody);
      }

      // Find the container element that holds the nested table
      dom.Element? container = innerTable.parent;
      dom.Element? containerRow;

      // Walk up to find the row that contains this nested table
      while (container != null && container.localName != 'tr') {
        container = container.parent;
      }
      containerRow = container;

      // Extract any heading text from elements before the table
      String headingText = '';
      final siblings = innerTable.parent?.children ?? [];
      for (final sibling in siblings) {
        if (sibling == innerTable) break;
        if (sibling.localName == 'p' || sibling.localName == 'div') {
          final text = sibling.text.trim();
          if (text.isNotEmpty) {
            headingText = text;
            break;
          }
        }
      }

      // Determine column count from the inner table
      int colCount = 0;
      final colgroup = innerTable.querySelector('colgroup');
      if (colgroup != null) {
        colCount = colgroup.querySelectorAll('col').length;
      } else {
        // Look for the first row with actual cells
        final allRows = innerTable.querySelectorAll('tr');
        for (final row in allRows) {
          final cells = row.children
              .where((e) => e.localName == 'td' || e.localName == 'th')
              .toList();
          if (cells.isNotEmpty) {
            colCount = cells.length;
            break;
          }
        }
      }
      if (colCount == 0) colCount = 2; // reasonable default

      // Add heading row if we found heading text
      if (headingText.isNotEmpty) {
        final headerTr = dom.Element.tag('tr');
        final headerTd = dom.Element.tag('td')
          ..attributes['colspan'] = colCount.toString()
          ..attributes['style'] = 'text-align:center;'
          ..text = headingText;
        headerTr.append(headerTd);
        tbody.append(headerTr);
      }

      // Move all rows from the inner table to the root table
      // Look for rows in various possible locations
      final innerRows = <dom.Element>[];

      // First try tbody > tr
      innerRows.addAll(innerTable.querySelectorAll('tbody > tr'));

      // If no tbody rows found, try direct tr children
      if (innerRows.isEmpty) {
        innerRows.addAll(innerTable.querySelectorAll('tr'));
      }

      // Clone and append each row to the root table
      for (final row in innerRows) {
        final clonedRow = row.clone(true);
        tbody.append(clonedRow);
      }

      // Remove the container row that held the nested table
      if (containerRow != null) {
        containerRow.remove();
      } else {
        // If we can't find the container row, just remove the nested table
        innerTable.remove();
      }
    }

    // Clean up any empty tables or rows that might be left
    final emptyTables = document.querySelectorAll('table');
    for (final table in emptyTables) {
      final rows = table.querySelectorAll('tr');
      if (rows.isEmpty) {
        table.remove();
      }
    }

    // Clean up empty tbody elements
    final emptyTbodies = document.querySelectorAll('tbody');
    for (final tbody in emptyTbodies) {
      if (tbody.children.isEmpty) {
        tbody.remove();
      }
    }
  }

  /// **[IMPROVED]** Process math elements with alttext attributes using robust, ordered patterns.
  /// This version can handle composite alttext like "40 percent sign".
  static void _processMathElements(dom.Document document) {
    final mathElements = document.querySelectorAll('math[alttext]');

    for (final mathElement in mathElements) {
      final alttext = mathElement.attributes['alttext']?.trim() ?? '';
      if (alttext.isEmpty) continue;

      String? replacement;

      // Rule 1: Handle currency (e.g., "dollar sign 52.50" -> "$52.50")
      // Uses a regular expression for robustness.
      // FIX: The original regex did not account for commas in numbers (e.g., 36,100.00).
      // The updated regex allows for digits, commas, and periods in the number part.
      final currencyMatch =
          RegExp(r'^dollar sign ([\d,.]+)$').firstMatch(alttext);
      if (currencyMatch != null) {
        replacement = '\$${currencyMatch.group(1)}';
      }

      // Rule 2: Handle a number followed by a known symbol (e.g., "40 percent sign" -> "40%")
      else {
        final parts = alttext.split(' ');
        if (parts.length > 1) {
          final numberPart = parts.first;
          final symbolPart = parts.skip(1).join(' '); // Re-join the rest
          if (num.tryParse(numberPart) != null &&
              _simpleReplacements.containsKey(symbolPart)) {
            replacement = '$numberPart${_simpleReplacements[symbolPart]!}';
          }
        }
      }

      // Rule 3: Handle a simple, standalone number (e.g., "115" -> "115")
      if (replacement == null && num.tryParse(alttext) != null) {
        replacement = alttext;
      }

      // Rule 4: Handle a simple, standalone symbol (e.g., "percent sign" -> "%")
      else if (replacement == null &&
          _simpleReplacements.containsKey(alttext)) {
        replacement = _simpleReplacements[alttext]!;
      }

      // If any rule produced a replacement, replace the entire math element.
      if (replacement != null) {
        final textNode = dom.Text(replacement);
        mathElement.replaceWith(textNode);
      }
      // If no rules match, the original <math> element is preserved.
    }
  }

  /// Fixes specific MathML rendering issues that cause units to not display
  static void _fixMathMLRendering(dom.Document document) {
    // Fix 1: Replace <mtext> with <mi> for better Flutter HTML compatibility
    final mtextElements = document.querySelectorAll('mtext');
    for (final mtextElement in mtextElements) {
      final miElement = dom.Element.tag('mi');
      miElement.attributes['mathvariant'] = 'normal';
      miElement.text = mtextElement.text;
      mtextElement.replaceWith(miElement);
    }

    // Fix 2: Handle non-breaking spaces within MathML
    final mathElements = document.querySelectorAll('math');
    for (final mathElement in mathElements) {
      _replaceNonBreakingSpaces(mathElement);
    }

    // Fix 3: Add explicit spacing around operators when missing
    for (final mathElement in mathElements) {
      final moElements = mathElement.querySelectorAll('mo');
      for (final moElement in moElements) {
        // This is a simple fix; can be expanded for other operators like +, - etc.
        if (moElement.text.trim() == '=') {
          moElement.text = ' = ';
        }
      }
    }

    // Fix 4: Ensure proper structure for fenced expressions
    final mfencedElements = document.querySelectorAll('mfenced');
    for (final mfencedElement in mfencedElements) {
      if (mfencedElement.children.length > 1 &&
          mfencedElement.querySelector('mrow') == null) {
        // If there are multiple children and they aren't in an <mrow>, wrap them.
        final mrowElement = dom.Element.tag('mrow');
        final children = List<dom.Node>.from(mfencedElement.nodes);
        for (final child in children) {
          child.remove();
          mrowElement.append(child);
        }
        mfencedElement.append(mrowElement);
      }
    }
  }

  /// Recursively replace non-breaking spaces in an element and its children
  static void _replaceNonBreakingSpaces(dom.Element element) {
    for (final node in element.nodes.toList()) {
      if (node is dom.Text) {
        node.text = node.text
            .replaceAll('\u00A0', '\\text{ }'); // Replace   with regular space
      } else if (node is dom.Element) {
        _replaceNonBreakingSpaces(node);
      }
    }
  }

  /// **[IMPROVED]** Fixes trigonometric function MathML structure to prevent LaTeX parsing errors.
  /// This version safely wraps arguments and avoids breaking already correct structures.
  static void _fixTrigonometricFunctions(dom.Document document) {
    const trigFunctions = {
      'sin',
      'cos',
      'tan',
      'cot',
      'sec',
      'csc',
      'sinh',
      'cosh',
      'tanh',
      'log',
      'ln',
      'exp'
    };

    final miElements = document.querySelectorAll('mi');

    for (final miElement in miElements) {
      final functionName = miElement.text.trim().toLowerCase();
      if (!trigFunctions.contains(functionName)) continue;

      final nextElement = _findNextSiblingElement(miElement);

      // If there's no next element or if it's already parentheses, skip.
      // This prevents breaking correct structures like "sin(x)".
      if (nextElement == null || nextElement.localName == 'mfenced') {
        continue;
      }

      // If the argument is an identifier, number, or a simple row, it needs wrapping.
      if (['mi', 'mn', 'mrow'].contains(nextElement.localName)) {
        // Create the new <mfenced> element to act as parentheses.
        final mfencedElement = dom.Element.tag('mfenced');

        // Detach the argument from its original position.
        final argument = nextElement.remove();

        // Place the detached argument inside the new parentheses.
        mfencedElement.append(argument);

        // Insert the new <mfenced>(argument)</mfenced> structure right after the function name.
        miElement.parent?.nodes.insert(
          miElement.parent!.nodes.indexOf(miElement) + 1,
          mfencedElement,
        );
      }
    }
  }

  // Fixes a rendering issue in MathML where spaces are not handled correctly.
  /// This function adds a space before the closing </ math> tag if not already present,
  static void _addSpaceToMathML(dom.Document document) {
    final mathElements = document.querySelectorAll('math');
    for (final mathElement in mathElements) {
      // Step 1: Add <mo>\text{ }</mo> before </math> if not already present
      if (mathElement.nodes.isNotEmpty &&
          !(mathElement.nodes.last is dom.Element &&
              (mathElement.nodes.last as dom.Element).localName == 'mo')) {
        final spaceMo = dom.Element.tag('mo');
        spaceMo.text = '\\text{ }';
        mathElement.append(spaceMo);
      }
      // Step 2: Remove space (text node) immediately after </math>
      final parent = mathElement.parent;
      if (parent != null) {
        final siblings = parent.nodes;
        final index = siblings.indexOf(mathElement);
        if (index + 1 < siblings.length) {
          final nextNode = siblings[index + 1];
          if (nextNode is dom.Text && nextNode.text.startsWith(' ')) {
            // Remove only the leading space(s)
            final trimmed = nextNode.text.replaceFirst(RegExp(r'^ +'), '');
            if (trimmed.isEmpty) {
              nextNode.remove();
            } else {
              nextNode.text = trimmed;
            }
          }
        }
      }
    }
  }

  /// **[IMPROVED]** Finds the very next sibling that is an Element, skipping whitespace Text nodes.
  /// This is simpler and more reliable than the original implementation.
  static dom.Element? _findNextSiblingElement(dom.Element element) {
    final parent = element.parent;
    if (parent == null) return null;
    final siblings = parent.nodes;
    final index = siblings.indexOf(element);
    for (var i = index + 1; i < siblings.length; i++) {
      final currentNode = siblings[i];
      if (currentNode is dom.Element) {
        // Found the next element, return it.
        return currentNode;
      }
      if (currentNode is dom.Text && currentNode.text.trim().isNotEmpty) {
        // Found a non-whitespace text node, which means we shouldn't continue.
        break;
      }
      // Otherwise, continue to next node.
    }
    return null;
  }

  /// NEW: Inverts base64 images by modifying the actual image data.
  static void _styleImages(dom.Document document) {
    final images = document.querySelectorAll('img');

    for (final img in images) {
      // Check if this is a base64 data URI image and invert it
      final src = img.attributes['src'];
      if (src != null && src.startsWith('data:image/')) {
        final invertedSrc = _invertBase64Image(src);
        if (invertedSrc != null) {
          img.attributes['src'] = invertedSrc;
        }
      }
    }
  }

  /// Inverts a base64 encoded image by modifying the actual pixel data using the image package
  static String? _invertBase64Image(String dataUri) {
    try {
      final mimeType = dataUri.split(';')[0].replaceFirst('data:', '');
      final base64Data = dataUri.split(',')[1];
      if (base64Data.isEmpty) return null;
      final imageBytes = base64Decode(base64Data);
      // Use the image package for decoding
      final img.Image? image = img.decodeImage(imageBytes);
      if (image == null) return null;
      img.invert(image);
      // Encode back to the original format
      List<int> encoded;
      if (mimeType.contains('png')) {
        encoded = img.encodePng(image);
      } else if (mimeType.contains('jpeg') || mimeType.contains('jpg')) {
        encoded = img.encodeJpg(image);
      } else {
        // Fallback to PNG
        encoded = img.encodePng(image);
      }
      final invertedBase64 = base64Encode(encoded);
      return 'data:$mimeType;base64,$invertedBase64';
    } catch (e) {
      return null;
    }
  }

  /// Processes all SVG elements in the document and inverts their colors
  static void _styleSvgElements(dom.Document document) {
    final svgs = document.querySelectorAll('svg');

    for (final svg in svgs) {
      try {
        _invertSvgColors(svg);
      } catch (e) {
        print('Error inverting SVG colors: $e');
      }
    }
  }

  // CSS color keywords that should be inverted.
  static const Map<String, String> _colorKeywords = {
    'black': 'white',
    'white': 'black',
    'darkgray': 'lightgray',
    'darkgrey': 'lightgrey',
    'gray': 'lightgray',
    'grey': 'lightgrey',
    'lightgray': 'darkgray',
    'lightgrey': 'darkgrey',
    'dimgray': 'lightgray',
    'dimgrey': 'lightgrey',
    'darkslategray': 'lightsteelblue',
    'darkslategrey': 'lightsteelblue',
    'slategray': 'lightblue',
    'slategrey': 'lightblue',
  };

  // SVG properties that can contain color values.
  static const Set<String> _colorProperties = {
    'fill',
    'stroke',
    'stop-color',
    'flood-color',
    'lighting-color',
  };

  // CSS properties (often found in style blocks) that can contain color values.
  static const Set<String> _cssColorProperties = {
    ..._colorProperties, // Includes all SVG properties
    'color', 'background-color', 'border-color', 'border-top-color',
    'border-right-color', 'border-bottom-color', 'border-left-color'
  };

  /// **[NEW]** A set of SVG element tag names that are rendered and can be filled.
  /// Used to identify elements that might have a default black fill.
  static const Set<String> _paintableElements = {
    'path',
    'rect',
    'circle',
    'ellipse',
    'polygon',
    'polyline',
    'text',
    'line',
    'tspan'
  };

  /// Main entry point: invert colors in a single SVG element.
  static void _invertSvgColors(dom.Element svg) {
    // Invert colors in the main <svg> element itself and all its descendants.
    _invertDescendantColors(svg);

    // Handle and invert colors within any existing <style> elements.
    _invertStyleTagColors(svg);
  }

  /// Invert colors in an element and all its descendants.
  static void _invertDescendantColors(dom.Element parentElement) {
    // Process the parent element itself first.
    _invertElementColors(parentElement);

    // Process all descendants.
    final allElements = parentElement.querySelectorAll('*');
    for (final element in allElements) {
      _invertElementColors(element);
    }
  }

  /// Invert colors in a single element's attributes and inline styles,
  /// and handle the default black fill case.
  static void _invertElementColors(dom.Element element) {
    // Handle explicit color attributes (e.g., fill="black", stroke="#FF0000").
    for (final property in _colorProperties) {
      if (element.attributes.containsKey(property)) {
        final originalColor = element.attributes[property]!;
        element.attributes[property] = _invertColor(originalColor);
      }
    }

    // Handle inline style attribute (e.g., style="fill: black; stroke: red;").
    final style = element.attributes['style'];
    if (style != null && style.isNotEmpty) {
      element.attributes['style'] = _invertInlineStyle(style);
    }

    // --- LOGIC FOR DEFAULT BLACK FILL ---
    // If an element is paintable but has no fill defined either by an attribute
    // or an inline style, it defaults to black. We must make it explicitly white.
    final tagName = element.localName?.toLowerCase();
    if (tagName != null && _paintableElements.contains(tagName)) {
      final hasFillAttribute = element.attributes.containsKey('fill');
      final hasFillInStyle =
          element.attributes['style']?.contains('fill:') ?? false;

      // If no fill is specified anywhere, it's implicitly black. Invert it to white.
      if (!hasFillAttribute && !hasFillInStyle) {
        element.attributes['fill'] = 'white';
      }
    }
  }

  /// Invert colors within any existing <style> tag's CSS rules.
  static void _invertStyleTagColors(dom.Element svg) {
    final styleElements = svg.querySelectorAll('style');
    for (final styleElement in styleElements) {
      final cssText = styleElement.text;
      if (cssText.isNotEmpty) {
        styleElement.text = _invertCssText(cssText);
      }
    }
  }

  /// Invert colors in an inline style attribute string using a robust regex.
  static String _invertInlineStyle(String style) {
    final propertyRegex = _colorProperties.join('|');
    final ruleRegex = RegExp(
      r'\b(' + propertyRegex + r')\s*:\s*([^;]+)',
      caseSensitive: false,
    );

    return style.replaceAllMapped(ruleRegex, (match) {
      final property = match.group(1)!;
      final value = match.group(2)!.trim();
      final invertedColor = _invertColor(value);
      return '$property: $invertedColor';
    });
  }

  /// Invert colors in a string of CSS text (from a <style> tag).
  static String _invertCssText(String cssText) {
    final propertyRegex = _cssColorProperties.join('|');
    final ruleRegex = RegExp(
      r'\b(' + propertyRegex + r')\s*:\s*([^;}]+)',
      caseSensitive: false,
    );

    return cssText.replaceAllMapped(ruleRegex, (match) {
      final property = match.group(1)!;
      final value = match.group(2)!.trim();
      final invertedColor = _invertColor(value);
      return '$property: $invertedColor';
    });
  }

  /// Core color inversion logic with comprehensive format support.
  static String _invertColor(String color) {
    final normalizedColor = color.trim().toLowerCase();

    // Handle special values that should not be inverted.
    if (normalizedColor == 'none' ||
        normalizedColor == 'transparent' ||
        normalizedColor == 'inherit' ||
        normalizedColor == 'currentcolor') {
      return color;
    }

    // Handle CSS color keywords.
    if (_colorKeywords.containsKey(normalizedColor)) {
      return _colorKeywords[normalizedColor]!;
    }

    // Handle hex colors (#RGB, #RRGGBB).
    final hexResult = _invertHexColor(normalizedColor);
    if (hexResult != null) return hexResult;

    // Handle rgb/rgba colors.
    final rgbResult = _invertRgbColor(normalizedColor);
    if (rgbResult != null) return rgbResult;

    // Handle hsl/hsla colors.
    final hslResult = _invertHslColor(normalizedColor);
    if (hslResult != null) return hslResult;

    // If the format is unknown, return the original color.
    return color;
  }

  /// Invert a hex color string.
  static String? _invertHexColor(String color) {
    final hexMatch = RegExp(r'^#([0-9a-f]{3}|[0-9a-f]{6})$').firstMatch(color);
    if (hexMatch == null) return null;

    String hex = hexMatch.group(1)!;

    if (hex.length == 3) {
      hex = '${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}';
    }

    final r = 255 - int.parse(hex.substring(0, 2), radix: 16);
    final g = 255 - int.parse(hex.substring(2, 4), radix: 16);
    final b = 255 - int.parse(hex.substring(4, 6), radix: 16);

    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
  }

  /// Invert an RGB/RGBA color string.
  static String? _invertRgbColor(String color) {
    final rgbMatch = RegExp(
            r'rgba?\(\s*(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)\s*(?:,\s*(\d+(?:\.\d+)?))?\s*\)')
        .firstMatch(color);
    if (rgbMatch == null) return null;

    final r = 255 - (double.parse(rgbMatch.group(1)!)).round();
    final g = 255 - (double.parse(rgbMatch.group(2)!)).round();
    final b = 255 - (double.parse(rgbMatch.group(3)!)).round();
    final alpha = rgbMatch.group(4);

    if (alpha != null) {
      return 'rgba($r, $g, $b, $alpha)';
    } else {
      return 'rgb($r, $g, $b)';
    }
  }

  /// Invert an HSL/HSLA color string by rotating hue and inverting lightness.
  static String? _invertHslColor(String color) {
    final hslMatch = RegExp(
            r'hsla?\(\s*(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)%\s*,\s*(\d+(?:\.\d+)?)%\s*(?:,\s*(\d+(?:\.\d+)?))?\s*\)')
        .firstMatch(color);
    if (hslMatch == null) return null;

    final h = (double.parse(hslMatch.group(1)!) + 180) % 360;
    final s = hslMatch.group(2)!;
    final l = 100 - double.parse(hslMatch.group(3)!);
    final alpha = hslMatch.group(4);

    if (alpha != null) {
      return 'hsla(${h.round()}, $s%, ${l.round()}%, $alpha)';
    } else {
      return 'hsl(${h.round()}, $s%, ${l.round()}%)';
    }
  }

  /// Remove elements meant only for screen readers
  static void _removeScreenReaderElements(dom.Document document) {
    // A more robust selector to find all elements with the sr-only class.
    final srOnlyElements = document.querySelectorAll('[class*="sr-only"]');
    for (final element in srOnlyElements) {
      element.remove();
    }
  }
}
