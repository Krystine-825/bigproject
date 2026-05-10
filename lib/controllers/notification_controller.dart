
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../data/models/notification_model.dart';
import '../data/services/auth_service.dart';

class NotificationController {
  final db = FirebaseFirestore.instance;
  final auth = AuthService();

  // Cloud Functions instance — region phải khớp với index.js
  final _fn = FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  String get _myUid => auth.currentUid ?? '';
  CollectionReference get _col => db.collection('notifications');

  /// Stream toàn bộ thông báo của user hiện tại, mới nhất trước
  Stream<List<NotificationModel>> streamMyNotifications() {
    if (_myUid.isEmpty) return const Stream.empty();
    return _col
        .where('user_id', isEqualTo: _myUid)
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => NotificationModel.fromJson(
                  d.data() as Map<String, dynamic>,
                  id: d.id,
                ))
            .toList());
  }

  /// Stream số thông báo chưa đọc — dùng cho badge nút chuông
  Stream<int> streamUnreadCount() {
    if (_myUid.isEmpty) return Stream.value(0);
    return _col
        .where('user_id', isEqualTo: _myUid)
        .where('is_read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> markAsRead(String notifId) async {
    try {
      await _col.doc(notifId).update({'is_read': true});
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    if (_myUid.isEmpty) return;
    try {
      final snap = await _col
          .where('user_id', isEqualTo: _myUid)
          .where('is_read', isEqualTo: false)
          .get();
      if (snap.docs.isEmpty) return;
      final batch = db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'is_read': true});
      }
      await batch.commit();
    } catch (_) {}
  }

  Future<void> deleteNotification(String notifId) async {
    try {
      await _col.doc(notifId).delete();
    } catch (_) {}
  }

 

  /// Ghi 1 thông báo vào Firestore
  Future<void> _write({
    required String toUserId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    if (toUserId.isEmpty) return;
    try {
      final notif = NotificationModel(
        id: '',
        userId: toUserId,
        type: type,
        title: title,
        body: body,
        isRead: false,
        createdAt: DateTime.now().toIso8601String(),
        data: data,
      );
      await _col.add(notif.toJson());
    } catch (_) {}
  }

  /// Gửi push notification qua Cloud Function (onCall)
  Future<void> _sendPush({
    required String toUserId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    if (toUserId.isEmpty) return;
    try {
      await _fn.httpsCallable('sendPushOnNotification').call({
        'userId': toUserId,
        'title': title,
        'body': body,
        'type': type,
        'data': data,
      });
    } catch (_) {}
  }

  /// Ghi Firestore + gửi push cùng lúc cho 1 user
  Future<void> _notify({
    required String toUserId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    await Future.wait([
      _write(toUserId: toUserId, type: type, title: title, body: body, data: data),
      _sendPush(toUserId: toUserId, type: type, title: title, body: body, data: data),
    ]);
  }

  /// Ghi nhiều thông báo + gửi push cho nhiều user cùng lúc (batch)
  Future<void> _notifyBatch({
    required List<String> toUserIds,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    final valid = toUserIds.where((u) => u.isNotEmpty).toList();
    if (valid.isEmpty) return;

    // Ghi Firestore batch
    try {
      final now = DateTime.now().toIso8601String();
      for (var i = 0; i < valid.length; i += 400) {
        final chunk = valid.sublist(i, i + 400 > valid.length ? valid.length : i + 400);
        final batch = db.batch();
        for (final uid in chunk) {
          final ref = _col.doc();
          batch.set(ref, {
            'user_id': uid,
            'type': type,
            'title': title,
            'body': body,
            'is_read': false,
            'created_at': now,
            'data': data,
          });
        }
        await batch.commit();
      }
    } catch (_) {}

    // Gửi push song song cho tất cả
    await Future.wait(
      valid.map((uid) => _sendPush(
            toUserId: uid,
            type: type,
            title: title,
            body: body,
            data: data,
          )),
    );
  }

 

  // Học sinh: tham gia lớp
  Future<void> notifyStudentJoinedClass({
    required String studentId,
    required String studentName,
    required String teacherId,
    required String className,
    required String classId,
  }) async {
    await Future.wait([
      _notify(
        toUserId: studentId,
        type: NotificationType.classJoined,
        title: 'Tham gia lớp thành công 🎉',
        body: 'Bạn đã gia nhập lớp "$className". Chúc học tốt!',
        data: {'classId': classId, 'className': className},
      ),
      _notify(
        toUserId: teacherId,
        type: NotificationType.studentJoined,
        title: 'Học sinh mới tham gia',
        body: '$studentName vừa tham gia lớp "$className".',
        data: {'classId': classId, 'className': className, 'studentId': studentId},
      ),
    ]);
  }

  // Học sinh: bị kick
  Future<void> notifyKickedFromClass({
    required String studentId,
    required String className,
    required String classId,
  }) async {
    await _notify(
      toUserId: studentId,
      type: NotificationType.kickedClass,
      title: 'Bạn đã rời lớp',
      body: 'Bạn đã bị xoá khỏi lớp "$className".',
      data: {'classId': classId, 'className': className},
    );
  }

  // Học sinh: được giao đề
  Future<void> notifyExamAssignedToStudents({
    required List<String> studentIds,
    required String examName,
    required String examId,
    required String classId,
    required String className,
    required DateTime closeAt,
  }) async {
    final closeStr =
        '${closeAt.day}/${closeAt.month}/${closeAt.year} ${closeAt.hour.toString().padLeft(2, '0')}:${closeAt.minute.toString().padLeft(2, '0')}';
    await _notifyBatch(
      toUserIds: studentIds,
      type: NotificationType.newAssignment,
      title: 'Đề thi mới: $examName',
      body: 'Lớp "$className" vừa được giao đề. Hạn nộp: $closeStr.',
      data: {'examId': examId, 'classId': classId, 'examName': examName, 'className': className},
    );
  }

  // Giáo viên: xác nhận giao đề
  Future<void> notifyExamAssignedConfirm({
    required String teacherId,
    required String examName,
    required String examId,
    required String className,
    required String classId,
  }) async {
    await _notify(
      toUserId: teacherId,
      type: NotificationType.examAssigned,
      title: 'Giao đề thành công ✅',
      body: '"$examName" đã được giao cho lớp "$className".',
      data: {'examId': examId, 'classId': classId, 'examName': examName},
    );
  }

  // Học sinh: nộp bài thành công
  Future<void> notifySubmissionSuccess({
    required String studentId,
    required String examName,
    required String examId,
    required String classId,
    required double score,
  }) async {
    await _notify(
      toUserId: studentId,
      type: NotificationType.subSuccess,
      title: 'Nộp bài thành công ✅',
      body: '"$examName" — Điểm của bạn: ${score.toStringAsFixed(1)}/10.',
      data: {'examId': examId, 'classId': classId, 'score': score},
    );
  }

  // Giáo viên: nhận bài nộp
  Future<void> notifyTeacherNewSubmission({
    required String teacherId,
    required String studentName,
    required String examName,
    required String examId,
    required String classId,
    required int submittedCount,
    required int totalCount,
  }) async {
    await _notify(
      toUserId: teacherId,
      type: NotificationType.subReceived,
      title: 'Học sinh vừa nộp bài',
      body: '$studentName đã nộp "$examName". Đã nộp: $submittedCount/$totalCount học sinh.',
      data: {
        'examId': examId,
        'classId': classId,
        'submittedCount': submittedCount,
        'totalCount': totalCount,
      },
    );
  }

  // Giáo viên: 100% học sinh đã nộp
  Future<void> notifyAllStudentsSubmitted({
    required String teacherId,
    required String examName,
    required String examId,
    required String classId,
    required String className,
    required int totalCount,
  }) async {
    await _notify(
      toUserId: teacherId,
      type: NotificationType.allSubmitted,
      title: '100% đã nộp bài 🎉',
      body: 'Tất cả $totalCount học sinh lớp "$className" đã nộp "$examName". Bạn có thể xem kết quả.',
      data: {'examId': examId, 'classId': classId, 'className': className},
    );
  }

  // Giáo viên: tạo lớp
  Future<void> notifyClassCreated({
    required String teacherId,
    required String className,
    required String classId,
    required String code,
  }) async {
    await _notify(
      toUserId: teacherId,
      type: NotificationType.classCreated,
      title: 'Tạo lớp thành công 🎉',
      body: 'Lớp "$className" đã được tạo. Mã lớp: $code.',
      data: {'classId': classId, 'className': className, 'code': code},
    );
  }

  // Giáo viên: tạo đề
  Future<void> notifyExamCreated({
    required String teacherId,
    required String examName,
    required String examId,
    required int questionCount,
  }) async {
    await _notify(
      toUserId: teacherId,
      type: NotificationType.examCreated,
      title: 'Tạo đề thi thành công ✅',
      body: '"$examName" gồm $questionCount câu hỏi đã sẵn sàng để giao.',
      data: {'examId': examId, 'examName': examName},
    );
  }

  // Hệ thống: đổi mật khẩu
  Future<void> notifyPasswordChanged({required String userId}) async {
    await _notify(
      toUserId: userId,
      type: NotificationType.passChanged,
      title: 'Mật khẩu đã được thay đổi 🔒',
      body: 'Mật khẩu của bạn vừa được cập nhật. Nếu không phải bạn, hãy liên hệ hỗ trợ ngay.',
      data: {},
    );
  }

  // Học sinh: đề thi bị xóa hoặc thu hồi
  Future<void> notifyExamDeletedToStudents({
    required List<String> studentIds,
    required String examName,
    required String classId,
    required String className,
  }) async {
    await _notifyBatch(
      toUserIds: studentIds,
      type: NotificationType.examDeleted, 
      title: 'Đề thi đã bị hủy',
      body: 'Đề thi "$examName" của lớp "$className" đã bị giáo viên thu hồi hoặc xóa bỏ.',
      data: {
        'classId': classId, 
        'className': className, 
        'examName': examName
      },
    );
  }

   Future<void> notifyExamDeadline({
    required List<String> studentIds,
    required String examName,
    required String examId,
    required String classId,
    required String className,
    required DateTime closeAt,
    required bool is24h, // true = nhắc trước 24h, false = nhắc trước 1h
  }) async {
    final closeStr =
        '${closeAt.day}/${closeAt.month}/${closeAt.year} '
        '${closeAt.hour.toString().padLeft(2, '0')}:'
        '${closeAt.minute.toString().padLeft(2, '0')}';
 
    final label = is24h ? '24 giờ' : '1 giờ';
 
    await _notifyBatch(
      toUserIds: studentIds,
      type: NotificationType.examDeadline,
      title: '⏰ Sắp hết hạn nộp bài',
      body: 'Còn $label để nộp "$examName" lớp "$className". Hạn: $closeStr.',
      data: {
        'examId': examId,
        'classId': classId,
        'examName': examName,
        'className': className,
        'closeAt': closeAt.toIso8601String(),
      },
    );
  }
 
  //  Hết hạn mà học sinh chưa nộp 
  Future<void> notifyExamExpiredUnsubmitted({
    required List<String> studentIds,
    required String examName,
    required String examId,
    required String classId,
    required String className,
  }) async {
    await _notifyBatch(
      toUserIds: studentIds,
      type: NotificationType.examExpiredUnsubmitted,
      title: '❌ Bạn đã bỏ lỡ bài thi',
      body: 'Đã hết hạn nộp "$examName" lớp "$className" mà bạn chưa nộp.',
      data: {
        'examId': examId,
        'classId': classId,
        'examName': examName,
        'className': className,
      },
    );
  }
 
  // Đề thi đã đóng — thông báo cho giáo viên
  Future<void> notifyExamClosed({
    required String teacherId,
    required String examName,
    required String examId,
    required String classId,
    required String className,
    required int submittedCount,
    required int totalCount,
  }) async {
    await _notify(
      toUserId: teacherId,
      type: NotificationType.examClosed,
      title: '🔒 Đề thi đã đóng',
      body: '"$examName" lớp "$className" đã hết hạn. '
            'Đã nộp: $submittedCount/$totalCount học sinh.',
      data: {
        'examId': examId,
        'classId': classId,
        'examName': examName,
        'className': className,
        'submittedCount': submittedCount,
        'totalCount': totalCount,
      },
    );
  }
 
  // Đề sắp đóng — nhắc giáo viên (trước 1h)
  Future<void> notifyExamClosingSoon({
    required String teacherId,
    required String examName,
    required String examId,
    required String classId,
    required String className,
    required int submittedCount,
    required int totalCount,
    required DateTime closeAt,
  }) async {
    final closeStr =
        '${closeAt.hour.toString().padLeft(2, '0')}:'
        '${closeAt.minute.toString().padLeft(2, '0')}';
 
    await _notify(
      toUserId: teacherId,
      type: NotificationType.examClosingSoon,
      title: '⚠️ Đề thi sắp đóng',
      body: '"$examName" lớp "$className" đóng lúc $closeStr hôm nay. '
            'Đã nộp: $submittedCount/$totalCount.',
      data: {
        'examId': examId,
        'classId': classId,
        'examName': examName,
        'className': className,
        'submittedCount': submittedCount,
        'totalCount': totalCount,
        'closeAt': closeAt.toIso8601String(),
      },
    );
  } 
  
}




