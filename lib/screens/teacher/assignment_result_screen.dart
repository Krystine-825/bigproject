import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../controllers/class_controller.dart';
import '../../controllers/submission_controller.dart';
import '../../data/models/class_member_model.dart';
import '../../data/models/submission_model.dart';

/// Màn chi tiết kết quả 1 bài tập — danh sách điểm từng học sinh.
class AssignmentResultScreen extends StatelessWidget {
  final String examId;
  final String classId;
  final String assignmentTitle;
  final int totalStudents;

  const AssignmentResultScreen({
    super.key,
    required this.examId,
    required this.classId,
    required this.assignmentTitle,
    required this.totalStudents,
  });

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[parts.length - 2][0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final classCtrl = ClassController();
    final subCtrl = SubmissionController();

    // Kết hợp 2 stream: danh sách thành viên + danh sách bài nộp
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: StreamBuilder<List<ClassMemberModel>>(
                stream: classCtrl.streamMembers(classId),
                builder: (context, memberSnap) {
                  return StreamBuilder<List<SubmissionModel>>(
                    stream: subCtrl.streamSubmissionsForExamAndClass(
                      examId: examId,
                      classId: classId,
                    ),
                    builder: (context, subSnap) {
                      final isLoading =
                          memberSnap.connectionState ==
                                  ConnectionState.waiting ||
                              subSnap.connectionState ==
                                  ConnectionState.waiting;

                      if (isLoading) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      if (memberSnap.hasError || subSnap.hasError) {
                        return Center(
                          child: Text(
                            'Lỗi tải dữ liệu',
                            style: const TextStyle(
                                color: AppColors.textMedium),
                          ),
                        );
                      }

                      final members = memberSnap.data ?? [];
                      final submissions = subSnap.data ?? [];

                      // Map: studentId → SubmissionModel
                      final subMap = {
                        for (final s in submissions) s.studentId: s
                      };

                      final submitted = submissions.length;
                      final avgScore = submitted > 0
                          ? submissions.fold<double>(
                                  0, (s, m) => s + m.score) /
                              submitted
                          : null;
                      final notSubmitted = members.length - submitted;
                      final submitPct = members.isNotEmpty
                          ? submitted / members.length
                          : 0.0;

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(
                            16, 16, 16, 100),
                        children: [
                          _buildStatCards(
                            submitted: submitted,
                            notSubmitted:
                                notSubmitted.clamp(0, members.length),
                            avgScore: avgScore,
                            submitPct: submitPct,
                            total: members.length,
                          ),
                          const SizedBox(height: 20),
                          _buildListHeader(),
                          const SizedBox(height: 12),
                          ...members.asMap().entries.map(
                                (e) => _buildStudentRow(
                                  member: e.value,
                                  index: e.key,
                                  submission: subMap[e.value.studentId],
                                ),
                              ),
                          // Học sinh có submission nhưng không còn trong class_members
                          // (đã bị kick) — vẫn hiện điểm nhưng tên là email/id
                          ...submissions
                              .where((s) => !members.any(
                                  (m) => m.studentId == s.studentId))
                              .map(
                                (s) => _buildOrphanRow(s,
                                    members.length +
                                        submissions.indexOf(s)),
                              ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.textDark,
          ),
          Expanded(
            child: Text(
              assignmentTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ── Stat cards ────────────────────────────────────────────────────────────
  Widget _buildStatCards({
    required int submitted,
    required int notSubmitted,
    required double? avgScore,
    required double submitPct,
    required int total,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Điểm TB
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Điểm trung bình',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      avgScore != null
                          ? avgScore.toStringAsFixed(1)
                          : '—',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 5, left: 4),
                      child: Text(
                        '/ 10',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textMedium),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Đã nộp + Chưa nộp
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _miniStatCard(
                label: 'Đã nộp',
                value: '$submitted/$total',
                color: AppColors.success,
                progress: submitPct.clamp(0.0, 1.0),
              ),
              const SizedBox(height: 10),
              _miniStatCard(
                label: 'Chưa nộp',
                value: '$notSubmitted',
                color: Colors.redAccent,
                progress: (1 - submitPct).clamp(0.0, 1.0),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniStatCard({
    required String label,
    required String value,
    required Color color,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMedium)),
              Text(value,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.bgLight,
              color: color,
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  // ── List header ─────────────────────────────────────────────────────────────
  Widget _buildListHeader() {
    return const Row(
      children: [
        Text(
          'Danh sách học sinh',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  // ── Student row (có trong class_members) ────────────────────────────────────
  Widget _buildStudentRow({
    required ClassMemberModel member,
    required int index,
    required SubmissionModel? submission,
  }) {
    final colorIndex = index % AppColors.avatarBgColors.length;
    final name = member.studentName ?? member.studentEmail ?? 'Học sinh';
    final hasScore = submission != null;

    return Opacity(
      opacity: hasScore ? 1.0 : 0.72,
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
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.avatarBgColors[colorIndex],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _initials(name),
                  style: TextStyle(
                    color: AppColors.avatarTextColors[colorIndex],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Tên + badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: hasScore
                          ? AppColors.successBg
                          : AppColors.bgLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      hasScore ? 'Đã nộp' : 'Chưa nộp',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: hasScore
                            ? AppColors.successMid
                            : AppColors.textMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Điểm
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  hasScore
                      ? '${submission.score.toStringAsFixed(1)}/10'
                      : '—',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: hasScore
                        ? AppColors.primary
                        : AppColors.textHint,
                  ),
                ),
                const Text(
                  'ĐIỂM SỐ',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 0.6,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Row học sinh đã bị kick nhưng có submission ──────────────────────────────
  Widget _buildOrphanRow(SubmissionModel submission, int index) {
    final colorIndex = index % AppColors.avatarBgColors.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.avatarBgColors[colorIndex],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '?',
                style: TextStyle(
                  color: AppColors.avatarTextColors[colorIndex],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  submission.studentId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Đã rời lớp',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${submission.score.toStringAsFixed(1)}/10',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}