import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/notification_controller.dart';
import '../../core/app_colors.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/exam_model.dart';
import '../../data/services/firestore_service.dart';
import '../teacher/exam_bank_screen.dart';
import '../student/student_class_detail_screen.dart';
import '../student/exam_take_screen.dart';
import '../student/results_screen.dart';

import '../teacher/class_detail_screen.dart';
import '../teacher/assignment_result_screen.dart';
import '../teacher/exam_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ctrl = NotificationController();
  final _firestore = FireStoreService();
  bool _navigating = false; // chặn double-tap

  late final Stream<List<NotificationModel>> stream;

  @override
  void initState() {
    super.initState();
    stream = ctrl.streamMyNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Thông báo',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: Text(
              'Đọc tất cả',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snap.data ?? [];
          if (all.isEmpty) return _emptyState();

          final grouped = _group(all);

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
            itemCount: grouped.length,
            itemBuilder: (context, i) {
              final section = grouped[i];
              final label = section['label'] as String;
              final items = section['items'] as List<NotificationModel>;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(label),
                  ...items.map((n) => _notifTile(n)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _group(List<NotificationModel> items) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final weekStart = todayStart.subtract(const Duration(days: 7));

    final today = <NotificationModel>[];
    final yesterday = <NotificationModel>[];
    final thisWeek = <NotificationModel>[];
    final older = <NotificationModel>[];

    for (final n in items) {
      final dt = DateTime.tryParse(n.createdAt)?.toLocal() ?? now;
      if (dt.isAfter(todayStart)) {
        today.add(n);
      } else if (dt.isAfter(yesterdayStart)) {
        yesterday.add(n);
      } else if (dt.isAfter(weekStart)) {
        thisWeek.add(n);
      } else {
        older.add(n);
      }
    }

    return [
      if (today.isNotEmpty) {'label': 'Hôm nay', 'items': today},
      if (yesterday.isNotEmpty) {'label': 'Hôm qua', 'items': yesterday},
      if (thisWeek.isNotEmpty) {'label': 'Tuần này', 'items': thisWeek},
      if (older.isNotEmpty) {'label': 'Cũ hơn', 'items': older},
    ];
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF94A3B8),
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _notifTile(NotificationModel n) {
    final meta = _meta(n.type);

    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: const Color(0xFFEF4444),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      onDismissed: (_) => ctrl.deleteNotification(n.id),
      child: GestureDetector(
        onTap: () => _onTap(n),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: n.isRead ? Colors.white : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: n.isRead
                  ? const Color(0xFFF1F5F9)
                  : const Color(0xFFBFDBFE),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: meta['bg'] as Color,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    meta['icon'] as IconData,
                    color: meta['color'] as Color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: n.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          if (!n.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        n.body,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _timeAgo(n.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 44,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Không có thông báo nào',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Các thông báo về lớp học và bài thi\nsẽ xuất hiện tại đây.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Future<void> _markAllRead() async {
    await ctrl.markAllAsRead();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đánh dấu tất cả là đã đọc'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _onTap(NotificationModel n) async {
    if (_navigating) return;
    _navigating = true;

    if (!n.isRead) await ctrl.markAsRead(n.id);
    if (!mounted) {
      _navigating = false;
      return;
    }

    await _navigate(n);
    _navigating = false;
  }

  Future<void> _navigate(NotificationModel n) async {
    final data = n.data;
    final classId = (data['classId'] as String?) ?? '';
    final examId = (data['examId'] as String?) ?? '';

    switch (n.type) {
      // Học sinh: tham gia lớp / bị kick → StudentClassDetailScreen
      case NotificationType.classJoined:
      case NotificationType.kickedClass:
        if (classId.isEmpty) break;
        await _pushStudentClassDetail(classId, data);
        break;

      // Giáo viên: HS vào lớp / tạo lớp → ClassDetailScreen
      case NotificationType.studentJoined:
      case NotificationType.classCreated:
        if (classId.isEmpty) break;
        await _pushTeacherClassDetail(classId, data);
        break;

      // Học sinh: đề mới / sắp hết hạn / hết hạn chưa nộp
      // → kiểm tra đã nộp chưa, nếu rồi → xem kết quả, chưa → vào làm bài
      case NotificationType.newAssignment:
      case NotificationType.examDeadline:
      case NotificationType.examExpiredUnsubmitted:
        if (examId.isEmpty || classId.isEmpty) break;
        final hasSubmitted = await _checkHasSubmission(examId, classId);
        if (!mounted) break;
        if (hasSubmitted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StudentResultsScreen()),
          );
        } else {
          await _pushExamTake(examId, classId);
        }
        break;

      // Học sinh: nộp bài thành công → StudentResultsScreen
      case NotificationType.subSuccess:
        if (!mounted) break;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StudentResultsScreen()),
        );
        break;

      // Giáo viên: bài nộp mới / 100% / đề đóng → AssignmentResultScreen
      case NotificationType.subReceived:
      case NotificationType.allSubmitted:
      case NotificationType.examClosed:
        if (examId.isEmpty || classId.isEmpty) break;
        await _pushAssignmentResult(examId, classId, data);
        break;

      // Giáo viên: tạo đề / giao đề / sắp đóng → ExamDetailScreen
      case NotificationType.examCreated:
      case NotificationType.examAssigned:
      case NotificationType.examClosingSoon:
        if (!mounted) break;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExamBankScreen()),
        );
        break;
      // Học sinh: Đề thi bị xóa
      case NotificationType.examDeleted:
        if (!mounted) break;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đề thi này đã bị giáo viên thu hồi hoặc xóa bỏ.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      // Không điều hướng
      case NotificationType.passChanged:
      default:
        break;
    }
  }

  Future<void> _pushStudentClassDetail(
    String classId,
    Map<String, dynamic> data,
  ) async {
    String className = (data['className'] as String?) ?? '';
    String teacherName = '';
    String code = '';

    try {
      final classDoc = await _firestore.getDocument('classes', classId);
      if (classDoc.exists && classDoc.data() != null) {
        final d = classDoc.data()!;
        if (className.isEmpty) className = (d['name'] as String?) ?? '';
        code = (d['code'] as String?) ?? '';
        final teacherId = (d['teacher_id'] as String?) ?? '';
        if (teacherId.isNotEmpty) {
          final teacherDoc = await _firestore.getDocument('users', teacherId);
          teacherName = (teacherDoc.data()?['name'] as String?) ?? '';
        }
      }
    } catch (_) {}

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentClassDetailScreen(
          classId: classId,
          className: className.isNotEmpty ? className : 'Lớp học',
          teacherName: teacherName.isNotEmpty ? teacherName : 'Giáo viên',
          code: code,
        ),
      ),
    );
  }

  Future<void> _pushTeacherClassDetail(
    String classId,
    Map<String, dynamic> data,
  ) async {
    String className = (data['className'] as String?) ?? '';
    String classCode = '';

    try {
      final classDoc = await _firestore.getDocument('classes', classId);
      if (classDoc.exists && classDoc.data() != null) {
        final d = classDoc.data()!;
        if (className.isEmpty) className = (d['name'] as String?) ?? '';
        classCode = (d['code'] as String?) ?? '';
      }
    } catch (_) {}

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClassDetailScreen(
          classId: classId,
          className: className.isNotEmpty ? className : 'Lớp học',
          classCode: classCode,
        ),
      ),
    );
  }

  /// Kiểm tra student hiện tại đã nộp bài cho [examId] chưa.
  /// Dùng FirebaseAuth.instance.currentUser để lấy uid — không cần async.
  Future<bool> _checkHasSubmission(String examId, String classId) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) return false;

      final snap = await _firestore.queryWhere(
        'submissions',
        field: 'exam_id',
        isEqualTo: examId,
        field2: 'student_id',
        isEqualTo2: uid,
      );
      return snap.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _pushExamTake(String examId, String classId) async {
    ExamModel? exam;
    try {
      final doc = await _firestore.getDocument('exams', examId);
      if (doc.exists && doc.data() != null) {
        exam = ExamModel.fromJson(doc.data()!, id: doc.id);
      }
    } catch (_) {}

    if (!mounted || exam == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamTakeScreen(exam: exam!, classId: classId),
      ),
    );
  }

  Future<void> _pushAssignmentResult(
    String examId,
    String classId,
    Map<String, dynamic> data,
  ) async {
    String assignmentTitle = (data['examName'] as String?) ?? '';
    int totalStudents = 0;

    try {
      if (assignmentTitle.isEmpty) {
        final examDoc = await _firestore.getDocument('exams', examId);
        if (examDoc.exists && examDoc.data() != null) {
          final d = examDoc.data()!;
          assignmentTitle = ((d['name'] ?? d['title'] ?? '') as String);
        }
      }
      final memberSnap = await _firestore.queryWhere(
        'class_members',
        field: 'class_id',
        isEqualTo: classId,
      );
      totalStudents = memberSnap.docs
          .where((d) => d.data()['status'] == 'active')
          .length;
    } catch (_) {}

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssignmentResultScreen(
          examId: examId,
          classId: classId,
          assignmentTitle: assignmentTitle.isNotEmpty
              ? assignmentTitle
              : 'Bài kiểm tra',
          totalStudents: totalStudents,
        ),
      ),
    );
  }

  String _timeAgo(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return 'Vừa xong';
      if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
      if (diff.inHours < 24) return '${diff.inHours} giờ trước';
      if (diff.inDays < 7) return '${diff.inDays} ngày trước';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  Map<String, dynamic> _meta(String type) {
    switch (type) {
      case NotificationType.classJoined:
      case NotificationType.classCreated:
        return {
          'icon': Icons.school_rounded,
          'bg': const Color(0xFFF0FDF4),
          'color': const Color(0xFF22C55E),
        };
      
      case NotificationType.subSuccess:
      case NotificationType.allSubmitted:
        return {
          'icon': Icons.task_alt_rounded,
          'bg': const Color(0xFFF0FDF4),
          'color': const Color(0xFF22C55E),
        };

      case NotificationType.newAssignment:
      case NotificationType.examAssigned:
      case NotificationType.examCreated:
        return {
          'icon': Icons.description_rounded,
          'bg': const Color(0xFFEFF6FF),
          'color': AppColors.primary,
        };

      case NotificationType.studentJoined:
      case NotificationType.subReceived:
        return {
          'icon': Icons.group_add_rounded,
          'bg': const Color(0xFFEFF6FF),
          'color': AppColors.primary,
        };

      case NotificationType.examDeadline:
      case NotificationType.examClosingSoon:
        return {
          'icon': Icons.access_time_rounded,
          'bg': const Color(0xFFFFF7ED),
          'color': const Color(0xFFF97316),
        };

      case NotificationType.kickedClass:
        return {
          'icon': Icons.remove_circle_outline_rounded,
          'bg': const Color(0xFFFFF1F2),
          'color': const Color(0xFFEF4444),
        };

      case NotificationType.examExpiredUnsubmitted:
        return {
          'icon': Icons.timer_off_rounded,
          'bg': const Color(0xFFF8FAFC),
          'color': const Color(0xFF94A3B8),
        };

      case NotificationType.examClosed:
        return {
          'icon': Icons.lock_clock_rounded,
          'bg': const Color(0xFFF8FAFC),
          'color': const Color(0xFF64748B),
        };

      case NotificationType.passChanged:
        return {
          'icon': Icons.lock_rounded,
          'bg': const Color(0xFFF5F3FF),
          'color': const Color(0xFF7C3AED),
        };
      case NotificationType.examDeleted:
        return {
          'icon': Icons.delete_forever_rounded,
          'bg': const Color(0xFFFFF1F2),
          'color': const Color(0xFFEF4444),
        };

      default:
        return {
          'icon': Icons.notifications_rounded,
          'bg': const Color(0xFFEFF6FF),
          'color': AppColors.primary,
        };
    }
  }
}