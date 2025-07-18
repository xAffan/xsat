import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_math/flutter_html_math.dart';
import 'package:flutter_html_svg/flutter_html_svg.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import '../models/mistake.dart';
import '../services/mistake_service.dart';
import '../utils/html_processor.dart';

// Utility class for difficulty-related functions
class DifficultyUtils {
  static String getName(String difficulty) {
    switch (difficulty.toUpperCase()) {
      case 'E':
        return 'Easy';
      case 'M':
        return 'Medium';
      case 'H':
        return 'Hard';
      default:
        return difficulty;
    }
  }

  static Color getColor(String difficulty) {
    switch (difficulty.toUpperCase()) {
      case 'E':
        return Colors.green;
      case 'M':
        return Colors.orange;
      case 'H':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// Utility class for timestamp formatting
class TimestampUtils {
  static String formatRelative(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  static String formatFull(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} at ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

// Utility class for HTML processing
class HtmlUtils {
  static String truncate(String html, int maxLength) {
    // Remove HTML tags for length calculation
    final plainText = html.replaceAll(RegExp(r'<[^>]*>'), '');
    if (plainText.length <= maxLength) return html;
    
    // Find a good truncation point
    final truncated = plainText.substring(0, maxLength);
    return '$truncated...';
  }

  static Widget buildHtml(String content, {required bool darkMode, double fontSize = 16}) {
    return Html(
      data: HtmlProcessor.process(content, darkMode: darkMode),
      style: {
        "body": Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          fontSize: FontSize(fontSize),
        ),
      },
      extensions: const [
        MathHtmlExtension(),
        SvgHtmlExtension(),
        TableHtmlExtension(),
      ],
    );
  }
}

class MistakeHistoryScreen extends StatefulWidget {
  const MistakeHistoryScreen({Key? key}) : super(key: key);

  @override
  State<MistakeHistoryScreen> createState() => _MistakeHistoryScreenState();
}

class _MistakeHistoryScreenState extends State<MistakeHistoryScreen> {
  late MistakeService _mistakeService;
  List<Mistake> _mistakes = [];
  List<Mistake> _filteredMistakes = [];
  bool _loading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mistakeService = MistakeService();
    _init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _mistakeService.init();
    setState(() {
      _mistakes = _mistakeService.getMistakes().reversed.toList();
      _filteredMistakes = _mistakes;
      _loading = false;
    });
  }

  void _filterMistakes(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredMistakes = _mistakes;
      } else {
        _filteredMistakes = _mistakes.where((mistake) {
          final queryLower = query.toLowerCase();
          return mistake.question.toLowerCase().contains(queryLower) ||
                 mistake.category.toLowerCase().contains(queryLower) ||
                 mistake.subject.toLowerCase().contains(queryLower) ||
                 DifficultyUtils.getName(mistake.difficulty).toLowerCase().contains(queryLower);
        }).toList();
      }
    });
  }

  Future<void> _clearMistakes() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Mistakes'),
        content: const Text('Are you sure you want to clear all mistake history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _mistakeService.clearMistakes();
      setState(() {
        _mistakes = [];
        _filteredMistakes = [];
      });
    }
  }

  void _showMistakeDetails(Mistake mistake) {
    showDialog(
      context: context,
      builder: (context) => _MistakeDetailsDialog(mistake: mistake),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mistake History (${_mistakes.length})'),
        elevation: 0,
        actions: [
          if (_mistakes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearMistakes,
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _mistakes.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildSearchBar(),
                    Expanded(child: _buildMistakesList()),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.green[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No mistakes yet!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Keep practicing to improve your knowledge',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: _filterMistakes,
        decoration: InputDecoration(
          hintText: 'Search mistakes by question, category, subject, or difficulty...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterMistakes('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
        ),
      ),
    );
  }

  Widget _buildMistakesList() {
    if (_filteredMistakes.isEmpty && _searchQuery.isNotEmpty) {
      return _buildNoResultsState();
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredMistakes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final mistake = _filteredMistakes[index];
        return _CompactMistakeCard(
          mistake: mistake,
          onTap: () => _showMistakeDetails(mistake),
        );
      },
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).hintColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No mistakes found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactMistakeCard extends StatelessWidget {
  final Mistake mistake;
  final VoidCallback onTap;

  const _CompactMistakeCard({
    required this.mistake,
    required this.onTap,
  });

  // Replace the metadata row in _CompactMistakeCard with this responsive version
Widget _buildMetadataRow(BuildContext context) {
  final theme = Theme.of(context);
  
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Tags section - can wrap and compress
      Expanded(
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _MetaChip(
              label: DifficultyUtils.getName(mistake.difficulty),
              color: DifficultyUtils.getColor(mistake.difficulty),
            ),
            _MetaChip(
              label: mistake.category,
              color: Colors.blue,
            ),
            _MetaChip(
              label: mistake.subject,
              color: Colors.purple,
            ),
          ],
        ),
      ),
      // Timestamp - always on the right
      const SizedBox(width: 12),
      Text(
        TimestampUtils.formatRelative(mistake.timestamp),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.hintColor,
        ),
      ),
    ],
  );
}

@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  
  return Card(
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question preview (truncated)
            HtmlUtils.buildHtml(
              HtmlUtils.truncate(mistake.question, 100),
              darkMode: isDark,
              fontSize: 15,
            ),
            const SizedBox(height: 12),
            
            // Metadata with wrap for narrow screens
            _buildMetadataRow(context),
            const SizedBox(height: 12),
            
            // Answer summary
            _AnswerSummary(mistake: mistake),
          ],
        ),
      ),
    ),
  );
}

}


// Updated _AnswerSummary to fix arrow positioning while keeping same line layout

// Robust _AnswerSummary with proper layout constraints
class _AnswerSummary extends StatelessWidget {
  final Mistake mistake;

  const _AnswerSummary({required this.mistake});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        // Left side - expandable content area
        Expanded(
          child: Row(
            children: [
              const Icon(Icons.cancel, color: Colors.red, size: 16),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Your answer: ${mistake.answerOptions.isEmpty ? mistake.userAnswer : mistake.userAnswerLabel}',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Correct: ${mistake.answerOptions.isEmpty ? mistake.correctAnswer : mistake.correctAnswerLabel}',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.green),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // Right side - always fixed arrow
        const SizedBox(width: 8),
        Icon(Icons.arrow_forward_ios, size: 16, color: theme.hintColor),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MetaChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _MistakeDetailsDialog extends StatelessWidget {
  final Mistake mistake;

  const _MistakeDetailsDialog({required this.mistake});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question
                    _SectionHeader(title: 'Question', icon: Icons.help_outline),
                    const SizedBox(height: 8),
                    HtmlUtils.buildHtml(mistake.question, darkMode: isDark),
                    const SizedBox(height: 20),
                    
                    // Metadata
                    _SectionHeader(title: 'Details', icon: Icons.info_outline),
                    const SizedBox(height: 8),
                    _MetadataChips(mistake: mistake),
                    const SizedBox(height: 20),
                    
                    // Answers
                    if (mistake.answerOptions.isEmpty) 
                      _SPRAnswers(mistake: mistake, isDark: isDark)
                    else
                      _MultipleChoiceAnswers(mistake: mistake, isDark: isDark),
                    
                    // Explanation
                    if (mistake.rationale.isNotEmpty) ...[
                      _SectionHeader(title: 'Explanation', icon: Icons.lightbulb_outline),
                      const SizedBox(height: 8),
                      _ExplanationContainer(mistake: mistake, isDark: isDark),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(Icons.quiz, color: theme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Question Details',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _MetadataChips extends StatelessWidget {
  final Mistake mistake;

  const _MetadataChips({required this.mistake});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _DetailChip(
          label: 'Difficulty',
          value: DifficultyUtils.getName(mistake.difficulty),
          color: DifficultyUtils.getColor(mistake.difficulty),
        ),
        _DetailChip(
          label: 'Category',
          value: mistake.category,
          color: Colors.blue,
        ),
        _DetailChip(
          label: 'Subject',
          value: mistake.subject,
          color: Colors.purple,
        ),
        _DetailChip(
          label: 'Answered',
          value: TimestampUtils.formatFull(mistake.timestamp),
          color: Colors.grey,
        ),
      ],
    );
  }
}

class _SPRAnswers extends StatelessWidget {
  final Mistake mistake;
  final bool isDark;

  const _SPRAnswers({required this.mistake, required this.isDark});

  @override
  Widget build(BuildContext context) {    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Answers', icon: Icons.short_text),
        const SizedBox(height: 8),
        _AnswerContainer(
          color: Colors.red,
          icon: Icons.cancel,
          text: 'Your answer: ${mistake.userAnswer}',
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _AnswerContainer(
          color: Colors.green,
          icon: Icons.check_circle,
          text: 'Correct answer: ${mistake.correctAnswer}',
          isDark: isDark,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _MultipleChoiceAnswers extends StatelessWidget {
  final Mistake mistake;
  final bool isDark;

  const _MultipleChoiceAnswers({required this.mistake, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Answer Options', icon: Icons.list),
        const SizedBox(height: 8),
        ...mistake.answerOptions.map((option) => _AnswerOption(
          option: option,
          isUserAnswer: option.label == mistake.userAnswerLabel,
          isCorrectAnswer: option.label == mistake.correctAnswerLabel,
          isDark: isDark,
        )),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _AnswerContainer extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  final bool isDark;

  const _AnswerContainer({
    required this.color,
    required this.icon,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.1) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExplanationContainer extends StatelessWidget {
  final Mistake mistake;
  final bool isDark;

  const _ExplanationContainer({required this.mistake, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.blue[900]?.withOpacity(0.1) : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: HtmlUtils.buildHtml(mistake.rationale, darkMode: isDark),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DetailChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  final dynamic option;
  final bool isUserAnswer;
  final bool isCorrectAnswer;
  final bool isDark;

  const _AnswerOption({
    required this.option,
    required this.isUserAnswer,
    required this.isCorrectAnswer,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    IconData? icon;
    
    if (isCorrectAnswer) {
      backgroundColor = isDark ? Colors.green[900]!.withOpacity(0.3) : Colors.green[50]!;
      borderColor = Colors.green;
      icon = Icons.check_circle;
    } else if (isUserAnswer) {
      backgroundColor = isDark ? Colors.red[900]!.withOpacity(0.3) : Colors.red[50]!;
      borderColor = Colors.red;
      icon = Icons.cancel;
    } else {
      backgroundColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;
      borderColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              option.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: HtmlUtils.buildHtml(option.content, darkMode: isDark),
          ),
          if (icon != null) ...[
            const SizedBox(width: 8),
            Icon(icon, color: borderColor, size: 20),
          ],
        ],
      ),
    );
  }
}