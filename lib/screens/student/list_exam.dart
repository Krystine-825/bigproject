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
  final classController      = ClassController();
  final examController       = ExamController();
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
          case 0: _filter = 'all';     break;
          case 1: _filter = 'pending'; break;
          case 2: _filter = 'done';    break;
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark),
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
          // Chặn lỗi
          if (classSnap.hasError) {
            return _buildEmpty('Lỗi tải dữ liệu.');
          }

          // Chặn Null để tận dụng Cache, tránh chớp màn hình
          if (!classSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Ép kiểu an toàn bằng dấu 
          final classes = classSnap.data!;

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
        if (examSnap.hasError) return const SizedBox.shrink();
        if (!examSnap.hasData) return const SizedBox.shrink(); // Đợi Cache load

        final allExams = examSnap.data!;
        if (allExams.isEmpty) return const SizedBox.shrink();

        return StreamBuilder<Map<String, SubmissionModel>>(
          stream: submissionController.streamMySubmissionsForClass(classId),
          builder: (context, subSnap) {
            if (subSnap.hasError) return const SizedBox.shrink();
            if (!subSnap.hasData) return const SizedBox.shrink(); // Đợi Cache load

            final submissions = subSnap.data!;
            final now = DateTime.now();

            final exams = allExams.where((exam) {
              final assignment = exam.assignments.firstWhere(
                (a) => a.classId == classId,
                orElse: () => exam.assignments.first,
              );
              final hasBestSubmission = submissions.containsKey(exam.id);
              final isOverdue        = assignment.closeAt.isBefore(now);
              
              // Lọc theo tab:
              switch (_filter) {
                case 'pending':
                  return !hasBestSubmission && !isOverdue;
                case 'done':
                  return hasBestSubmission;
                case 'overdue':
                  return !hasBestSubmission && isOverdue;
                default:
                  return true;
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
                  final isOverdue   = assignment.closeAt.isBefore(now);
                  final isCompleted = sub != null;

                  return _ExamCard(
                    key: ValueKey('${exam.id}_$classId'),
                    exam: exam,
                    classId: classId,
                    className: className,
                    bestSubmission: sub,
                    assignment: assignment,
                    isOverdue: isOverdue,
                    isCompleted: isCompleted,
                    submissionController: submissionController,
                    onStartExam: () => _goToExam(exam, classId),
                    onReview: () => _openReview(exam, classId, sub!),
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

  /// Vào màn hình làm bài — KHÔNG cần kiểm tra lượt ở đây vì _ExamCard
  /// đã kiểm tra async trước khi gọi callback này.
  void _goToExam(ExamModel exam, String classId) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ExamTakeScreen(exam: exam, classId: classId)),
    );
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
}

class _ExamCard extends StatefulWidget {
  final ExamModel exam;
  final String classId;
  final String className;
  final SubmissionModel? bestSubmission;
  final ExamAssignment assignment;
  final bool isOverdue;
  final bool isCompleted;
  final SubmissionController submissionController;
  final VoidCallback onStartExam;
  final VoidCallback onReview;

  const _ExamCard({
    super.key,
    required this.exam,
    required this.classId,
    required this.className,
    required this.bestSubmission,
    required this.assignment,
    required this.isOverdue,
    required this.isCompleted,
    required this.submissionController,
    required this.onStartExam,
    required this.onReview,
  });

  @override
  State<_ExamCard> createState() => _ExamCardState();
}

class _ExamCardState extends State<_ExamCard> {
  // Cache attemptCount để tránh gọi lại mỗi lần rebuild
  int? _attemptCount;
  bool _loadingAttempt = true;

  @override
  void initState() {
    super.initState();
    _loadAttemptCount();
  }

  Future<void> _loadAttemptCount() async {
    try {
      final count = await widget.submissionController.getAttemptCount(
        widget.exam.id,
        widget.classId,
      );
      if (mounted) {
        setState(() {
          _attemptCount   = count;
          _loadingAttempt = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingAttempt = false);
    }
  }

  // Học sinh còn lượt làm nếu: chưa hết hạn VÀ số lần làm < maxAttempts
  bool get _hasAttemptsLeft {
    if (widget.isOverdue) return false;
    final count      = _attemptCount ?? 0;
    final maxAttempts = widget.assignment.maxAttempts;
    return count < maxAttempts;
  }

  // Số lượt còn lại
  int get _attemptsLeft {
    final count      = _attemptCount ?? 0;
    final maxAttempts = widget.assignment.maxAttempts;
    return (maxAttempts - count).clamp(0, maxAttempts);
  }

  /// Kiểm tra trước khi cho vào thi (gọi lại Firestore để tránh race condition)
  Future<void> _handleTap(BuildContext context) async {
    // Luôn re-fetch để tránh race condition (user mở 2 tab, etc.)
    final latestCount = await widget.submissionController.getAttemptCount(
      widget.exam.id,
      widget.classId,
    );
    if (!mounted) return;

    if (latestCount >= widget.assignment.maxAttempts) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.assignment.maxAttempts == 1
                ? 'Bạn đã nộp bài. Đề này chỉ được làm 1 lần.'
                : 'Bạn đã dùng hết ${widget.assignment.maxAttempts} lượt làm bài.',
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    widget.onStartExam();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompleted && widget.bestSubmission != null) {
      return _buildCompletedCard(context);
    }
    return _buildPendingCard(context);
  }

  Widget _buildCompletedCard(BuildContext context) {
    final sub       = widget.bestSubmission!;
    final canReview = widget.assignment.showAnswerAfterSubmit;
    final maxAttempts = widget.assignment.maxAttempts;

    // Có thể làm lại: còn lượt VÀ chưa hết hạn
    final canRetry = !_loadingAttempt && _hasAttemptsLeft;

    final card = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD1FAE5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon
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
                    // Tên đề + điểm
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.exam.name,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${sub.score.toStringAsFixed(1)} đ',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Info row
                    Row(
                      children: [
                        _infoItem(Icons.groups_rounded, widget.className),
                        const SizedBox(width: 14),
                        _infoItem(Icons.description_rounded,
                            '${widget.exam.questions.length} câu'),
                        const Spacer(),
                        // Số lần làm / tổng lượt
                        if (maxAttempts > 1)
                          _loadingAttempt
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 1.5))
                              : _infoItem(
                                  Icons.repeat_rounded,
                                  'Lần ${_attemptCount ?? sub.attemptNumber}/$maxAttempts',
                                ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Hàng hành động: Xem đáp án + Làm lại 
          if (canReview || canRetry) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFD1FAE5)),
            const SizedBox(height: 12),
            Row(
              children: [
                // Nút "Xem đáp án"
                if (canReview) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onReview,
                      icon: const Icon(Icons.visibility_rounded, size: 16),
                      label: const Text('Xem đáp án',
                          style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  if (canRetry) const SizedBox(width: 10),
                ],
                // Nút "Làm lại"
                if (canRetry)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleTap(context),
                      icon: const Icon(Icons.replay_rounded, size: 16),
                      label: Text(
                        'Làm lại (còn $_attemptsLeft lượt)',
                        style: const TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
              ],
            ),
          ] else if (!canReview) ...[
            // Không có nút nào → hiển thị xếp loại nhỏ
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _getGradeLabel(sub.score),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981)),
              ),
            ),
          ],
        ],
      ),
    );

    // Toàn bộ card vẫn tap được để vào review (nếu cho phép)
    if (canReview) {
      return GestureDetector(
        onTap: widget.onReview,
        child: card,
      );
    }
    return card;
  }

  // Card chưa làm / hết hạn 
  Widget _buildPendingCard(BuildContext context) {
    final isOverdue   = widget.isOverdue;
    final badgeText   = isOverdue ? 'Hết hạn' : 'Chưa làm';
    final badgeColor  = isOverdue ? Colors.grey : const Color(0xFFFF9800);
    final iconColor   = isOverdue ? Colors.grey : const Color(0xFFFF9800);
    final closeAt     = widget.assignment.closeAt;
    final remaining   = closeAt.difference(DateTime.now());

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
                        widget.exam.name,
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
                    _infoItem(Icons.groups_rounded, widget.className),
                    const SizedBox(width: 14),
                    _infoItem(Icons.description_rounded,
                        '${widget.exam.questions.length} câu'),
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
        onTap: () => _handleTap(context),
        child: card,
      );
    }
    return card;
  }

  Widget _infoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.textMedium),
        const SizedBox(width: 5),
        Text(text,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textMedium)),
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