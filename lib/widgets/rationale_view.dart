import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_math/flutter_html_math.dart';
import 'package:flutter_html_svg/flutter_html_svg.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/html_styles.dart';
import '../utils/html_processor.dart';

class RationaleView extends StatelessWidget {
  final String rationale;
  const RationaleView({super.key, required this.rationale});

  @override
  Widget build(BuildContext context) {
    // Get the current theme and color scheme for easy access
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      // The parent container still defines the absolute maximum height.
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        // Use a theme-aware color like 'surface' for the background
        color: colorScheme.surface,
        // Use a theme-aware color for the border that works in both modes
        border: Border(
            top: BorderSide(color: colorScheme.outline.withOpacity(0.5))),
      ),
      // This Column will shrink-wrap its content because of MainAxisSize.min.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Keep this!
        children: [
          Text(
            "Rationale",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              // This was already correct, as it uses the theme's primary color
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          // Wrap the scroll view in Flexible, NOT Expanded.
          Flexible(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Html(
                data: HtmlProcessor.process(
                  rationale,
                  darkMode: Theme.of(context).brightness == Brightness.dark,
                ),
                extensions: const [
                  MathHtmlExtension(),
                  SvgHtmlExtension(),
                  TableHtmlExtension(),
                ],
                style: HtmlStyles.get(context), // Use the centralized styles
              ),
            ),
          ),
        ],
      ),
    );
  }
}
