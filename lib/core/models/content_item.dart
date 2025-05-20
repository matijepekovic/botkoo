class ContentItem {
  final int? id;
  final String title;
  final String content;
  final List<String> mediaUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String status; // 'draft', 'scheduled', 'published'

  ContentItem({
    this.id,
    required this.title,
    required this.content,
    this.mediaUrls = const [],
    required this.createdAt,
    this.updatedAt,
    this.status = 'draft',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'mediaUrls': mediaUrls.join(','),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'status': status,
    };
  }

  factory ContentItem.fromMap(Map<String, dynamic> map) {
    return ContentItem(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      mediaUrls: map['mediaUrls'] != null && map['mediaUrls'].isNotEmpty
          ? map['mediaUrls'].split(',')
          : [],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
      status: map['status'],
    );
  }

  // Add these equality operators
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContentItem &&
        other.id == id;
  }

  @override
  int get hashCode => id?.hashCode ?? 0;
}