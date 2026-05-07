class NotificationType {
  //học sinh
  static const classJoined = 'class_joined';
  static const kickedClass = 'kicked_class';
  static const newAssignment = 'new_assignment';
  static const examDeadline = 'exam_deadline';
  static const subSuccess = 'sub_success';
  static const examExpiredUnsubmitted = 'exam_expired_unsubmitted'; //hết hạn mà chưa nộp


  //giáo viên
  static const classCreated = 'class_created';
  static const examCreated = 'exam_created';
  static const examAssigned = 'exam_assigned';
  static const studentJoined = 'student_joined';
  static const subReceived = 'sub_received';
  static const allSubmitted = 'all_submitted';
  static const examClosed = 'exam_closed';
  static const examClosingSoon = 'exam_closing_soon';

  static const passChanged = 'pass_changed';
}

class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final String createdAt;            
  final Map<String, dynamic> data;  

 const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.isRead = false,
    required this.createdAt,
    this.data = const {},
  });

    factory NotificationModel.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    return NotificationModel(
      id: id,
      userId: (json['user_id'] as String?) ?? '',
      type: (json['type'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      isRead: (json['is_read'] as bool?) ?? false,
      createdAt: (json['created_at'] as String?) ?? '',
      data: Map<String, dynamic>.from((json['data'] as Map?) ?? {}),
    );
  }
 
 
  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'type': type,
        'title': title,
        'body': body,
        'is_read': isRead,
        'created_at': createdAt,
        'data': data,
      };
 
  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        userId: userId,
        type: type,
        title: title,
        body: body,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        data: data,
      );
}