import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../controllers/exam_controller.dart';
import '../../controllers/submission_controller.dart';
import '../../data/models/exam_model.dart';
import '../../data/models/submission_model.dart';
import 'assignment_result_screen.dart';

/// Tab "Kết quả" bên trong ClassDetailScreen.
/// Nhận [classId] và [totalStudents] từ màn cha.
class ClassResultsTab extends StatelessWidget {
  final String classId;
  final int totalStudents;

  const ClassResultsTab({
    super.key,
    required this.classId,
    required this.totalStudents,
  });

  @override
  Widget build(BuildContext context) {
    final examController = ExamController();

    return StreamBuilder<List<ExamModel>>(
      stream: examController.streamMyExams(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: Colors.redAccent),
                const SizedBox(height: 12),
                Text('Lỗi: ${snap.error}',
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: AppColors.textMedium)),
              ],
            ),
          );
        }

        // Chỉ lấy đề đã giao cho lớp này
        final exams = (snap.data ?? [])
            .where((e) =>
                e.assignments.any((a) => a.classId == classId))
            .toList();

        if (exams.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bar_chart_rounded,
                    size: 56, color: AppColors.textHint),
                SizedBox(height: 12),
                Text('Chưa có bài tập nào',
                    style: TextStyle(
                        fontSize: 15, color: AppColors.textMedium)),
                SizedBox(height: 6),
                Text('Giao đề thi để xem kết quả học sinh',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textHint)),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'Danh sách bài tập',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
            ...exams.map(
              (exam) => _ExamCard(
                exam: exam,
                classId: classId,
                totalStudents: totalStudents,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Card từng đề thi ─────────────────────────────────────────────────────────
class _ExamCard extends StatelessWidget {
  final ExamModel exam;
  final String classId;
  final int totalStudents;

  const _ExamCard({
    required this.exam,
    required this.classId,
    required this.totalStudents,
  });

  // Pool icon xoay vòng theo hashCode examId
  static const _iconPool = [
    (Icons.description_rounded,  Color(0xFFDBEAFE), Color(0xFF2563EB)),
    (Icons.edit_document,         Color(0xFFEDE9FE), Color(0xFF7C3AED)),
    (Icons.menu_book_rounded,     Color(0xFFD1FAE5), Color(0xFF059669)),
    (Icons.history_edu_rounded,   Color(0xFFFFE4E6), Color(0xFFE11D48)),
    (Icons.quiz_rounded,          Color(0xFFFEF3C7), Color(0xFFD97706)),
  ];

  @override
  Widget build(BuildContext context) {
    final submissionCtrl = SubmissionController();
    final iconData = _iconPool[exam.id.hashCode.abs() % _iconPool.length];

    // assignment tương ứng lớp này
    final assignment = exam.assignments.firstWhere(
      (a) => a.classId == classId,
      orElse: () => exam.assignments.first,
    );

    return StreamBuilder<List<SubmissionModel>>(
      stream: submissionCtrl.streamSubmissionsForExamAndClass(
        examId: exam.id,
        classId: classId,
      ),
      builder: (context, subSnap) {
        final submissions = subSnap.data ?? [];
        final submitted = submissions.length;
        final avgScore = submitted > 0
            ? submissions.fold<double>(0, (s, m) => s + m.score) /
                submitted
            : null;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AssignmentResultScreen(
                examId: exam.id,
                classId: classId,
                assignmentTitle: exam.name,
                totalStudents: totalStudents,
              ),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconData.$2,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData.$1, color: iconData.$3, size: 22),
                ),
                const SizedBox(width: 12),

                // Tiêu đề + stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        avgScore != null
                            ? '$submitted/$totalStudents nộp  ·  TB ${avgScore.toStringAsFixed(1)}'
                            : '$submitted/$totalStudents nộp',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMedium),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Badge + chevron
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StatusBadge(
                      assignment: assignment,
                      submitted: submitted,
                      total: totalStudents,
                    ),
                    const SizedBox(height: 4),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textHint, size: 20),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Badge trạng thái tính theo thời gian thật ───────────────────────────────
class _StatusBadge extends StatelessWidget {
  final ExamAssignment assignment;
  final int submitted;
  final int total;

  const _StatusBadge({
    required this.assignment,
    required this.submitted,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    late String label;
    late Color bg;
    late Color fg;

    if (now.isBefore(assignment.openAt)) {
      label = 'Mới giao';
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFD97706);
    } else if (now.isAfter(assignment.closeAt)) {
      label = 'Hết hạn';
      bg = const Color(0xFFFFE4E6);
      fg = const Color(0xFFE11D48);
    } else if (submitted == 0) {
      label = 'Đang mở';
      bg = AppColors.primaryLight;
      fg = AppColors.primary;
    } else {
      final pct =
          total > 0 ? (submitted / total * 100).round() : 0;
      label = '$pct%';
      bg = AppColors.successBg;
      fg = AppColors.successMid;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}