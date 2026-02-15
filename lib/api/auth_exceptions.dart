class AuthExpiredException implements Exception {
  AuthExpiredException({this.message = "Session expired"});
  final String message;

  @override
  String toString() => "AuthExpiredException: $message";
}
