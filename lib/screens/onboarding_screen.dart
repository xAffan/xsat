import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/themed_button.dart';

/// Onboarding screen shown to first-time users to set up basic preferences
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  QuestionType _selectedQuestionType = QuestionType.english;
  ThemePreference _selectedTheme = ThemePreference.system;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        _buildWelcomeSection(),
                        const SizedBox(height: 40),
                        _buildQuestionTypeSection(),
                        const SizedBox(height: 32),
                        _buildThemeSection(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                _buildContinueButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.quiz,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Welcome to SAT Quiz!',
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Let\'s set up your quiz preferences to get started.',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionTypeSection() {
    return _OnboardingSectionCard(
      title: 'Question Content',
      subtitle: 'What type of questions would you like to practice?',
      child: Column(
        children: QuestionType.values.map((type) {
          String title;
          String subtitle;
          IconData icon;

          switch (type) {
            case QuestionType.english:
              title = 'English';
              subtitle = 'Reading, writing, and language questions';
              icon = Icons.book;
              break;
            case QuestionType.math:
              title = 'Math';
              subtitle = 'Algebra, geometry, and problem-solving';
              icon = Icons.calculate;
              break;
            case QuestionType.both:
              title = 'Both';
              subtitle = 'Mix of English and Math questions';
              icon = Icons.all_inclusive;
              break;
          }

          return _OptionTile(
            title: title,
            subtitle: subtitle,
            icon: icon,
            isSelected: _selectedQuestionType == type,
            onTap: () {
              setState(() {
                _selectedQuestionType = type;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildThemeSection() {
    return _OnboardingSectionCard(
      title: 'Appearance',
      subtitle: 'Choose your preferred theme',
      child: Column(
        children: ThemePreference.values.map((theme) {
          String title;
          String subtitle;
          IconData icon;

          switch (theme) {
            case ThemePreference.system:
              title = 'System';
              subtitle = 'Follow device settings';
              icon = Icons.brightness_auto;
              break;
            case ThemePreference.light:
              title = 'Light';
              subtitle = 'Light theme';
              icon = Icons.wb_sunny;
              break;
            case ThemePreference.dark:
              title = 'Dark';
              subtitle = 'Dark theme';
              icon = Icons.brightness_2;
              break;
          }

          return _OptionTile(
            title: title,
            subtitle: subtitle,
            icon: icon,
            isSelected: _selectedTheme == theme,
            onTap: () {
              setState(() {
                _selectedTheme = theme;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ThemedButton(
        text: 'Start Quiz',
        onPressed: _completeOnboarding,
      ),
    );
  }

  void _completeOnboarding() async {
    final settingsProvider = context.read<SettingsProvider>();

    // Apply the selected settings
    await settingsProvider.updateQuestionType(_selectedQuestionType);
    await settingsProvider.updateThemePreference(_selectedTheme);
    // Audio is always enabled - no need to set it
    await settingsProvider.setOnboardingCompleted(true);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/quiz');
    }
  }
}

class _OnboardingSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _OnboardingSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
