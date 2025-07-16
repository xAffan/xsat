import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_math/flutter_html_math.dart';
import 'package:flutter_html_svg/flutter_html_svg.dart';
import 'package:flutter_html_table/flutter_html_table.dart';

import '../utils/html_styles.dart';
import '../providers/quiz_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/filter_provider.dart';
import '../services/share_service.dart';
import '../utils/html_processor.dart';
import '../widgets/answer_option.dart';
import '../widgets/collapsible_rationale_popup.dart';
import '../widgets/themed_button.dart';
import '../widgets/question_info_modal.dart';
import '../widgets/no_results_widget.dart';
import 'settings_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // A GlobalKey to identify the widget we want to capture for sharing.
  final GlobalKey _questionAreaKey = GlobalKey();

  // Create ShareService instance directly instead of using Provider
  late final ShareService _shareService;

  // Popup state management for rationale display
  bool _isRationaleExpanded =
      false; // Controls whether popup content is expanded

  // Store filter provider reference to avoid accessing context in dispose
  FilterProvider? _filterProvider;

  @override
  void initState() {
    super.initState();
    // Initialize ShareService
    _shareService = ShareService();

    // Initialize the quiz after the first frame is built to ensure
    // that the providers are available in the widget tree.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeQuizBasedOnSettings();
      _setupFilterListener();
    });
  }

  /// Set up listener for filter changes
  void _setupFilterListener() {
    _filterProvider = context.read<FilterProvider>();
    _filterProvider!.addListener(_onFiltersChanged);
  }

  /// Handle filter changes by refreshing the question pool
  void _onFiltersChanged() {
    if (!mounted) return;

    final quizProvider = context.read<QuizProvider>();
    final filterProvider = context.read<FilterProvider>();

    // Only refresh if quiz is initialized and not in error state
    if (quizProvider.state != QuizState.uninitialized &&
        quizProvider.state != QuizState.error) {
      quizProvider.refreshQuestionPool(filterProvider);
    }
  }

  @override
  void dispose() {
    // Remove filter listener using stored reference
    _filterProvider?.removeListener(_onFiltersChanged);
    super.dispose();
  }

  /// Safely initializes the quiz by reading the current settings.
  void _initializeQuizBasedOnSettings() {
    final settingsProvider = context.read<SettingsProvider>();
    final filterProvider = context.read<FilterProvider>();

    // Reset popup state when initializing quiz
    _resetPopupState();

    // Initialize filter provider if not already done
    filterProvider.initialize().then((_) {
      if (mounted) {
        context.read<QuizProvider>().initializeQuiz(
              settingsProvider.questionType,
              settingsProvider: settingsProvider,
              filterProvider: filterProvider,
            );
      }
    });
  }

  /// Shows a dialog prompting the user to restart the quiz to apply changes.
  void _showRestartDialog() {
    final settingsProvider = context.read<SettingsProvider>();
    showDialog<void>(
      context: context,
      barrierDismissible: false, // User must make a choice
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Apply Settings'),
          content: const Text(
              'To apply the new content settings, the quiz needs to be restarted.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                // Reset the flag but don't restart
                settingsProvider.appliedChanges();
                Navigator.of(dialogContext).pop();
              },
            ),
            FilledButton(
              child: const Text('Restart Quiz'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Restart the quiz with the new settings
                _initializeQuizBasedOnSettings();
                // Reset the flag
                settingsProvider.appliedChanges();
              },
            ),
          ],
        );
      },
    );
  }

  /// Shows the question information modal
  void _showQuestionInfo() {
    final quizProvider = context.read<QuizProvider>();
    final currentQuestion = quizProvider.currentQuestion;

    if (currentQuestion?.metadata != null) {
      QuestionInfoModal.show(context, currentQuestion!.metadata);
    }
  }

  /// Shows the rationale popup when answer is submitted
  void _showRationalePopup() {
    setState(() {
      _isRationaleExpanded =
          true; // Start expanded by default for inline version
    });
  }

  /// Toggles the expansion state of the rationale popup
  void _toggleRationaleExpansion() {
    setState(() {
      _isRationaleExpanded = !_isRationaleExpanded;
    });
  }

  /// Resets popup state when navigating to next question
  void _resetPopupState() {
    setState(() {
      _isRationaleExpanded = false;
    });
  }

  /// Handles calling the ShareService and showing feedback to the user.
  Future<void> _shareQuestion() async {
    final quizProvider = context.read<QuizProvider>();
    final questionId = quizProvider.currentQuestion?.externalId;

    if (questionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No question available to share.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Preparing question for sharing...'),
          ],
        ),
      ),
    );

    try {
      // Call the service to do all the heavy lifting
      final result = await _shareService.shareWidgetAsPdf(
        widgetKey: _questionAreaKey,
        questionId: questionId,
        context: context,
      );

      // Pop the loading indicator
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      // Show feedback based on the result from the service
      if (!result.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'An unknown error occurred.'),
            backgroundColor: Colors.red[600],
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (result.success && result.message != null && mounted) {
        // Show success message if provided
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message!),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Pop the loading indicator if still showing
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: $e'),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers to react to changes in quiz state or settings.
    final quizProvider = context.watch<QuizProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    // If settings have changed, schedule the dialog to be shown after the build.
    if (settingsProvider.settingsHaveChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Ensure dialog isn't shown if another one is already on screen
        if (ModalRoute.of(context)?.isCurrent == true) {
          _showRestartDialog();
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('SAT Question Bank Quiz', style: GoogleFonts.poppins()),
        backgroundColor: const Color.fromARGB(255, 76, 118, 166),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Question',
            onPressed: () {
              // Call the share method only when a question is ready to be shared
              if (quizProvider.state == QuizState.ready ||
                  quizProvider.state == QuizState.answered) {
                _shareQuestion();
              }
            },
          ),
          // Question info button - only show if question has metadata
          if ((quizProvider.state == QuizState.ready ||
                  quizProvider.state == QuizState.answered) &&
              quizProvider.currentQuestion?.metadata != null)
            IconButton(
              icon: const Icon(Icons.help_outline),
              tooltip: 'Question Information',
              onPressed: () => _showQuestionInfo(),
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: _buildBody(context, quizProvider),
    );
  }

  /// Builds the main body of the screen based on the current QuizState.
  Widget _buildBody(BuildContext context, QuizProvider provider) {
    switch (provider.state) {
      case QuizState.uninitialized:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Initializing Quiz..."),
            ],
          ),
        );
      case QuizState.loading:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Loading Question..."),
            ],
          ),
        );
      case QuizState.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 20),
                Text(
                  provider.errorMessage ?? "An unknown error occurred.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                ThemedButton(
                  text: "Try Again",
                  onPressed: _initializeQuizBasedOnSettings,
                ),
              ],
            ),
          ),
        );
      case QuizState.complete:
        return Consumer<FilterProvider>(
          builder: (context, filterProvider, child) {
            final hasActiveFilters = filterProvider.hasActiveFilters;
            final isNoResults =
                provider.errorMessage?.contains("No questions match") == true;

            // If it's a no results scenario, use the dedicated NoResultsWidget
            if (isNoResults) {
              return NoResultsWidget(
                hasActiveFilters: hasActiveFilters,
                onClearFilters: hasActiveFilters
                    ? () {
                        filterProvider.clearFilters();
                      }
                    : null,
                onRestart: _initializeQuizBasedOnSettings,
                customMessage: provider.errorMessage,
              );
            }

            // Otherwise, show the regular quiz complete screen
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.celebration,
                    size: 80,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Quiz Complete!",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    hasActiveFilters
                        ? "You've answered all questions matching the selected filters."
                        : "You've answered all available questions.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 30),
                  ThemedButton(
                    text: "Restart With New Questions",
                    onPressed: _initializeQuizBasedOnSettings,
                  ),
                ],
              ),
            );
          },
        );
      case QuizState.ready:
      case QuizState.answered:
        return _buildQuizLayout(context, provider);
    }
  }

  /// Builds the responsive layout for displaying the question and answers.
  Widget _buildQuizLayout(BuildContext context, QuizProvider provider) {
    final question = provider.currentQuestion!;
    Widget answerSection;
    if (question.type == 'mcq') {
      // Multiple Choice Question: show answer options as before
      answerSection = Column(
        children: [
          ...question.answerOptions.map((option) => AnswerOptionTile(
                optionId: option.id,
                optionContent: option.content,
                currentState: provider.state,
                selectedOptionId: provider.selectedAnswerId,
                correctOptionId: question.correctKey,
                onSelect: () => provider.selectAnswer(option.id),
              )),
        ],
      );
    } else if (question.type == 'spr') {
      // Short Constructed Response: allow text input
      answerSection = _ShortAnswerInput(
        // Pass the current quiz state and correct answer for evaluation
        quizState: provider.state,
        correctAnswer: question.correctKey,
        initialValue: provider.selectedAnswerId,
        enabled: provider.state == QuizState.ready,
        onChanged: provider.selectAnswer,
      );
    } else {
      // Fallback for unknown types
      answerSection = const Text('Unsupported question type.');
    }

    return RepaintBoundary(
      key: _questionAreaKey,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, viewportConstraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: viewportConstraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Html(
                              data: HtmlProcessor.process(question.stimulus) +
                                  HtmlProcessor.process(question.stem),
                              extensions: const [
                                MathHtmlExtension(),
                                SvgHtmlExtension(),
                                TableHtmlExtension(),
                              ],
                              style: HtmlStyles.get(context),
                            ),
                            const SizedBox(height: 32.0),
                            answerSection,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Inline collapsible rationale section
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) {
                return SizeTransition(
                  sizeFactor: CurvedAnimation(
                      parent: animation, curve: Curves.easeInOut),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: provider.state == QuizState.answered
                  ? CollapsibleRationalePopup(
                      key: const ValueKey('rationale_section'),
                      rationale: question.rationale,
                      isVisible:
                          true, // Always visible when answer is submitted
                      onToggle: _toggleRationaleExpansion,
                      onDismiss: null, // No dismiss for inline version
                      initiallyExpanded: true, // Expanded by default
                    )
                  : const SizedBox.shrink(),
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: provider.state == QuizState.answered
                    ? ThemedButton(
                        key: const ValueKey('next_button'),
                        text: "Next Question",
                        onPressed: () {
                          _resetPopupState();
                          provider.nextQuestion();
                        },
                      )
                    : ThemedButton(
                        key: const ValueKey('submit_button'),
                        text: 'Submit',
                        onPressed: provider.selectedAnswerId != null &&
                                provider.selectedAnswerId
                                    .toString()
                                    .trim()
                                    .isNotEmpty
                            ? () {
                                provider.submitAnswer();
                                _showRationalePopup();
                              }
                            : null,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for short constructed response input (SPR)
class _ShortAnswerInput extends StatefulWidget {
  final String? initialValue;
  final bool enabled;
  final ValueChanged<String> onChanged;
  // Add properties to receive quiz state and correct answer
  final QuizState quizState;
  final String? correctAnswer;

  const _ShortAnswerInput({
    this.initialValue,
    required this.enabled,
    required this.onChanged,
    required this.quizState,
    this.correctAnswer,
  });

  @override
  State<_ShortAnswerInput> createState() => _ShortAnswerInputState();
}

class _ShortAnswerInputState extends State<_ShortAnswerInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void didUpdateWidget(covariant _ShortAnswerInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color? borderColor;
    // Only determine the border color after the answer has been submitted.
    if (widget.quizState == QuizState.answered && !widget.enabled) {
      // Check if a correct answer is available to perform validation.
      final bool hasAnswerToValidate = widget.correctAnswer != null &&
          widget.correctAnswer!.trim().isNotEmpty;

      if (hasAnswerToValidate) {
        final isCorrect = widget.correctAnswer!.trim().toLowerCase() ==
            _controller.text.trim().toLowerCase();
        borderColor = isCorrect ? Colors.green : Colors.red;
      }
      // If `hasAnswerToValidate` is false, `borderColor` remains null,
      // and a neutral-colored border will be used.
    }

    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      decoration: InputDecoration(
        labelText: 'Your Answer',
        border: const OutlineInputBorder(),
        // Define a colored border for the disabled state (after submission).
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            // Use the determined color or default grey if no validation occurred.
            color: borderColor ?? Colors.grey,
            // Make the border thicker only when showing a correct/incorrect status.
            width: borderColor != null ? 2.0 : 1.0,
          ),
        ),
      ),
      onChanged: widget.onChanged,
      minLines: 1,
      maxLines: 3,
      textInputAction: TextInputAction.done,
    );
  }
}
