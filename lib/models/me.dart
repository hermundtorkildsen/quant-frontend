class MeResponse {
  final String username;

  MeResponse({required this.username});

  factory MeResponse.fromJson(Map<String, dynamic> json) {
    return MeResponse(
      username: (json['username'] ?? '').toString(),
    );
  }
}