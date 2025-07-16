import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Enum representing the possible states of the popup
enum PopupState {
  /// Fully collapsed state (only header visible)
  collapsed,

  /// Partially expanded state (shows some content)
  partial,

  /// Fully expanded state (shows maximum content)
  expanded
}

/// Controller class for managing drag gestures and animations for the draggable popup
class PopupGestureController {
  /// The controller for the draggable scrollable sheet
  final DraggableScrollableController scrollController;

  /// The minimum size of the popup (collapsed state)
  final double minChildSize;

  /// The size of the popup in partial state
  final double partialChildSize;

  /// The maximum size of the popup (expanded state)
  final double maxChildSize;

  /// The current state of the popup
  PopupState _currentState = PopupState.collapsed;

  /// Whether the popup is currently being dragged
  bool _isDragging = false;

  /// Constructor
  PopupGestureController({
    required this.scrollController,
    required this.minChildSize,
    required this.partialChildSize,
    required this.maxChildSize,
  });

  /// Get the current state of the popup
  PopupState get currentState => _currentState;

  /// Whether the popup is currently being dragged
  bool get isDragging => _isDragging;

  /// Set the dragging state
  set isDragging(bool value) {
    _isDragging = value;
  }

  /// Animate the popup to expanded state
  void animateToExpanded() {
    _animateTo(maxChildSize);
    _currentState = PopupState.expanded;
    _provideHapticFeedback();
  }

  /// Animate the popup to collapsed state
  void animateToCollapsed() {
    _animateTo(minChildSize);
    _currentState = PopupState.collapsed;
    _provideHapticFeedback();
  }

  /// Animate the popup to partial state
  void animateToPartial() {
    _animateTo(partialChildSize);
    _currentState = PopupState.partial;
    _provideHapticFeedback();
  }

  /// Handle the end of a drag gesture
  void handleDragEnd(double velocity, double position) {
    // Determine target state based on velocity and position
    final targetState = determineTargetState(velocity, position);

    // Animate to the target state
    switch (targetState) {
      case PopupState.collapsed:
        animateToCollapsed();
        break;
      case PopupState.partial:
        animateToPartial();
        break;
      case PopupState.expanded:
        animateToExpanded();
        break;
    }
    
    // Reset dragging state
    _isDragging = false;
  }

  /// Update the current state based on the position
  void updateStateFromPosition(double position) {
    // Only update state if not currently dragging to avoid state flicker
    if (!_isDragging) {
      if (position <= minChildSize + 0.05) {
        _currentState = PopupState.collapsed;
      } else if (position >= maxChildSize - 0.05) {
        _currentState = PopupState.expanded;
      } else {
        _currentState = PopupState.partial;
      }
    }
  }

  /// Determine the target state based on velocity and position
  PopupState determineTargetState(double velocity, double position) {
    // Fast flick up - go to expanded
    if (velocity > 1000) {
      return PopupState.expanded;
    }

    // Fast flick down - go to collapsed
    if (velocity < -1000) {
      return PopupState.collapsed;
    }

    // Based on position
    final midPoint1 = minChildSize + (partialChildSize - minChildSize) / 2;
    final midPoint2 = partialChildSize + (maxChildSize - partialChildSize) / 2;

    if (position < midPoint1) {
      return PopupState.collapsed;
    } else if (position < midPoint2) {
      return PopupState.partial;
    } else {
      return PopupState.expanded;
    }
  }

  /// Animate to a specific size
  void _animateTo(double size) {
    try {
      scrollController.animateTo(
        size,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    } catch (e) {
      // Handle animation failures gracefully
      debugPrint('Animation error: $e');
      // Try to reset to a safe state
      try {
        scrollController.jumpTo(size);
      } catch (_) {
        // If even jumpTo fails, we can't do much more
      }
    }
  }

  /// Provide haptic feedback when snapping to a position
  void _provideHapticFeedback() {
    HapticFeedback.mediumImpact();
  }

  /// Dispose of resources
  void dispose() {
    // No need to dispose the scrollController as it's provided externally
  }
}
