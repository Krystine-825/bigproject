import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../controllers/class_controller.dart';
import '../../controllers/exam_controller.dart';
import '../../controllers/submission_controller.dart';
import '../../data/models/exam_model.dart';
import '../../data/models/submission_model.dart';
import 'exam_review_screen.dart';
import 'exam_take_screen.dart';

class ListExamsScreen extends StatefulWidget {
  const ListExamsScreen({super.key});

  @override
  State<ListExamsScreen> createState() => _ListExamsScreenState();
}

class _ListExamsScreenState extends State<ListExamsScreen>
    with SingleTickerProviderStateMixin {
  final classController = ClassController();
  final examController = ExamController();
  final submissionController = SubmissionController();

  late TabController _tabController;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;
      setState(() {
        switch (_tabController.index) {
          case 0: _filter = 'all'; break;
          case 1: _filter = 'pending'; break;
          case 2: _filter = 'done'; break;
          case 3: _filter = 'overdue'; break;
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Đề thi của bạn',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMedium,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: const [
            Tab(text: 'Tất cả'),
            Tab(text: 'Chưa làm'),
            Tab(text: 'Hoàn thành'),
            Tab(text: 'Hết hạn'),
          ],
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: classController.streamStudentClasses(),
        builder: (context, classSnap) {
          if (classSnap.hasError) {
            return _buildEmpty('Lỗi tải dữ liệu.');
          }

          // Firestore tự cache → dùng data trực tiếp
          final classes = classSnap.data ?? [];

          if (classes.isEmpty) {
            return _buildEmpty('Bạn chưa tham gia lớp học nào.');
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: classes.length,
            itemBuilder: (context, i) {
              final cls = classes[i];
              return _buildClassSection(
                classId: cls['classId'] as String,
                className: cls['name'] as String,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildClassSection({
    required String classId,
    required String className,
  }) {
    return StreamBuilder<List<ExamModel>>(
      stream: examController.streamAssignedExamsForStudent(classId),
      builder: (context, examSnap) {
        // Firestore tự cache → dùng data trực tiếp
        final allExams = examSnap.data ?? [];
        if (allExams.isEmpty) return const SizedBox.shrink();

        return StreamBuilder<Map<String, SubmissionModel>>(
          stream: submissionController.streamMySubmissionsForClass(classId),
          builder: (context, subSnap) {
            final submissions = subSnap.data ?? {};
            final now = DateTime.now();

            final exams = allExams.where((exam) {
              final assignment = exam.assignments.firstWhere(
                (a) => a.classId == classId,
                orElse: () => exam.assignments.first,
              );
              final isDone = submissions.containsKey(exam.id);
              final isOverdue = assignment.closeAt.isBefore(now);

              switch (_filter) {
                case 'pending':  return !isDone && !isOverdue;
                case 'done':     return isDone;
                case 'overdue':  return !isDone && isOverdue;
                default:         return true;
              }
            }).toList();

            if (exams.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.groups_rounded,
                                size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              className,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${exams.length} đề',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMedium),
                      ),
                    ],
                  ),
                ),
                ...exams.map((exam) {
                  final sub = submissions[exam.id];
                  final assignment = exam.assignments.firstWhere(
                    (a) => a.classId == classId,
                    orElse: () => exam.assignments.first,
                  );
                  final isOverdue = assignment.closeAt.isBefore(now);
                  final isCompleted = sub != null;

                  return _buildExamCard(
                    exam: exam,
                    classId: classId,
                    className: className,
                    submission: sub,
                    assignment: assignment,
                    isOverdue: isOverdue,
                    isCompleted: isCompleted,
                    closeAt: assignment.closeAt,
                  );
                }),
                const SizedBox(height: 8),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildExamCard({
    required ExamModel exam,
    required String classId,
    required String className,
    required SubmissionModel? submission,
    required ExamAssignment assignment,
    required bool isOverdue,
    required bool isCompleted,
    required DateTime closeAt,
  }) {
    if (isCompleted && submission != null) {
      final canReview = assignment.showAnswerAfterSubmit;

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
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.task_alt_rounded,
                  color: Color(0xFF10B981), size: 28),
            ),
            const SizedBox(width: 14),
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
                              color: AppColors.textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${submission.score.toStringAsFixed(1)} đ',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _infoItem(Icons.groups_rounded, className),
                      const SizedBox(width: 14),
                      _infoItem(Icons.description_rounded,
                          '${exam.questions.length} câu'),
                      const Spacer(),
                      if (canReview)
                        Row(children: const [
                          Icon(Icons.visibility_rounded,
                              size: 13, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text('Xem đáp án',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600)),
                        ])
                      else
                        Text(
                          _getGradeLabel(submission.score),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      if (canReview) {
        return GestureDetector(
          onTap: () => _openReview(exam, classId, submission),
          child: card,
        );
      }
      return card;
    }

    final badgeText = isOverdue ? 'Hết hạn' : 'Chưa làm';
    final badgeColor = isOverdue ? Colors.grey : const Color(0xFFFF9800);
    final iconColor = isOverdue ? Colors.grey : const Color(0xFFFF9800);

    final remaining = closeAt.difference(DateTime.now());
    String remainingText = '';
    if (!isOverdue) {
      if (remaining.inDays > 0) {
        remainingText = 'Còn ${remaining.inDays} ngày';
      } else if (remaining.inHours > 0) {
        remainingText = 'Còn ${remaining.inHours} giờ';
      } else {
        remainingText = 'Còn ${remaining.inMinutes} phút';
      }
    }

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
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child:
                Icon(Icons.description_rounded, color: iconColor, size: 28),
          ),
          const SizedBox(width: 14),
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
                            color: AppColors.textDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: badgeColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _infoItem(Icons.groups_rounded, className),
                    const SizedBox(width: 14),
                    _infoItem(Icons.description_rounded,
                        '${exam.questions.length} câu'),
                    if (remainingText.isNotEmpty) ...[
                      const Spacer(),
                      Text(remainingText,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFFF9800),
                              fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!isOverdue) {
      return GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  ExamTakeScreen(exam: exam, classId: classId)),
        ),
        child: card,
      );
    }
    return card;
  }

  void _openReview(
      ExamModel exam, String classId, SubmissionModel submission) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamReviewScreen(
            exam: exam, classId: classId, submission: submission),
      ),
    );
  }

  Widget _infoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textMedium),
        const SizedBox(width: 5),
        Text(text,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textMedium)),
      ],
    );
  }

  Widget _buildEmpty(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),
        ],
      ),
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