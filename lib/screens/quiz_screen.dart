import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../services/sound_service.dart';
import '../utils/html_processor.dart';
import '../widgets/answer_option.dart';
import '../widgets/collapsible_rationale_popup.dart';
import '../widgets/question_count_widget.dart';
import '../widgets/no_results_widget.dart';
import 'settings_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  // A GlobalKey to identify the widget we want to capture for sharing.
  final GlobalKey _questionAreaKey = GlobalKey();

  // Create ShareService instance directly instead of using Provider
  late final ShareService _shareService;

  // Create SoundService instance
  late final SoundService _soundService;

  // Popup state management for rationale display
  bool _isRationaleVisible = false;

  // Store filter provider reference to avoid accessing context in dispose
  FilterProvider? _filterProvider;

  // Scroll controller for ensuring MCQ options are visible
  final ScrollController _scrollController = ScrollController();

  // Map to store GlobalKeys for each answer option
  final Map<String, GlobalKey> _answerOptionKeys = {};

  // Animation controllers for enhanced UI
  late AnimationController _questionAnimationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _questionSlideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize services
    _shareService = ShareService();
    _soundService = SoundService();

    // Initialize animation controllers
    _questionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize animations
    _questionSlideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _questionAnimationController,
      curve: Curves.easeOutCubic,
    ));


    // Initialize the quiz after the first frame is built
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
    // Dispose controllers
    _scrollController.dispose();
    _questionAnimationController.dispose();
    _fabAnimationController.dispose();
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
        // Start question animation
        _questionAnimationController.forward();
      }
    });
  }

  /// Shows a modern dialog prompting the user to restart the quiz
  void _showRestartDialog() {
    final settingsProvider = context.read<SettingsProvider>();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.refresh, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              const Text('Apply Settings'),
            ],
          ),
          content: const Text(
            'To apply the new content settings, the quiz needs to be restarted.',
            style: TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Cancel'),
              onPressed: () {
                settingsProvider.appliedChanges();
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Restart Quiz'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _initializeQuizBasedOnSettings();
                settingsProvider.appliedChanges();
              },
            ),
          ],
        );
      },
    );
  }

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
        return 'Medium';
    }
  }

  /// Shows the rationale popup when answer is submitted
  void _showRationalePopup() {
    if (mounted) {
      setState(() {
        _isRationaleVisible = true;
      });
      _scrollToShowAnswerOptions();
    }
  }

  /// Resets popup state when navigating to next question
  void _resetPopupState() {
    setState(() {
      _isRationaleVisible = false;
    });
    // Reset and restart animations
    _questionAnimationController.reset();
    _questionAnimationController.forward();
  }

  /// Scrolls to ensure the selected answer option is visible
  void _scrollToShowAnswerOptions() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients && mounted) {
        final quizProvider = context.read<QuizProvider>();
        final selectedAnswerId = quizProvider.selectedAnswerId;

        if (selectedAnswerId != null && _answerOptionKeys.containsKey(selectedAnswerId)) {
          final selectedKey = _answerOptionKeys[selectedAnswerId]!;
          final RenderBox? renderBox = selectedKey.currentContext?.findRenderObject() as RenderBox?;

          if (renderBox != null) {
            final position = renderBox.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
            final scrollOffset = _scrollController.position.pixels;
            final viewportHeight = _scrollController.position.viewportDimension;
            final targetOffset = position.dy + scrollOffset - (viewportHeight / 2);

            _scrollController.animateTo(
              targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        }
      }
    });
  }

  /// Enhanced share functionality with better feedback
  Future<void> _shareQuestion() async {
    final quizProvider = context.read<QuizProvider>();
    final questionId = quizProvider.currentQuestion?.externalId;

    if (questionId == null) {
      _showSnackBar('No question available to share.', Colors.orange);
      return;
    }

    // Show modern loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Preparing question for sharing...',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
          ],
        ),
      ),
    );

    try {
      final result = await _shareService.shareWidgetAsPdf(
        widgetKey: _questionAreaKey,
        questionId: questionId,
        context: context,
      );

      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      if (!result.success && mounted) {
        _showSnackBar(result.message ?? 'An unknown error occurred.', Colors.red);
      } else if (result.success && result.message != null && mounted) {
        _showSnackBar(result.message!, Colors.green);
      }
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      _showSnackBar('Unexpected error: $e', Colors.red);
    }
  }

  /// Helper method to show consistent snackbars
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Handles submitting the answer with sound effects and animations
  void _handleSubmitAnswer(QuizProvider provider) {
    final question = provider.currentQuestion!;
    final selectedAnswer = provider.selectedAnswerId;

    // Submit the answer
    provider.submitAnswer();

    // Play sound based on whether answer is correct
    final settingsProvider = context.read<SettingsProvider>();
    if (settingsProvider.soundEnabled) {
      if (question.type == 'mcq') {
        final isCorrect = selectedAnswer == question.correctKey;
        if (isCorrect) {
          _soundService.playCorrectSound();
        } else {
          _soundService.playWrongSound();
        }
      } else if (question.type == 'spr') {
        bool isCorrect = false;
        if (question.correctKey.trim().isNotEmpty) {
          isCorrect = question.correctKey.trim().toLowerCase() ==
              (selectedAnswer?.toString().trim().toLowerCase() ?? '');
          if (isCorrect) {
            _soundService.playCorrectSound();
          } else {
            _soundService.playWrongSound();
          }
        }
      }
    }

    // Show rationale popup
    _showRationalePopup();
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = context.watch<QuizProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    // Show restart dialog if needed
    if (settingsProvider.hasSettingsChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ModalRoute.of(context)?.isCurrent == true) {
          _showRestartDialog();
        }
      });
    }

    // Start FAB animation when question is ready
    if (quizProvider.state == QuizState.ready && !_fabAnimationController.isCompleted) {
      _fabAnimationController.forward();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildModernAppBar(context, settingsProvider),
      body: _buildBody(context, quizProvider),
    );
  }

  /// Builds a modern, clean app bar
  PreferredSizeWidget _buildModernAppBar(BuildContext context, SettingsProvider settingsProvider) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      titleSpacing: 0,
      title: Row(
        children: [
          // App icon with subtle animation
            Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              'assets/images/icon.png',
              width: 42,
              height: 42,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'xSAT Quiz',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Consumer<FilterProvider>(
                  builder: (context, filterProvider, child) {
                    if (settingsProvider.isCachingEnabled) {
                      return QuestionCountWidget(
                        showProgress: true,
                        textStyle: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      );
                    } else {
                      return QuestionCountWidget(
                        showProgress: false,
                        textStyle: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
                  // Share button as IconButton
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.share, color: Colors.blue, size: 20),
                    ),
                    onPressed: () => _shareQuestion(),
                    tooltip: 'Share Question',
                        padding: EdgeInsets.zero,          // <-- remove default padding

                  ),
                  // Mistakes history button as IconButton (only if caching enabled)
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.history, color: Colors.orange, size: 20),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/mistakes');
                    },
                    tooltip: 'Mistakes History',
                        padding: EdgeInsets.zero,          // <-- remove default padding

                  ),
                  // Modern settings button
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.settings_outlined, size: 20),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                        padding: EdgeInsets.zero,          // <-- remove default padding
                    tooltip: 'Settings',  
                  ),
                  SizedBox(
                    width: 2, // Add spacing between actions
                  ),
      ],
    );
  }

  /// Builds the main body with enhanced animations
  Widget _buildBody(BuildContext context, QuizProvider provider) {
    switch (provider.state) {
      case QuizState.uninitialized:
        return _buildLoadingState("Initializing Quiz...");
      case QuizState.loading:
        return _buildLoadingState("Loading Question...");
      case QuizState.error:
        return _buildErrorState(provider);
      case QuizState.complete:
        return _buildCompleteState(provider);
      case QuizState.ready:
      case QuizState.answered:
        return _buildQuizLayout(context, provider);
    }
  }

  /// Builds modern loading state
  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds modern error state
  Widget _buildErrorState(QuizProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Something went wrong",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              provider.errorMessage ?? "An unknown error occurred.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _initializeQuizBasedOnSettings,
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds modern complete state
  Widget _buildCompleteState(QuizProvider provider) {
    return Consumer<FilterProvider>(
      builder: (context, filterProvider, child) {
        final hasActiveFilters = filterProvider.hasActiveFilters;
        final isNoResults = provider.errorMessage?.contains("No questions match") == true;

        if (isNoResults) {
          return NoResultsWidget(
            hasActiveFilters: hasActiveFilters,
            onClearFilters: hasActiveFilters ? () => filterProvider.clearFilters() : null,
            onRestart: _initializeQuizBasedOnSettings,
            customMessage: provider.errorMessage,
          );
        }

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.celebration,
                    color: Colors.green,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Quiz Complete!",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  hasActiveFilters
                      ? "You've answered all questions matching the selected filters."
                      : "You've answered all available questions.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _initializeQuizBasedOnSettings,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Start New Quiz"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds the enhanced quiz layout with animations
  Widget _buildQuizLayout(BuildContext context, QuizProvider provider) {
    final question = provider.currentQuestion!;
    
    Widget answerSection;
    if (question.type == 'mcq') {
      answerSection = Column(
        children: [
          ...question.answerOptions.map((option) {
            _answerOptionKeys[option.id] = GlobalKey();
            return AnswerOptionTile(
              key: _answerOptionKeys[option.id],
              optionId: option.id,
              optionContent: option.content,
              currentState: provider.state,
              selectedOptionId: provider.selectedAnswerId,
              correctOptionId: question.correctKey,
              onSelect: () => provider.selectAnswer(option.id),
            );
          }),
        ],
      );
    } else if (question.type == 'spr') {
      answerSection = _ShortAnswerInput(
        quizState: provider.state,
        correctAnswer: question.correctKey,
        initialValue: provider.selectedAnswerId,
        enabled: provider.state == QuizState.ready,
        onChanged: provider.selectAnswer,
      );
    } else {
      answerSection = Text(
        'Unsupported question type.',
        style: GoogleFonts.poppins(fontSize: 16),
      );
    }

    return RepaintBoundary(
      key: _questionAreaKey,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            Expanded(
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(_questionSlideAnimation),
                child: FadeTransition(
                  opacity: _questionSlideAnimation,
                  child: LayoutBuilder(
                    builder: (context, viewportConstraints) {
                      return SingleChildScrollView(
                        controller: _scrollController,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: viewportConstraints.maxHeight,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Column(
                              children: [
                                PreferredSize(
        preferredSize: const Size.fromHeight(44),
        child: Consumer<QuizProvider>(
          builder: (context, quizProvider, _) {
            final metadata = quizProvider.currentQuestion?.metadata;
            if (metadata == null) {
              return const SizedBox.shrink();
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Wrap(
                  alignment: WrapAlignment.center,
                runSpacing: 8,
                children: [
                  // Category chip
                  _MetadataChip(
                    label: metadata.primaryClassDescription,
                    icon: Icons.category_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  // Skill chip
                  _MetadataChip(
                    label: metadata.skillDescription,
                    icon: Icons.psychology_outlined,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),

                  // Difficulty badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(metadata.difficulty),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getDifficultyLabel(metadata.difficulty),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
                                // Question card with modern styling
                                Container(
                                  width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.outline,
                                    width: 2,
                                  ),
                                  ),
                                  child: Html(
                                    data: HtmlProcessor.process(
                                          question.stimulus,
                                          darkMode: Theme.of(context).brightness == Brightness.dark,
                                        ) +
                                        HtmlProcessor.process(
                                          question.stem,
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
                                const SizedBox(height: 24),
                                answerSection,
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Enhanced rationale popup
            if (provider.state == QuizState.answered)
              CollapsibleRationalePopup(
                rationale: question.rationale,
                isVisible: _isRationaleVisible,
                initiallyExpanded: true,
                onToggle: () {},
                onDismiss: () {
                  setState(() {
                    _isRationaleVisible = false;
                  });
                },
              ),
            // Modern action button
            Container(
              padding: const EdgeInsets.all(20.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: provider.state == QuizState.answered
                    ? ElevatedButton.icon(
                        key: const ValueKey('next_button'),
                        onPressed: () {
                          _resetPopupState();
                          provider.nextQuestion();
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text("Next Question"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(double.infinity, 0),
                        ),
                      )
                    : ElevatedButton.icon(
  key: const ValueKey('submit_button'),
  onPressed: provider.selectedAnswerId != null
      ? () => _handleSubmitAnswer(provider)
      : null,
  icon: const Icon(Icons.check),
  label: const Text("Submit Answer"),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green,
    foregroundColor: Colors.white,
    disabledBackgroundColor: Theme.of(context).brightness == Brightness.dark 
        ? Colors.grey[800] 
        : Colors.grey[300],
    disabledForegroundColor: Theme.of(context).brightness == Brightness.dark 
        ? Colors.grey[600] 
        : Colors.grey[600],
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    minimumSize: const Size(double.infinity, 0),
  ),
)

              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetadataChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _MetadataChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  State<_MetadataChip> createState() => __MetadataChipState();
}

class __MetadataChipState extends State<_MetadataChip> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    const iconSize = 14.0;
    const gap = 4.0;
    const horizontalPadding = 20.0;

    final textStyle = GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: widget.color,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textWidth = constraints.maxWidth -
            iconSize -
            gap -
            horizontalPadding;

        final textPainter = TextPainter(
          text: TextSpan(text: widget.label, style: textStyle),
          maxLines: 1,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: textWidth);

        final needsExpansion = textPainter.didExceedMaxLines;

        // reset expansion when the text fits again
        if (!needsExpansion && _expanded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _expanded = false);
          });
        }

        final chip = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(widget.icon, size: iconSize, color: widget.color),
              const SizedBox(width: gap),
              Flexible(
                child: Text(
                  widget.label,
                  style: textStyle,
                  overflow: _expanded ? null : TextOverflow.ellipsis,
                  maxLines: _expanded ? null : 1,
                ),
              ),
            ],
          ),
        );

        return needsExpansion
            ? InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _expanded = !_expanded),
                child: chip,
              )
            : chip;
      },
    );
  }
}

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

/// Enhanced widget for short constructed response input
class _ShortAnswerInput extends StatefulWidget {
  final String? initialValue;
  final bool enabled;
  final ValueChanged<String> onChanged;
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
    
    // Determine styling based on quiz state
    if (widget.quizState == QuizState.answered && !widget.enabled) {
      final bool hasAnswerToValidate = widget.correctAnswer != null &&
          widget.correctAnswer!.trim().isNotEmpty;

      if (hasAnswerToValidate) {
        final isCorrect = widget.correctAnswer!.trim().toLowerCase() ==
            _controller.text.trim().toLowerCase();
        borderColor = isCorrect ? Colors.green : Colors.red;
      }
    }

    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      decoration: InputDecoration(
        labelText: 'Your Answer',
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        // Define a colored border for the disabled state (after submission).
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            // Use the determined color or default grey if no validation occurred.
            color: borderColor ?? Colors.grey,
            // Make the border thicker only when showing a correct/incorrect status.
            width: borderColor != null ? 2.0 : 1.0,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      onChanged: widget.onChanged,
      minLines: 1,
      maxLines: 3,
      textInputAction: TextInputAction.done,
    );
  }
  }