class SocialAccount {
  final int? id;
  final String platform; // e.g., 'twitter', 'facebook', 'instagram'
  final String username;
  final String token;
  final String? refreshToken;
  final DateTime? tokenExpiry;
  final bool isActive;

  SocialAccount({
    this.id,
    required this.platform,
    required this.username,
    required this.token,
    this.refreshToken,
    this.tokenExpiry,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'platform': platform,
      'username': username,
      'token': token,
      'refreshToken': refreshToken,
      'tokenExpiry': tokenExpiry?.toIso8601String(),
      'isActive': isActive ? 1 : 0,
    };
  }

  factory SocialAccount.fromMap(Map<String, dynamic> map) {
    return SocialAccount(
      id: map['id'],
      platform: map['platform'],
      username: map['username'],
      token: map['token'],
      refreshToken: map['refreshToken'],
      tokenExpiry: map['tokenExpiry'] != null
          ? DateTime.parse(map['tokenExpiry'])
          : null,
      isActive: map['isActive'] == 1,
    );
  }

  // Add copyWith method for easy object updates
  SocialAccount copyWith({
    int? id,
    String? platform,
    String? username,
    String? token,
    String? refreshToken,
    DateTime? tokenExpiry,
    bool? isActive,
  }) {
    return SocialAccount(
      id: id ?? this.id,
      platform: platform ?? this.platform,
      username: username ?? this.username,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenExpiry: tokenExpiry ?? this.tokenExpiry,
      isActive: isActive ?? this.isActive,
    );
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SocialAccount &&
        other.id == id;
  }

  @override
  int get hashCode => id?.hashCode ?? 0;
}