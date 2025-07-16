import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_math/flutter_html_math.dart';
import 'package:flutter_html_svg/flutter_html_svg.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/html_styles.dart';
import '../utils/html_processor.dart';

/// A modern gesture-based draggable popup that behaves like YouTube's comment section
/// Supports smooth drag gestures, snap positions, and proper overlay positioning
class DraggableRationalePopup extends StatefulWidget {
  /// The rationale content to display (HTML format)
  final String rationaleContent;

  /// Whether the popup is visible
  final bool isVisible;

  /// Callback when the popup should be dismissed entirely
  final VoidCallback? onDismiss;

  /// Initial size of the popup (0.0 to 1.0)
  final double initialChildSize;

  /// Minimum size of the popup when collapsed (0.0 to 1.0)
  final double minChildSize;

  /// Maximum size of the popup when fully expanded (0.0 to 1.0)
  final double maxChildSize;

  /// Whether haptic feedback is enabled
  final bool enableHapticFeedback;

  const DraggableRationalePopup({
    super.key,
    required this.rationaleContent,
    this.isVisible = true,
    this.onDismiss,
    this.initialChildSize = 0.15,
    this.minChildSize = 0.1,
    this.maxChildSize = 0.7,
    this.enableHapticFeedback = true,
  });

  @override
  State<DraggableRationalePopup> createState() =>
      _DraggableRationalePopupState();
}

class _DraggableRationalePopupState extends State<DraggableRationalePopup>
    with TickerProviderStateMixin {
  late DraggableScrollableController _controller;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Current expansion state
  bool _isExpanded = false;
  double _currentSize = 0.0;

  // Gesture tracking
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();

    _controller = DraggableScrollableController();
    _currentSize = widget.initialChildSize;

    // Animation for fade in/out
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    // Show popup with animation
    if (widget.isVisible) {
      _fadeController.forward();
    }

    // Listen to controller changes
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(DraggableRationalePopup oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _fadeController.forward();
      } else {
        _fadeController.reverse();
      }
    }
  }

  void _onControllerChanged() {
    final newSize = _controller.size;
    if (newSize != _currentSize) {
      setState(() {
        _currentSize = newSize;
        _isExpanded = newSize > (widget.minChildSize + widget.maxChildSize) / 2;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _handleDragStart() {
    _isDragging = true;

    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }

  void _handleDragEnd(double velocity) {
    _isDragging = false;

    // Determine target size based on velocity and current position
    double targetSize;

    // Strong velocity threshold for immediate snapping
    const strongVelocityThreshold = 1000.0;

    if (velocity < -strongVelocityThreshold) {
      // Strong upward swipe - expand
      targetSize = widget.maxChildSize;
    } else if (velocity > strongVelocityThreshold) {
      // Strong downward swipe - collapse or dismiss
      if (_currentSize <= widget.minChildSize + 0.05) {
        _dismissPopup();
        return;
      }
      targetSize = widget.minChildSize;
    } else {
      // Gentle drag - snap to nearest logical position
      final midSize = (widget.minChildSize + widget.maxChildSize) / 2;

      if (_currentSize < widget.minChildSize + 0.05) {
        targetSize = widget.minChildSize;
      } else if (_currentSize < midSize) {
        targetSize = velocity > 0 ? widget.minChildSize : midSize;
      } else {
        targetSize = velocity < 0 ? widget.maxChildSize : midSize;
      }
    }

    _animateToSize(targetSize);
  }

  void _animateToSize(double targetSize) {
    _controller.animateTo(
      targetSize,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );

    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
  }

  void _dismissPopup() {
    _fadeController.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  void _toggleExpansion() {
    final targetSize = _isExpanded ? widget.minChildSize : widget.maxChildSize;
    _animateToSize(targetSize);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildPopupContent(context),
    );
  }

  Widget _buildPopupContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        // Handle the drag notifications for smooth tracking
        return true;
      },
      child: DraggableScrollableSheet(
        initialChildSize: widget.initialChildSize,
        minChildSize: widget.minChildSize,
        maxChildSize: widget.maxChildSize,
        controller: _controller,
        snap: true,
        snapSizes: [
          widget.minChildSize,
          (widget.minChildSize + widget.maxChildSize) / 2,
          widget.maxChildSize,
        ],
        builder: (context, scrollController) {
          return Container(
            // Add bottom padding to avoid covering buttons
            margin: EdgeInsets.only(
              bottom: mediaQuery.padding.bottom +
                  100, // Space for button area + safe area
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDragHandle(colorScheme),
                _buildHeader(colorScheme),
                Flexible(
                  child: _buildContent(scrollController),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDragHandle(ColorScheme colorScheme) {
    return GestureDetector(
      onVerticalDragStart: (_) => _handleDragStart(),
      onVerticalDragEnd: (details) => _handleDragEnd(
        details.primaryVelocity ?? 0,
      ),
      onTap: _toggleExpansion,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            // Drag indicator
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            // Visual feedback for drag state
            if (_isDragging)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Drag to resize',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            "Rationale",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          const Spacer(),
          // Expansion indicator
          AnimatedRotation(
            turns: _isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.keyboard_arrow_up,
              color: colorScheme.onSurface.withOpacity(0.6),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ScrollController scrollController) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: ListView(
        controller: scrollController,
        physics: const BouncingScrollPhysics(),
        children: [
          Html(
            data: HtmlProcessor.process(widget.rationaleContent),
            extensions: const [
              MathHtmlExtension(),
              SvgHtmlExtension(),
              TableHtmlExtension(),
            ],
            style: HtmlStyles.get(context),
          ),
          // Add some bottom padding for better scrolling experience
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
