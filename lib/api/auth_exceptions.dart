class AuthExpiredException implements Exception {
  AuthExpiredException({this.message = "Økten er utløpt"});
  final String message;

  @override
  String toString() => "AuthExpiredException: $message";
}
