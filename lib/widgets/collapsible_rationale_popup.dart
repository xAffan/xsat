import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_math/flutter_html_math.dart';
import 'package:flutter_html_svg/flutter_html_svg.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/html_styles.dart';
import '../utils/html_processor.dart';

/// A collapsible popup widget that displays rationale content with smooth animations
/// and theme-aware styling. Positioned as an overlay at the bottom of the screen.
class CollapsibleRationalePopup extends StatefulWidget {
  /// The rationale content to display (HTML format)
  final String rationale;

  /// Whether the popup is visible
  final bool isVisible;

  /// Callback when the toggle button is pressed
  final VoidCallback? onToggle;

  /// Callback when the popup should be dismissed entirely
  final VoidCallback? onDismiss;

  /// Whether the popup starts in expanded state (defaults to false)
  final bool initiallyExpanded;

  const CollapsibleRationalePopup({
    super.key,
    required this.rationale,
    required this.isVisible,
    this.onToggle,
    this.onDismiss,
    this.initiallyExpanded = false,
  });

  @override
  State<CollapsibleRationalePopup> createState() =>
      _CollapsibleRationalePopupState();
}

class _CollapsibleRationalePopupState extends State<CollapsibleRationalePopup>
    with TickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();

    _isExpanded = widget.initiallyExpanded;

    // Animation controller for expand/collapse
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    // Expand animation for content
    _expandAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOutCubic,
    ));

    // Fade animation for content
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _expandController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    ));

    // Set initial state
    if (_isExpanded) {
      _expandController.forward();
    }
  }

  @override
  void didUpdateWidget(CollapsibleRationalePopup oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle expansion state changes
    if (widget.initiallyExpanded != oldWidget.initiallyExpanded) {
      setState(() {
        _isExpanded = widget.initiallyExpanded;
      });

      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }

    widget.onToggle?.call();
  }

  void _handleDragEnd(DragEndDetails details) {
    // If dragging down with sufficient velocity, collapse or dismiss
    if (details.velocity.pixelsPerSecond.dy > 300) {
      if (_isExpanded) {
        // If expanded, first collapse
        _toggleExpanded();
      } else {
        // If already collapsed, dismiss entirely
        widget.onDismiss?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight =
        screenHeight * 0.4; // Maximum 40% of screen height for inline

    return GestureDetector(
      onPanEnd: _handleDragEnd,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
        ),
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with toggle button and drag indicator
            _buildHeader(context, colorScheme),

            // Expandable content
            if (_isExpanded)
              AnimatedBuilder(
                animation: _expandAnimation,
                builder: (context, child) {
                  return SizeTransition(
                    sizeFactor: _expandAnimation,
                    axisAlignment: -1.0,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildContent(context, maxHeight),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return InkWell(
      onTap: _toggleExpanded,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Title
            Expanded(
              child: Text(
                "Rationale",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),

            // Toggle button with animation
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: Icon(
                Icons.keyboard_arrow_up,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, double maxHeight) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight - 60, // Account for header height
      ),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Html(
          data: HtmlProcessor.process(widget.rationale),
          extensions: const [
            MathHtmlExtension(),
            SvgHtmlExtension(),
            TableHtmlExtension(),
          ],
          style: HtmlStyles.get(context),
        ),
      ),
    );
  }
}
