class ValidationException implements Exception {
  ValidationException(this.message, {this.details});

  final String message;
  final Map<String, String>? details;

  @override
  String toString() => message;
}
