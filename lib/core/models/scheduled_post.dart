class ScheduledPost {
  final int? id;
  final int contentItemId;
  final int socialAccountId;
  final DateTime scheduledTime;
  final String status; // 'pending', 'published', 'failed'
  final String? failureReason;

  ScheduledPost({
    this.id,
    required this.contentItemId,
    required this.socialAccountId,
    required this.scheduledTime,
    this.status = 'pending',
    this.failureReason,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contentItemId': contentItemId,
      'socialAccountId': socialAccountId,
      'scheduledTime': scheduledTime.toIso8601String(),
      'status': status,
      'failureReason': failureReason,
    };
  }

  factory ScheduledPost.fromMap(Map<String, dynamic> map) {
    return ScheduledPost(
      id: map['id'],
      contentItemId: map['contentItemId'],
      socialAccountId: map['socialAccountId'],
      scheduledTime: DateTime.parse(map['scheduledTime']),
      status: map['status'],
      failureReason: map['failureReason'],
    );
  }
}