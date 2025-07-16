import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/filter_provider.dart';
import '../services/cache_service.dart';

/// A widget that displays the current question count in the settings screen
/// Shows either total count or filtered and total counts based on filter state
/// Can also show current question progress (Question X of Y)
class QuestionCountWidget extends StatelessWidget {
  /// Whether to always show both filtered and total counts
  /// If false, will only show both counts when filters are active
  final bool showBothCounts;

  /// Whether to show question progress format (Question X of Y)
  final bool showProgress;

  /// Optional text style for the count display
  final TextStyle? textStyle;

  /// Optional loading widget to show while question data is being fetched
  final Widget? loadingWidget;

  /// Creates a new QuestionCountWidget
  const QuestionCountWidget({
    Key? key,
    this.showBothCounts = false,
    this.showProgress = false,
    this.textStyle,
    this.loadingWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FilterProvider>(
      builder: (context, filterProvider, _) {
        // Check if we have question data
        final hasQuestionData = filterProvider.totalQuestionCount > 0;

        if (!hasQuestionData) {
          return _buildLoadingState(context);
        }

        return _buildCountDisplay(context, filterProvider);
      },
    );
  }

  /// Builds the loading state widget
  Widget _buildLoadingState(BuildContext context) {
    if (loadingWidget != null) {
      return loadingWidget!;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Loading questions...',
          style: textStyle ?? Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  /// Builds the count display based on filter state
  Widget _buildCountDisplay(
      BuildContext context, FilterProvider filterProvider) {
    final hasActiveFilters = filterProvider.hasActiveFilters;
    final shouldShowBothCounts = showBothCounts || hasActiveFilters;

    String countText;
    if (showProgress) {
      // Show "Question X of Y" format using seen questions logic
      return FutureBuilder<Set<String>>(
        future: _getSeenQuestionIds(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Text(
              'Loading...',
              style: textStyle ?? Theme.of(context).textTheme.bodyMedium,
            );
          }

          final seenIds = snapshot.data ?? <String>{};
          final totalAvailable = filterProvider.filteredQuestionCount > 0
              ? filterProvider.filteredQuestionCount
              : filterProvider.totalQuestionCount;
          final currentQuestionNumber = seenIds.length + 1;

          return Text(
            'Question $currentQuestionNumber of $totalAvailable',
            style: textStyle ??
                Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
          );
        },
      );
    } else if (shouldShowBothCounts) {
      countText =
          '${filterProvider.filteredQuestionCount} of ${filterProvider.totalQuestionCount} questions';
    } else {
      countText = '${filterProvider.totalQuestionCount} questions';
    }

    return Text(
      countText,
      style: textStyle ??
          Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
    );
  }

  /// Gets the set of seen question IDs from cache
  Future<Set<String>> _getSeenQuestionIds() async {
    final cacheService = CacheService();
    final seenIds = await cacheService.getSeenQuestionIds();
    return seenIds.toSet();
  }
}
