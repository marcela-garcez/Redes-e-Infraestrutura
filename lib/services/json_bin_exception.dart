class JsonBinException implements Exception {
  const JsonBinException(this.message, {this.statusCode, this.stage, this.method});

  final String message;
  final int? statusCode;
  final String? stage;
  final String? method;

  @override
  String toString() => 'JsonBinException($statusCode): $message';
}
