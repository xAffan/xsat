import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/filter_provider.dart';
import '../widgets/filter_chip_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Colors are now inherited from the theme, no hardcoding needed
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, child) {
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
                  selected: {provider.themePreference},
                  onSelectionChanged: (Set<ThemePreference> newSelection) {
                    provider.updateThemePreference(newSelection.first);
                  },
                ),
              ),
              SwitchListTile(
                title: const Text('OLED Dark Mode'),
                subtitle:
                    const Text('Use a true black background for dark mode'),
                value: provider.isOledMode,
                onChanged: (bool value) {
                  provider.toggleOledMode(value);
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
                  selected: {provider.questionType},
                  onSelectionChanged: (Set<QuestionType> newSelection) {
                    provider.updateQuestionType(newSelection.first);
                  },
                ),
              ),
              SwitchListTile(
                title: const Text('Exclude active questions'),
                subtitle: const Text(
                    'Hide questions that are on the official practice tests.'),
                value: provider.excludeActiveQuestions,
                onChanged: (bool value) {
                  provider.toggleExcludeActiveQuestions(value);
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
                      FilterChipBar(
                        availableFilters: availableCategories,
                        activeFilters: filterProvider.activeFilters,
                        onFilterToggle: (category) {
                          filterProvider.toggleFilter(category);
                        },
                        onClearAll: () {
                          filterProvider.clearFilters();
                        },
                      ),
                      if (filterProvider.hasActiveFilters)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            '${filterProvider.filteredQuestions.length} questions match selected filters',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
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
                value: provider.isCachingEnabled,
                onChanged: (bool value) {
                  provider.toggleCaching(value);
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
                    provider.clearCache();
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
