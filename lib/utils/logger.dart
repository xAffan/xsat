import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart' as log;

/// Centralized logging utility for the application
/// Provides different log levels and handles production vs debug logging
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  late final log.Logger _logger;
  late final String _platform;

  factory AppLogger() => _instance;

  AppLogger._internal() {
    _platform = _getPlatform();
    final log.LogFilter filter = kDebugMode ? log.DevelopmentFilter() : ProductionFilter();
    final log.PrettyPrinter printer = log.PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    );
    _logger = log.Logger(printer: printer, filter: filter);
  }

  static void info(String message, {String? tag, Object? error}) {
    _instance._logger.i(_instance._format(message, tag), error: error);
  }

  static void warning(String message, {String? tag, Object? error}) {
    _instance._logger.w(_instance._format(message, tag), error: error);
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _instance._logger.e(_instance._format(message, tag), error: error, stackTrace: stackTrace);
  }

  static void debug(String message, {String? tag, Object? error}) {
    if (kDebugMode) {
      _instance._logger.d(_instance._format(message, tag), error: error);
    }
  }

  String _format(String message, String? tag) {
    return tag != null ? '[$_platform][$tag] $message' : '[$_platform] $message';
  }

  String _getPlatform() {
    if (kIsWeb) return 'Web';
    try {
      if (Platform.isAndroid) return 'Android';
      if (Platform.isIOS) return 'iOS';
      if (Platform.isMacOS) return 'macOS';
      if (Platform.isWindows) return 'Windows';
      if (Platform.isLinux) return 'Linux';
      if (Platform.isFuchsia) return 'Fuchsia';
    } catch (_) {
      // Platform not available (e.g., web)
    }
    return 'Unknown';
  }
}

class ProductionFilter extends log.LogFilter {
  @override
  bool shouldLog(log.LogEvent event) {
    // Only log warnings and errors in release mode
    return event.level.index >= log.Level.warning.index;
  }
}
