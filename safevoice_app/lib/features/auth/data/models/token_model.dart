class TokenModel {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String role;

  const TokenModel({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.role,
  });

  factory TokenModel.fromJson(Map<String, dynamic> json) => TokenModel(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        userId: json['userId'] as String,
        role: json['role'] as String,
      );
}
