/// Custom exceptions for the SAT Quiz application
/// Provides specific error types for better error handling and user feedback

/// Base exception class for all application-specific exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException: $message';
}

/// Exception thrown when network operations fail
class NetworkException extends AppException {
  const NetworkException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception thrown when API responses are invalid or malformed
class ApiException extends AppException {
  final int? statusCode;

  const ApiException(
    String message, {
    this.statusCode,
    String? code,
    dynamic originalError,
  }) : super(message, code: code, originalError: originalError);

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}

/// Exception thrown when data parsing or validation fails
class DataException extends AppException {
  const DataException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'DataException: $message';
}

/// Exception thrown when filter operations fail
class FilterException extends AppException {
  const FilterException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'FilterException: $message';
}

/// Exception thrown when storage operations fail
class StorageException extends AppException {
  const StorageException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'StorageException: $message';
}

/// Exception thrown when UI operations fail
class UIException extends AppException {
  const UIException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'UIException: $message';
}
