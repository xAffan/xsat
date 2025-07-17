import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_math/flutter_html_math.dart';
import 'package:flutter_html_svg/flutter_html_svg.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import '../utils/html_styles.dart';
import '../providers/quiz_provider.dart';
import '../utils/html_processor.dart';

class AnswerOptionTile extends StatelessWidget {
  final String optionId;
  final String optionContent;
  final QuizState currentState;
  final String? selectedOptionId;
  final String correctOptionId;
  final VoidCallback onSelect;

  const AnswerOptionTile({
    super.key,
    required this.optionId,
    required this.optionContent,
    required this.currentState,
    required this.selectedOptionId,
    required this.correctOptionId,
    required this.onSelect,
  });

  Color _getBorderColor(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    bool isSelected = selectedOptionId == optionId;

    if (currentState != QuizState.answered) {
      // Use primary color for selected, and outline for default
      return isSelected ? colorScheme.primary : colorScheme.outline;
    } else {
      // Use green for correct, error color for wrong, and a faint outline for others
      if (optionId == correctOptionId) return Colors.green.shade600;
      if (isSelected) return colorScheme.error;
      return colorScheme.outline.withOpacity(0.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSelected = selectedOptionId == optionId;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: currentState == QuizState.ready ? onSelect : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 5.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        decoration: BoxDecoration(
          // Use a theme-aware background color like cardColor or surface
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: _getBorderColor(context),
            width: isSelected || currentState == QuizState.answered ? 2.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              // Use the theme's shadowColor for appropriate shadows in light/dark mode
              color: theme.shadowColor.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Html(
          data: HtmlProcessor.process(
            optionContent,
            darkMode: Theme.of(context).brightness == Brightness.dark,
          ),
          extensions: const [
            MathHtmlExtension(),
            SvgHtmlExtension(),
            TableHtmlExtension(),
          ],
          style: HtmlStyles.get(context),
        ),
      ),
    );
  }
}
