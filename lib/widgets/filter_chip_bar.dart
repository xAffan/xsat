import 'package:flutter/material.dart';

/// A horizontal scrollable bar of filter chips for category selection
/// Provides visual indication for active vs inactive states and handles filter toggling
class FilterChipBar extends StatelessWidget {
  /// List of available filter categories to display
  final List<String> availableFilters;

  /// Set of currently active filter categories
  final Set<String> activeFilters;

  /// Callback function when a filter is toggled
  final Function(String) onFilterToggle;

  /// Optional callback when all filters are cleared
  final VoidCallback? onClearAll;

  /// Whether to show a clear all button when filters are active
  final bool showClearAll;

  /// Height of the filter chip bar
  final double height;

  const FilterChipBar({
    super.key,
    required this.availableFilters,
    required this.activeFilters,
    required this.onFilterToggle,
    this.onClearAll,
    this.showClearAll = true,
    this.height = 60.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // If no filters are available, show empty state
    if (availableFilters.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'No filter categories available',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clear all button (if enabled and filters are active)
          if (showClearAll && activeFilters.isNotEmpty && onClearAll != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildClearAllButton(context),
            ),

          // Wrapping filter chips
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: availableFilters.map((filter) {
              final isActive = activeFilters.contains(filter);
              return _buildFilterChip(context, filter, isActive);
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Builds an individual filter chip
  Widget _buildFilterChip(BuildContext context, String filter, bool isActive) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FilterChip(
      label: Text(
        filter,
        style: TextStyle(
          color: isActive ? colorScheme.onPrimary : colorScheme.onSurface,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          fontSize: 13.0,
        ),
      ),
      selected: isActive,
      onSelected: (_) => onFilterToggle(filter),
      backgroundColor: colorScheme.surface,
      selectedColor: colorScheme.primary,
      checkmarkColor: colorScheme.onPrimary,
      side: BorderSide(
        color: isActive
            ? colorScheme.primary
            : colorScheme.outline.withValues(alpha: 0.5),
        width: isActive ? 2.0 : 1.0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      elevation: isActive ? 2.0 : 0.0,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
    );
  }

  /// Builds the clear all button
  Widget _buildClearAllButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(20.0),
      child: InkWell(
        onTap: onClearAll,
        borderRadius: BorderRadius.circular(20.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.clear_all,
                size: 16.0,
                color: colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 4.0),
              Text(
                'Clear All',
                style: TextStyle(
                  color: colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w500,
                  fontSize: 13.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
