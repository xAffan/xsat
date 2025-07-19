import 'package:flutter/material.dart';

/// Widget to display when no questions match the selected filters
/// Provides clear messaging and options to resolve the no results state
class NoResultsWidget extends StatelessWidget {
  /// Callback to clear all active filters
  final VoidCallback? onClearFilters;

  /// Whether filters are currently active
  final bool hasActiveFilters;

  /// Custom message to display (optional)
  final String? customMessage;

  /// Whether to show the clear filters button
  final bool showClearFilters;



  const NoResultsWidget({

    super.key,

    this.onClearFilters,

    this.hasActiveFilters = false,

    this.customMessage,

    this.showClearFilters = true,

  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.filter_list_off,
                size: 64,
                color: colorScheme.error,
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              'No Questions Found',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Message
            Text(
              customMessage ?? _getDefaultMessage(),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Action buttons
            Column(
              children: [
                // Clear filters button (only show if filters are active and enabled)
                if (hasActiveFilters &&
                    showClearFilters &&
                    onClearFilters != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onClearFilters,
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Clear All Filters'),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 12.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),

            // Additional help text
            if (hasActiveFilters) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Try removing some filters to see more questions.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getDefaultMessage() {
    if (hasActiveFilters) {
      return 'No questions match the selected filters. Try adjusting your filter selection or clearing all filters to see more questions.';
    } else {
      return 'No questions are currently available. Please check your connection.';
    }
  }
}
