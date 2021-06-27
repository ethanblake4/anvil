class ConfigError extends AnvilError {
  const ConfigError(String message) : super(message);

  @override
  String get name => 'ConfigError';
}

class BuildError extends AnvilError {
  const BuildError(String message, [String? help]) : super(message, help);

  @override
  String get name => 'BuildError';
}

class CommandError extends AnvilError {
  const CommandError(String message) : super(message);

  @override
  String get name => 'CommandError';
}

abstract class AnvilError implements Exception {
  const AnvilError([this.message, this.help]);

  final Object? message;

  final String? help;

  String get name;

  @override
  String toString() => message == null ? name : '$name: $message';
}
