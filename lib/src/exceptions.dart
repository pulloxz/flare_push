class FlareException implements Exception {
  FlareException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'FlareException: $message';
}
