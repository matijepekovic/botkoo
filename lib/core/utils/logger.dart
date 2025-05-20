// lib/core/utils/logger.dart
import 'package:flutter/foundation.dart';

/// A simple logger utility class that handles logging appropriately
/// for both debug and production builds.
class Logger {
  /// Log a debug message
  static void d(String tag, String message) {
    if (kDebugMode) {
      debugPrint('DEBUG: $tag - $message');
    }
  }

  /// Log an error message
  static void e(String tag, String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('ERROR: $tag - $message');
      if (error != null) {
        debugPrint('ERROR DETAILS: $error');
      }
      if (stackTrace != null) {
        debugPrint('STACK TRACE: $stackTrace');
      }
    }
  }

  /// Log an info message
  static void i(String tag, String message) {
    if (kDebugMode) {
      debugPrint('INFO: $tag - $message');
    }
  }

  /// Log a warning message
  static void w(String tag, String message) {
    if (kDebugMode) {
      debugPrint('WARNING: $tag - $message');
    }
  }
}