import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/common/custom_button_nav_student.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/class_controller.dart';
import '../../controllers/exam_controller.dart';
import '../../controllers/submission_controller.dart';
import '../../data/models/exam_model.dart';
import '../../data/models/submission_model.dart';
import '../notification/notification_screen.dart';
import 'list_exam.dart';
import 'exam_review_screen.dart'; // ← MỚI
import 'exam_take_screen.dart';
import '../../widgets/common/notification_badge.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  String studentName = '';
  final classController = ClassController();
  final examController = ExamController();
  final submissionController = SubmissionController();

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final name = await AuthController().getUserName();
    if (mounted) setState(() => studentName = name ?? 'Học sinh');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRealStats(),
                    const SizedBox(height: 32),
                    _buildRecentExams(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavSt(currentIndex: 0),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: ClipOval(
                      child: Container(
                        color: const Color(0xFFE2E8F0),
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppColors.textHint,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Xin chào,',
                    style: TextStyle(fontSize: 13, color: AppColors.textMedium),
                  ),
                  Text(
                    studentName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          NotificationBadge(
            iconColor: AppColors.textMedium,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealStats() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: classController.streamStudentClasses(),
      builder: (context, classSnap) {
        final classes = classSnap.data ?? [];
        final classIds = classes.map((c) => c['classId'] as String).toList();

        if (classIds.isEmpty) {
          return _statsRow(pending: 0, newToday: 0, done: 0);
        }

        return StreamBuilder<Map<String, SubmissionModel>>(
          stream: submissionController.streamMySubmissionsForClass(
            classIds.isNotEmpty ? classIds.first : '',
          ),
          builder: (context, subSnap) {
            final submissions = subSnap.data ?? {};

            return FutureBuilder<_HomeStats>(
              future: _computeStats(classIds, submissions),
              builder: (context, statSnap) {
                final stats =
                    statSnap.data ??
                    _HomeStats(pending: 0, newToday: 0, done: 0);
                return _statsRow(
                  pending: stats.pending,
                  newToday: stats.newToday,
                  done: stats.done,
                );
              },
            );
          },
        );
      },
    );
  }

  Future<_HomeStats> _computeStats(
    List<String> classIds,
    Map<String, SubmissionModel> knownSubmissions,
  ) async {
    int totalPending = 0;
    int totalNewToday = 0;
    int totalDone = knownSubmissions.length;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    for (final classId in classIds) {
      try {
        final exams = await examController
            .streamAssignedExamsForStudent(classId)
            .first;

        for (final exam in exams) {
          final assignment = exam.assignments.firstWhere(
            (a) => a.classId == classId,
            orElse: () => exam.assignments.first,
          );
          final isDone = knownSubmissions.containsKey(exam.id);
          final isOpen =
              assignment.openAt.isBefore(now) &&
              assignment.closeAt.isAfter(now);

          if (!isDone && isOpen) totalPending++;

          final assignedAt =
              DateTime.tryParse(assignment.assignedAt) ?? DateTime(2000);
          if (assignedAt.isAfter(todayStart)) totalNewToday++;
        }
      } catch (_) {}
    }

    return _HomeStats(
      pending: totalPending,
      newToday: totalNewToday,
      done: totalDone,
    );
  }

  Widget _statsRow({
    required int pending,
    required int newToday,
    required int done,
  }) {
    final items = [
      {
        'count': '$pending',
        'label': 'Chưa làm',
        'color': const Color(0xFFFF9800),
      },
      {
        'count': '$newToday',
        'label': 'Mới hôm nay',
        'color': const Color(0xFF007BFF),
      },
      {
        'count': '$done',
        'label': 'Hoàn thành',
        'color': const Color(0xFF10B981),
      },
    ];

    return Row(
      children: items.map((stat) {
        final isHighlighted = stat['label'] == 'Mới hôm nay';
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: isHighlighted
                  ? Border.all(color: AppColors.primary, width: 2)
                  : Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  stat['count'] as String,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: stat['color'] as Color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  stat['label'] as String,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentExams() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: classController.streamStudentClasses(),
      builder: (context, classSnap) {
        final classes = classSnap.data ?? [];
        if (classes.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Đề thi của bạn',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ListExamsScreen(),
                    ),
                  ),
                  child: const Text(
                    'Xem tất cả >',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...classes
                .take(3)
                .map(
                  (cls) => _buildClassExams(
                    cls['classId'] as String,
                    cls['name'] as String,
                  ),
                ),
          ],
        );
      },
    );
  }

  Widget _buildClassExams(String classId, String className) {
    return StreamBuilder<List<ExamModel>>(
      stream: examController.streamAssignedExamsForStudent(classId),
      builder: (context, snap) {
        final exams = snap.data ?? [];
        if (exams.isEmpty) return const SizedBox.shrink();

        return StreamBuilder<Map<String, SubmissionModel>>(
          stream: submissionController.streamMySubmissionsForClass(classId),
          builder: (context, subSnap) {
            final submissions = subSnap.data ?? {};
            final now = DateTime.now();

            final displayExams = exams.take(5).toList();

            return Column(
              children: displayExams.map((exam) {
                final sub = submissions[exam.id];
                final assignment = exam.assignments.firstWhere(
                  (a) => a.classId == classId,
                  orElse: () => exam.assignments.first,
                );
                final isOverdue = assignment.closeAt.isBefore(now);
                final isCompleted = sub != null;

                return _buildHomeExamCard(
                  exam: exam,
                  classId: classId,           // ← MỚI
                  className: className,
                  assignment: assignment,     // ← MỚI
                  submission: sub,
                  isOverdue: isOverdue,
                  isCompleted: isCompleted,
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildHomeExamCard({
    required ExamModel exam,
    required String classId,            // ← MỚI
    required String className,
    required ExamAssignment assignment, // ← MỚI
    required SubmissionModel? submission,
    required bool isOverdue,
    required bool isCompleted,
  }) {
    if (isCompleted && submission != null) {
      final canReview = assignment.showAnswerAfterSubmit; // ← MỚI

      Widget card = Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD1FAE5)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                color: Color(0xFF10B981),
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          exam.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        submission.score.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _infoItem(Icons.groups_rounded, className),
                      const SizedBox(width: 16),
                      // ← MỚI: hint tap nếu được xem đáp án
                      if (canReview) ...[
                        const Spacer(),
                        const Icon(Icons.visibility_rounded,
                            size: 13, color: AppColors.primary),
                        const SizedBox(width: 4),
                        const Text(
                          'Xem đáp án',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(width: 16),
                        Text(
                          _getGradeLabel(submission.score),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      // ← MỚI: bọc trong GestureDetector nếu được xem đáp án
      if (canReview) {
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExamReviewScreen(
                exam: exam,
                classId: classId,
                submission: submission,
              ),
            ),
          ),
          child: card,
        );
      }
      return card;
    }

    // Card chưa làm / hết hạn
    final now = DateTime.now();
    final isOpen = assignment.openAt.isBefore(now) && !isOverdue;
    final badgeText = isOverdue ? 'Hết hạn' : 'Chưa làm';
    final badgeColor = isOverdue ? Colors.grey : const Color(0xFFFF9800);

    final card = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: (isOverdue ? Colors.grey : const Color(0xFFFF9800))
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.description_rounded,
              color: isOverdue ? Colors.grey : const Color(0xFFFF9800),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        exam.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _infoItem(Icons.groups_rounded, className),
                    const SizedBox(width: 16),
                    _infoItem(
                      Icons.description_rounded,
                      '${exam.questions.length} câu',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Chỉ cho tap vào nếu đề đang mở (chưa hết hạn, đã đến giờ)
    if (isOpen) {
      return GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExamTakeScreen(
              exam: exam,
              classId: classId,
            ),
          ),
        ),
        child: card,
      );
    }
    return card;
  }

  Widget _infoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMedium),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 13, color: AppColors.textMedium),
        ),
      ],
    );
  }

  String _getGradeLabel(double score) {
    if (score >= 9) return 'Xuất sắc';
    if (score >= 8) return 'Giỏi';
    if (score >= 6.5) return 'Khá';
    if (score >= 5) return 'Trung bình';
    return 'Yếu';
  }
}

class _HomeStats {
  final int pending;
  final int newToday;
  final int done;
  const _HomeStats({
    required this.pending,
    required this.newToday,
    required this.done,
  });
}