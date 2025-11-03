import 'dart:developer' as developer;

class Logger {
  static const String _name = 'TraverseApp';
  
  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _name,
      level: 800, // Info level
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _name,
      level: 900, // Warning level
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _name,
      level: 1000, // Error level
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _name,
      level: 700, // Debug level
      error: error,
      stackTrace: stackTrace,
    );
  }
}