import 'dart:core';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

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
  static String process(String html) {
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

    // --- Step 4: Clean up problematic layout elements ---
    _cleanupLayoutElements(document);

    // --- Step 5: Remove screen reader only elements ---
    _removeScreenReaderElements(document);

    // --- Step 6: Style images for better visibility in dark mode ---
    _styleImages(document);

    // --- Step 7 (NEW): Add a background to SVGs for visibility in dark mode ---
    _styleSvgElements(document);

    // Return the processed HTML
    return document.body?.innerHtml ?? document.outerHtml;
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

  /// Clean up problematic layout tags and styles
  static void _cleanupLayoutElements(dom.Document document) {
    // Remove inline style attributes from all elements except SVG, its children, and now IMG tags.
    final elementsWithStyle = document.querySelectorAll('[style]');
    for (final element in elementsWithStyle) {
      // Check if the element is an <img> tag first
      if (element.localName == 'img') {
        continue; // MODIFIED: Skip <img> tags, leaving their style attribute intact.
      }

      // Manually check if the element is inside an <svg>.
      bool isInsideSvg = false;
      dom.Element? current = element;
      while (current != null && current.parent != null) {
        if (current.parent is dom.Element &&
            (current.parent as dom.Element).localName == 'svg') {
          isInsideSvg = true;
          break;
        }
        current = current.parent;
      }
      if (!isInsideSvg) {
        element.attributes.remove('style');
      }
    }
  }

  /// NEW: Adds a white background to all <img> tags to ensure they are visible in dark mode.
  static void _styleImages(dom.Document document) {
    final images = document.querySelectorAll('img');
    for (final img in images) {
      // Add a style that gives a white background, some padding, and rounded corners.
      // This makes images with black text readable on any background.
      img.attributes['style'] =
          'background-color: white; padding: 4px; border-radius: 4px; vertical-align: middle;';
    }
  }

  /// NEW: Wraps all < svg> tags in a styled <span> to give them a white background.
  static void _styleSvgElements(dom.Document document) {
    final svgs = document.querySelectorAll('svg');

    for (final svg in svgs) {
      // Create a wrapper element. A span with inline-block is perfect for this.
      final wrapper = dom.Element.tag('span');

      // Apply the same style as we do for images for consistency.
      wrapper.attributes['style'] =
          'background-color: white; padding: 4px; border-radius: 4px; display: inline-block; vertical-align: middle; line-height: 0;';

      // Replace the svg in the document with our new wrapper
      svg.replaceWith(wrapper);

      // And then append the original svg inside the wrapper
      wrapper.append(svg);
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
