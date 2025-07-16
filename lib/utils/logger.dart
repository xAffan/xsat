import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Centralized logging utility for the application
/// Provides different log levels and handles production vs debug logging
class Logger {
  static const String _appName = 'SAT_Quiz';

  /// Log an informational message
  static void info(String message, {String? tag, Object? error}) {
    _log('INFO', message, tag: tag, error: error);
  }

  /// Log a warning message
  static void warning(String message, {String? tag, Object? error}) {
    _log('WARNING', message, tag: tag, error: error);
  }

  /// Log an error message
  static void error(String message,
      {String? tag, Object? error, StackTrace? stackTrace}) {
    _log('ERROR', message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Log a debug message (only in debug mode)
  static void debug(String message, {String? tag, Object? error}) {
    if (kDebugMode) {
      _log('DEBUG', message, tag: tag, error: error);
    }
  }

  /// Internal logging method
  static void _log(
    String level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final tagPrefix = tag != null ? '[$tag] ' : '';
    final logMessage = '[$_appName] $tagPrefix$message';

    if (kDebugMode) {
      // In debug mode, use developer.log for better debugging experience
      developer.log(
        logMessage,
        name: _appName,
        level: _getLevelValue(level),
        error: error,
        stackTrace: stackTrace,
      );
    } else {
      // In production, use print for basic logging
      // In a real app, you might want to use a more sophisticated logging service
      print('$level: $logMessage');
      if (error != null) {
        print('Error: $error');
      }
      if (stackTrace != null) {
        print('StackTrace: $stackTrace');
      }
    }
  }

  /// Convert log level string to numeric value for developer.log
  static int _getLevelValue(String level) {
    switch (level) {
      case 'DEBUG':
        return 500;
      case 'INFO':
        return 800;
      case 'WARNING':
        return 900;
      case 'ERROR':
        return 1000;
      default:
        return 800;
    }
  }
}
