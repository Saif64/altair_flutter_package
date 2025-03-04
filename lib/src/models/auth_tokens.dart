class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final DateTime? accessTokenExpiry;
  final DateTime? refreshTokenExpiry;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.accessTokenExpiry,
    this.refreshTokenExpiry,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      accessTokenExpiry:
          json['access_token_expiry'] != null
              ? DateTime.parse(json['access_token_expiry'])
              : null,
      refreshTokenExpiry:
          json['refresh_token_expiry'] != null
              ? DateTime.parse(json['refresh_token_expiry'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'access_token_expiry': accessTokenExpiry?.toIso8601String(),
      'refresh_token_expiry': refreshTokenExpiry?.toIso8601String(),
    };
  }

  bool get isAccessTokenExpired =>
      accessTokenExpiry != null && DateTime.now().isAfter(accessTokenExpiry!);

  bool get isRefreshTokenExpired =>
      refreshTokenExpiry != null && DateTime.now().isAfter(refreshTokenExpiry!);
}
