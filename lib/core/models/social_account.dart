// Updated SocialAccount model with platform-specific data
class SocialAccount {
  final int? id;
  final String platform; // e.g., 'twitter', 'facebook', 'instagram', 'tiktok', 'threads', 'youtube'
  final String username;
  final String token;
  final String? refreshToken;
  final DateTime? tokenExpiry;
  final bool isActive;
  final Map<String, dynamic>? platformSpecificData; // New field for platform-specific info

  SocialAccount({
    this.id,
    required this.platform,
    required this.username,
    required this.token,
    this.refreshToken,
    this.tokenExpiry,
    this.isActive = true,
    this.platformSpecificData,
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
      'platformSpecificData': platformSpecificData,
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
      platformSpecificData: map['platformSpecificData'],
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
    Map<String, dynamic>? platformSpecificData,
  }) {
    return SocialAccount(
      id: id ?? this.id,
      platform: platform ?? this.platform,
      username: username ?? this.username,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenExpiry: tokenExpiry ?? this.tokenExpiry,
      isActive: isActive ?? this.isActive,
      platformSpecificData: platformSpecificData ?? this.platformSpecificData,
    );
  }

  // Helper methods for platform-specific functionality

  // For YouTube: Get available channels
  List<Map<String, dynamic>> get youtubeChannels {
    if (platform != 'youtube' || platformSpecificData == null) {
      return [];
    }

    final List<dynamic> channels = platformSpecificData!['channels'] ?? [];
    return channels.cast<Map<String, dynamic>>();
  }

  // For YouTube: Get default channel
  Map<String, dynamic>? get defaultYoutubeChannel {
    if (platform != 'youtube') {
      return null;
    }

    final channels = youtubeChannels;
    if (channels.isEmpty) {
      return null;
    }

    // Find the default channel or return the first one
    return channels.firstWhere(
          (channel) => channel['isDefault'] == true,
      orElse: () => channels.first,
    );
  }

  // For TikTok: Check if verified
  bool get isTikTokVerified {
    if (platform != 'tiktok' || platformSpecificData == null) {
      return false;
    }

    return platformSpecificData!['verificationStatus'] == 'verified';
  }

  // For Threads: Check if connected via Instagram
  bool get isThreadsConnectedViaInstagram {
    if (platform != 'threads' || platformSpecificData == null) {
      return false;
    }

    return platformSpecificData!['connectedViaInstagram'] == true;
  }

  // Get display name based on platform
  String get displayName {
    switch (platform) {
      case 'twitter':
        return '@$username';
      case 'youtube':
        final defaultChannel = defaultYoutubeChannel;
        return defaultChannel != null
            ? defaultChannel['name']
            : username;
      default:
        return username;
    }
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