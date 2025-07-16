import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

/// A utility class to provide a centralized, theme-aware style map for Html widgets.
class HtmlStyles {
  /// Returns a map of CSS-like styles for HTML tags that adapts to the current theme.
  static Map<String, Style> get(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return {
      "body": Style(
        margin: Margins.zero,
        color: colorScheme.onSurface,
        fontSize: FontSize(theme.textTheme.bodyMedium?.fontSize ?? 14),
      ),
      // --- Table Styling ---
      "th": Style(
        padding: HtmlPaddings.all(8),
        backgroundColor: colorScheme.primaryContainer.withOpacity(0.5),
        color: colorScheme.onPrimaryContainer,
        fontWeight: FontWeight.bold,
        border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
      ),
      "td": Style(
        padding: HtmlPaddings.all(8),
        border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
        verticalAlign: VerticalAlign.top,
      ),
    };
  }
}
