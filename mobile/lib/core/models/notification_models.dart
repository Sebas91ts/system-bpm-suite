class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.read,
    this.userId,
    this.userEmail,
    this.createdAt,
    this.relatedProcessInstanceId,
    this.relatedTaskId,
  });

  final String id;
  final String? userId;
  final String? userEmail;
  final String title;
  final String message;
  final String type;
  final bool read;
  final String? createdAt;
  final String? relatedProcessInstanceId;
  final String? relatedTaskId;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: (json['id'] as String?) ?? '',
      userId: json['userId'] as String?,
      userEmail: json['userEmail'] as String?,
      title: (json['title'] as String?) ?? '',
      message: (json['message'] as String?) ?? '',
      type: (json['type'] as String?) ?? '',
      read: json['read'] == true,
      createdAt: json['createdAt'] as String?,
      relatedProcessInstanceId: json['relatedProcessInstanceId'] as String?,
      relatedTaskId: json['relatedTaskId'] as String?,
    );
  }
}

class NotificationUnreadCount {
  const NotificationUnreadCount({required this.unreadCount});

  final int unreadCount;

  factory NotificationUnreadCount.fromJson(Map<String, dynamic> json) {
    return NotificationUnreadCount(
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }
}
