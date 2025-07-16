import 'package:flutter/material.dart';
import '../models/question_metadata.dart';

/// Modal widget for displaying detailed question metadata information
class QuestionInfoModal extends StatelessWidget {
  final QuestionMetadata? metadata;

  const QuestionInfoModal({
    Key? key,
    required this.metadata,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 500,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Question Information',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content
            if (metadata != null) ...[
              _buildInfoSection(
                context,
                'Skill',
                metadata!.skillDescription,
                Icons.psychology,
              ),
              const SizedBox(height: 16),
              _buildInfoSection(
                context,
                'Category',
                metadata!.primaryClassDescription,
                Icons.category,
              ),
              const SizedBox(height: 16),
              _buildInfoSection(
                context,
                'Difficulty',
                _formatDifficulty(metadata!.difficulty),
                Icons.trending_up,
              ),
            ] else ...[
              _buildNoMetadataMessage(context),
            ],

            const SizedBox(height: 24),

            // Close button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds an information section with icon, label, and value
  Widget _buildInfoSection(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a message when metadata is not available
  Widget _buildNoMetadataMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Question information is not available for this question.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  /// Formats difficulty code to user-friendly text
  String _formatDifficulty(String difficulty) {
    switch (difficulty.toUpperCase()) {
      case 'E':
        return 'Easy';
      case 'M':
        return 'Medium';
      case 'H':
        return 'Hard';
      default:
        return difficulty.isNotEmpty ? difficulty : 'Unknown';
    }
  }

  /// Static method to show the modal
  static Future<void> show(
    BuildContext context,
    QuestionMetadata? metadata,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // Allow dismissal by tapping outside
      builder: (BuildContext context) {
        return QuestionInfoModal(metadata: metadata);
      },
    );
  }
}
