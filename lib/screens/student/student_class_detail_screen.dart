import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../controllers/exam_controller.dart';
import '../../controllers/submission_controller.dart';
import '../../data/models/exam_model.dart';
import '../../data/models/submission_model.dart';
import 'exam_take_screen.dart';

class StudentClassDetailScreen extends StatefulWidget {
  final String classId;
  final String className;
  final String teacherName;
  final String? code;

  const StudentClassDetailScreen({
    super.key,
    required this.classId,
    required this.className,
    required this.teacherName,
    this.code,
  });

  @override
  State<StudentClassDetailScreen> createState() =>
      _StudentClassDetailScreenState();
}

class _StudentClassDetailScreenState extends State<StudentClassDetailScreen> {
  final examController = ExamController();
  final submissionController = SubmissionController();
  int _selectedTab = 0; // 0: Tất cả, 1: Chưa làm, 2: Đã làm

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                child: Column(
                  children: [
                    _buildDynamicStats(),
                    const SizedBox(height: 24),
                    _buildFilterTabs(),
                    const SizedBox(height: 20),
                    _buildExamListWithSubmissions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.textDark),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  widget.className,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  "${widget.teacherName} • Mã: ${widget.code ?? 'Không có'}",
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textLight),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // ── Stats từ dữ liệu thật ─────────────────────────────────────────────────
  Widget _buildDynamicStats() {
    return StreamBuilder<List<ExamModel>>(
      stream: examController.streamAssignedExamsForStudent(widget.classId),
      builder: (context, examSnap) {
        return StreamBuilder<Map<String, SubmissionModel>>(
          stream: submissionController
              .streamMySubmissionsForClass(widget.classId),
          builder: (context, subSnap) {
            final exams = examSnap.data ?? [];
            final submissions = subSnap.data ?? {};
            final now = DateTime.now();

            final done = submissions.length;
            final total = exams.length;
            final pending = total - done;

            // Điểm trung bình
            double avg = 0;
            if (submissions.isNotEmpty) {
              avg = submissions.values
                      .map((s) => s.score)
                      .reduce((a, b) => a + b) /
                  submissions.length;
            }

            return Row(
              children: [
                _statCard(Icons.task_alt_rounded, "Đã làm",
                    '$done', AppColors.primary),
                const SizedBox(width: 12),
                _statCard(Icons.pending_actions_rounded, "Chưa làm",
                    '$pending', Colors.orange),
                const SizedBox(width: 12),
                _statCard(Icons.star_rounded, "Điểm TB",
                    submissions.isEmpty ? '—' : avg.toStringAsFixed(1),
                    AppColors.success),
              ],
            );
          },
        );
      },
    );
  }

  Widget _statCard(
      IconData icon, String label, String value, Color iconColor) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLight)),
            Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
          ],
        ),
      ),
    );
  }

  // ── Tabs ──────────────────────────────────────────────────────────────────
  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterTab("Tất cả", 0),
          const SizedBox(width: 8),
          _filterTab("Chưa làm", 1),
          const SizedBox(width: 8),
          _filterTab("Đã làm", 2),
        ],
      ),
    );
  }

  Widget _filterTab(String title, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color:
                isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textMedium,
          ),
        ),
      ),
    );
  }

  // ── Exam list kết hợp submission ─────────────────────────────────────────
  Widget _buildExamListWithSubmissions() {
    return StreamBuilder<List<ExamModel>>(
      stream: examController.streamAssignedExamsForStudent(widget.classId),
      builder: (context, examSnap) {
        if (examSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (examSnap.hasError) {
          return Center(
            child: Text('Lỗi tải đề thi: ${examSnap.error}',
                style: const TextStyle(color: Colors.red)),
          );
        }

        final exams = examSnap.data ?? [];
        if (exams.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.assignment_outlined,
                      size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Chưa có đề thi nào được giao',
                      style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          );
        }

        return StreamBuilder<Map<String, SubmissionModel>>(
          stream: submissionController
              .streamMySubmissionsForClass(widget.classId),
          builder: (context, subSnap) {
            final submissions = subSnap.data ?? {};
            final filtered = _filterExams(exams, submissions);

            if (filtered.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    _selectedTab == 1
                        ? 'Bạn đã làm tất cả các bài!'
                        : 'Chưa có bài nào được nộp',
                    style: const TextStyle(
                        fontSize: 15, color: AppColors.textMedium),
                  ),
                ),
              );
            }

            return Column(
              children: filtered
                  .map((exam) => _examCard(exam, submissions[exam.id]))
                  .toList(),
            );
          },
        );
      },
    );
  }

  List<ExamModel> _filterExams(
      List<ExamModel> exams, Map<String, SubmissionModel> submissions) {
    switch (_selectedTab) {
      case 1: // Chưa làm
        return exams.where((e) => !submissions.containsKey(e.id)).toList();
      case 2: // Đã làm
        return exams.where((e) => submissions.containsKey(e.id)).toList();
      default:
        return exams;
    }
  }

  // ── Exam card ─────────────────────────────────────────────────────────────
  Widget _examCard(ExamModel exam, SubmissionModel? submission) {
    final assignment = exam.assignments.firstWhere(
      (a) => a.classId == widget.classId,
      orElse: () => exam.assignments.first,
    );

    final now = DateTime.now();
    final isOverdue = assignment.closeAt.isBefore(now);
    final isOpen = assignment.openAt.isBefore(now) && !isOverdue;
    final isUrgent = isOpen &&
        assignment.closeAt.isBefore(now.add(const Duration(days: 2)));
    final isCompleted = submission != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xFFF0FDF4)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFFD1FAE5)
              : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          // Row trên
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.success.withOpacity(0.1)
                      : isUrgent
                          ? Colors.orange.withOpacity(0.1)
                          : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.description_rounded,
                  color: isCompleted
                      ? AppColors.success
                      : isUrgent
                          ? Colors.orange
                          : AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${exam.questions.length} câu • ${assignment.durationMinutes} phút",
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
              // Badge trạng thái
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    submission.score.toStringAsFixed(1),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                      fontSize: 14,
                    ),
                  ),
                )
              else if (isUrgent)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Sắp hết hạn',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.red),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Row dưới
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Thông tin thời hạn
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: isOverdue
                            ? Colors.red
                            : AppColors.textLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOverdue
                            ? 'Hết hạn ${_formatDate(assignment.closeAt)}'
                            : 'Hạn: ${_formatDate(assignment.closeAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverdue
                              ? Colors.red
                              : AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                  if (isCompleted) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.check_rounded,
                            size: 13, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text(
                          '${submission.correctCount}/${submission.totalCount} câu đúng',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.success),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              // Nút hành động
              _buildActionButton(exam, assignment, isCompleted,
                  isOverdue, isOpen, isUrgent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    ExamModel exam,
    ExamAssignment assignment,
    bool isCompleted,
    bool isOverdue,
    bool isOpen,
    bool isUrgent,
  ) {
    if (isCompleted) {
      return Row(
        children: [
          const Icon(Icons.task_alt_rounded,
              color: AppColors.success, size: 18),
          const SizedBox(width: 4),
          const Text('Đã nộp',
              style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ],
      );
    }

    if (isOverdue) {
      return Row(
        children: [
          const Icon(Icons.lock_clock_rounded,
              color: Colors.grey, size: 18),
          const SizedBox(width: 4),
          const Text('Đã hết hạn',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      );
    }

    if (!isOpen) {
      final now = DateTime.now();
      final diff = assignment.openAt.difference(now);
      final days = diff.inDays;
      return Text(
        days > 0 ? 'Mở sau $days ngày' : 'Sắp mở',
        style: const TextStyle(
            color: AppColors.textLight, fontSize: 13),
      );
    }

    // Có thể làm bài
    return ElevatedButton(
      onPressed: () => _startExam(exam),
      style: ElevatedButton.styleFrom(
        backgroundColor: isUrgent ? Colors.orange : AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30)),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: Text(
        isUrgent ? 'Làm ngay' : 'Làm bài',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _startExam(ExamModel exam) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ExamTakeScreen(
          exam: exam,
          classId: widget.classId,
        ),
      ),
    );
    // result == true nghĩa là đã nộp bài → stream tự cập nhật
    if (result == true) {
      setState(() {}); // trigger rebuild để cập nhật UI ngay
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}