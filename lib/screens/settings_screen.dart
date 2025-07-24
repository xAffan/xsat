import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/filter_provider.dart';
import '../providers/quiz_provider.dart';
import '../widgets/filter_chip_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// Helper to map difficulty codes to human-readable labels
  String _getDifficultyLabel(String code) {
    switch (code) {
      case 'E':
        return 'Easy';
      case 'M':
        return 'Medium';
      case 'H':
        return 'Hard';
      default:
        return code;
    }
  }

  /// Helper to get difficulty color
  Color _getDifficultyColor(String code) {
    switch (code) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Colors are now inherited from the theme, no hardcoding needed
        title: const Text('Settings'),
      ),
      body: Consumer3<SettingsProvider, FilterProvider, QuizProvider>(
        builder:
            (context, settingsProvider, filterProvider, quizProvider, child) {
          return ListView(
            children: [
              _SettingsHeader('Appearance'),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: SegmentedButton<ThemePreference>(
                  segments: const <ButtonSegment<ThemePreference>>[
                    ButtonSegment<ThemePreference>(
                        value: ThemePreference.system,
                        label: Text('System'),
                        icon: Icon(Icons.brightness_auto)),
                    ButtonSegment<ThemePreference>(
                        value: ThemePreference.light,
                        label: Text('Light'),
                        icon: Icon(Icons.wb_sunny)),
                    ButtonSegment<ThemePreference>(
                        value: ThemePreference.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.brightness_2)),
                  ],
                  selected: {settingsProvider.themePreference},
                  onSelectionChanged: (Set<ThemePreference> newSelection) {
                    settingsProvider.updateThemePreference(newSelection.first);
                  },
                ),
              ),
              SwitchListTile(
                title: const Text('OLED Dark Mode'),
                subtitle:
                    const Text('Use a true black background for dark mode'),
                value: settingsProvider.isOledMode,
                onChanged: (bool value) {
                  settingsProvider.toggleOledMode(value);
                },
              ),
              const Divider(),
              _SettingsHeader('Quiz Content'),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: SegmentedButton<QuestionType>(
                  segments: const <ButtonSegment<QuestionType>>[
                    ButtonSegment<QuestionType>(
                        value: QuestionType.english,
                        label: Text('English'),
                        icon: Icon(Icons.text_fields)),
                    ButtonSegment<QuestionType>(
                        value: QuestionType.math,
                        label: Text('Math'),
                        icon: Icon(Icons.calculate)),
                    ButtonSegment<QuestionType>(
                        value: QuestionType.both,
                        label: Text('Both'),
                        icon: Icon(Icons.functions)),
                  ],
                  selected: {settingsProvider.questionType},
                  onSelectionChanged: (Set<QuestionType> newSelection) {
                    settingsProvider.updateQuestionType(newSelection.first);
                    // Also update the filter provider instantly
                    filterProvider.updateQuestionType(newSelection.first);
                    // Update quiz pool with new filters
                    quizProvider.updateQuestionPool(filterProvider);
                  },
                ),
              ),
              SwitchListTile(
                title: const Text('Exclude active questions'),
                subtitle: const Text(
                    'Hide questions that are on the official practice tests.'),
                value: settingsProvider.excludeActiveQuestions,
                onChanged: (bool value) {
                  settingsProvider.toggleExcludeActiveQuestions(value);
                  // Also update the filter provider instantly
                  filterProvider.updateExcludeActiveQuestions(value);
                  // Update quiz pool with new filters
                  quizProvider.updateQuestionPool(filterProvider);
                },
              ),
              const Divider(),
              _SettingsHeader('Question Filters'),
              Consumer<FilterProvider>(
                builder: (context, filterProvider, child) {
                  final availableCategories =
                      filterProvider.getAvailableFilterCategories();

                  if (availableCategories.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No filter categories available. Load some questions first.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  // Filter categories based on selected question type
                  final questionType = settingsProvider.questionType;

                  Widget buildFilterSection(
                      String title, List<String> categories,
                      {bool isLast = false}) {
                    if (categories.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FilterChipBar(
                          availableFilters: categories,
                          activeFilters: filterProvider.activeFilters,
                          showClearAll: false,
                          onFilterToggle: (category) {
                            filterProvider.toggleFilter(category);
                            quizProvider.updateQuestionPool(filterProvider);
                          },
                          /*
                          onClearAll: () {
                            filterProvider.clearFilters();
                            quizProvider.updateQuestionPool(filterProvider);
                          },
                          */
                        ),
                        // Add visual separator between sections when both subjects are shown
                        if (questionType == QuestionType.both && !isLast)
                          Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 0.0), // Reduced from 16.0 to 0.0
                            height: 1,
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.2),
                          ),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Text(
                          'Filter questions by category. Multiple filters use OR logic.',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ),

                      // Show filters based on question type selection
                      if (questionType == QuestionType.english ||
                          questionType == QuestionType.both)
                        buildFilterSection(
                          'English Categories',
                          filterProvider.getAvailableFilterCategoriesForSubject(
                              'English'),
                        ),

                      if (questionType == QuestionType.math ||
                          questionType == QuestionType.both)
                        buildFilterSection(
                          'Math Categories',
                          filterProvider
                              .getAvailableFilterCategoriesForSubject('Math'),
                          isLast: true,
                        ),

                      // Difficulty filters section
                      const SizedBox(height: 16),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Filter by Difficulty',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 4.0),
                        child: Text(
                          'Select difficulty levels to include in your quiz.',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: filterProvider
                              .getAvailableDifficultyLevels()
                              .map((difficulty) {
                            final isActive = filterProvider
                                .isDifficultyFilterActive(difficulty);
                            final counts =
                                filterProvider.getDifficultyQuestionCounts();
                            final count = counts[difficulty] ?? 0;

                            return FilterChip(
                              label: Text(
                                '${_getDifficultyLabel(difficulty)} ($count)',
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.white
                                      : _getDifficultyColor(difficulty),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              selected: isActive,
                              onSelected: (selected) {
                                filterProvider
                                    .toggleDifficultyFilter(difficulty);
                                quizProvider.updateQuestionPool(filterProvider);
                              },
                              selectedColor: _getDifficultyColor(difficulty),
                              checkmarkColor: Colors.white,
                              side: BorderSide(
                                color: _getDifficultyColor(difficulty),
                                width: 1.5,
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: filterProvider.hasActiveFilters
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 250),
                                    transitionBuilder: (Widget child,
                                        Animation<double> animation) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0, -0.2),
                                            end: Offset.zero,
                                          ).animate(CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOut,
                                          )),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      key: ValueKey(filterProvider
                                          .filteredQuestions.length),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0),
                                      child: Text(
                                        '${filterProvider.filteredQuestions.length} questions match selected filters',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 250),
                                    transitionBuilder: (Widget child,
                                        Animation<double> animation) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0, 0.2),
                                            end: Offset.zero,
                                          ).animate(CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOut,
                                          )),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      key: const ValueKey('clear_button'),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0),
                                      child: TextButton.icon(
                                        onPressed: () {
                                          filterProvider.clearFilters();
                                          quizProvider.updateQuestionPool(
                                              filterProvider);
                                        },
                                        icon: const Icon(Icons.clear_all),
                                        label: const Text('Clear All Filters'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Theme.of(context)
                                              .colorScheme
                                              .error,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  );
                },
              ),
              const Divider(),
              _SettingsHeader('Data Management'),
              SwitchListTile(
                title: const Text('Cache Answered Questions'),
                subtitle:
                    const Text('Prevent answered questions from reappearing.'),
                value: settingsProvider.isCachingEnabled,
                onChanged: (bool value) {
                  settingsProvider.toggleCaching(value);
                },
              ),
              ListTile(
                title: const Text('Clear Cached Questions'),
                subtitle: const Text('This will reset your quiz progress.'),
                onTap: () async {
                  bool? confirm = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear Cache'),
                      content: const Text(
                          'Are you sure you want to clear cached questions? This will reset your quiz progress.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    settingsProvider.clearCache();
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

// A helper widget for creating styled section headers.
class _SettingsHeader extends StatelessWidget {
  final String title;
  const _SettingsHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
