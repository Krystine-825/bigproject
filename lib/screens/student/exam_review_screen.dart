import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../data/models/exam_model.dart';
import '../../data/models/question_model.dart';
import '../../data/models/submission_model.dart';


class ExamReviewScreen extends StatefulWidget {
  final ExamModel exam;
  final String classId;
  final SubmissionModel submission;

  const ExamReviewScreen({
    super.key,
    required this.exam,
    required this.classId,
    required this.submission,
  });

  @override
  State<ExamReviewScreen> createState() => _ExamReviewScreenState();
}

class _ExamReviewScreenState extends State<ExamReviewScreen> {
  // questionId → câu trả lời học sinh đã chọn
  late final Map<int, String> _studentAnswers;

  @override
  void initState() {
    super.initState();
    _studentAnswers = {
      for (final a in widget.submission.answers) a.questionId: a.answer,
    };
  }

  bool _isCorrect(QuestionModel q) {
    final chosen = _studentAnswers[q.id] ?? '';
    if (chosen.isEmpty) return false;
    return chosen.trim().toLowerCase() == q.answer.trim().toLowerCase();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final questions = widget.exam.questions;
    final sub = widget.submission;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildScoreBanner(sub),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                itemCount: questions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) =>
                    _buildQuestionCard(questions[i], i),
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
      padding: const EdgeInsets.fromLTRB(4, 10, 16, 10),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.textDark),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  widget.exam.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const Text(
                  'Xem lại đáp án',
                  style: TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
              ],
            ),
          ),
          // Nhãn "Đã nộp" để cân bằng layout
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Đã nộp',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Score banner ──────────────────────────────────────────────────────────

  Widget _buildScoreBanner(SubmissionModel sub) {
    final grade = _getGrade(sub.score);
    final percentage = sub.totalCount > 0
        ? (sub.correctCount / sub.totalCount * 100).round()
        : 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: grade.$2.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: grade.$2.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          // Điểm
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    sub.score.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: grade.$2,
                      height: 1,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6, left: 2),
                    child: Text('/10',
                        style: TextStyle(
                            fontSize: 16, color: AppColors.textLight)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: grade.$2.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  grade.$1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: grade.$2,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _scoreStat(Icons.check_circle_rounded,
                  '${sub.correctCount} đúng', AppColors.success),
              const SizedBox(height: 6),
              _scoreStat(Icons.cancel_rounded,
                  '${sub.totalCount - sub.correctCount} sai', Colors.red),
              const SizedBox(height: 6),
              _scoreStat(Icons.percent_rounded, '$percentage%',
                  AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreStat(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  // ── Question card ─────────────────────────────────────────────────────────

  Widget _buildQuestionCard(QuestionModel q, int index) {
    final correct = _isCorrect(q);
    final chosen = _studentAnswers[q.id] ?? '';
    final unanswered = chosen.isEmpty;

    final borderColor = unanswered
        ? AppColors.border
        : correct
            ? const Color(0xFF10B981)
            : Colors.red;
    final bgColor = unanswered
        ? Colors.white
        : correct
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFFFF5F5);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Question header ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: unanswered
                        ? AppColors.textLight.withOpacity(0.15)
                        : correct
                            ? const Color(0xFF10B981).withOpacity(0.15)
                            : Colors.red.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    unanswered
                        ? Icons.remove_circle_outline_rounded
                        : correct
                            ? Icons.check_rounded
                            : Icons.close_rounded,
                    size: 16,
                    color: unanswered
                        ? AppColors.textLight
                        : correct
                            ? const Color(0xFF10B981)
                            : Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Câu ${index + 1}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: unanswered
                        ? AppColors.textLight
                        : correct
                            ? const Color(0xFF10B981)
                            : Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                _difficultyBadge(q.difficulty),
                const Spacer(),
                _typeBadge(q.type),
              ],
            ),
          ),

          // ── Question text ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Text(
              q.question,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
                height: 1.5,
              ),
            ),
          ),

          // ── Options / Answer section ──────────────────────────────────
          if (q.type == 'multiple_choice' && q.options != null)
            ..._buildMCOptions(q)
          else if (q.type == 'true_false')
            ..._buildTFOptions(q)
          else
            _buildFillInReview(q, chosen),

          // ── Explanation ───────────────────────────────────────────────
          if (q.explanation.isNotEmpty)
            _buildExplanation(q.explanation),

          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── MC options ────────────────────────────────────────────────────────────

  List<Widget> _buildMCOptions(QuestionModel q) {
    return q.options!.map((opt) {
      // Tách label (A, B, C, D) và phần text trước để so sánh đúng
      final parts = opt.split('. ');
      final label = parts.length >= 2 ? parts[0] : opt;
      final text = parts.length >= 2 ? parts.sublist(1).join('. ') : opt;

      final isChosen = (_studentAnswers[q.id] ?? '') == opt;
      // So sánh với cả 3 dạng: full ("A. Hà Nội"), chỉ label ("A"), chỉ text ("Hà Nội")
      final answerLower = q.answer.trim().toLowerCase();
      final isCorrectOpt =
          opt.trim().toLowerCase() == answerLower ||
          label.trim().toLowerCase() == answerLower ||
          text.trim().toLowerCase() == answerLower;

      Color? bgColor;
      Color borderColor = AppColors.border;
      Color? labelBg = AppColors.bgLight;
      Color labelColor = AppColors.textMedium;
      Widget? trailing;

      if (isCorrectOpt) {
        bgColor = const Color(0xFFECFDF5);
        borderColor = const Color(0xFF10B981);
        labelBg = const Color(0xFF10B981);
        labelColor = Colors.white;
        trailing = const Icon(Icons.check_circle_rounded,
            color: Color(0xFF10B981), size: 18);
      }
      if (isChosen && !isCorrectOpt) {
        bgColor = const Color(0xFFFEF2F2);
        borderColor = Colors.red;
        labelBg = Colors.red;
        labelColor = Colors.white;
        trailing =
            const Icon(Icons.cancel_rounded, color: Colors.red, size: 18);
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor ?? Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: labelBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: labelColor,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    color: isCorrectOpt
                        ? const Color(0xFF065F46)
                        : (isChosen ? Colors.red.shade800 : AppColors.textDark),
                    fontWeight: (isCorrectOpt || isChosen)
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing,
              ],
            ],
          ),
        ),
      );
    }).toList();
  }

  // ── True/False options ────────────────────────────────────────────────────

  List<Widget> _buildTFOptions(QuestionModel q) {
    return ['True', 'False'].map((value) {
      final label = value == 'True' ? 'Đúng' : 'Sai';
      final icon =
          value == 'True' ? Icons.check_rounded : Icons.close_rounded;
      final isChosen = (_studentAnswers[q.id] ?? '') == value;
      final isCorrectOpt =
          value.toLowerCase() == q.answer.trim().toLowerCase();
      final baseColor = value == 'True' ? Colors.green : Colors.red;

      Color containerColor = Colors.white;
      Color borderColor = AppColors.border;
      Widget? trailing;

      if (isCorrectOpt) {
        containerColor = baseColor.withOpacity(0.08);
        borderColor = baseColor;
        trailing = Icon(Icons.check_circle_rounded,
            color: baseColor, size: 18);
      }
      if (isChosen && !isCorrectOpt) {
        containerColor = Colors.red.withOpacity(0.06);
        borderColor = Colors.red;
        trailing =
            const Icon(Icons.cancel_rounded, color: Colors.red, size: 18);
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isCorrectOpt
                      ? baseColor.withOpacity(0.12)
                      : (isChosen ? Colors.red.withOpacity(0.1) : AppColors.bgLight),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    color: isCorrectOpt
                        ? baseColor
                        : (isChosen ? Colors.red : AppColors.textLight),
                    size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isCorrectOpt
                      ? baseColor.shade700
                      : (isChosen ? Colors.red.shade700 : AppColors.textDark),
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
        ),
      );
    }).toList();
  }

  // ── Fill-in review ────────────────────────────────────────────────────────

  Widget _buildFillInReview(QuestionModel q, String chosen) {
    final correct = _isCorrect(q);
    final unanswered = chosen.isEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Câu trả lời của học sinh
          _answerRow(
            label: 'Bạn trả lời',
            value: unanswered ? '(Bỏ trống)' : chosen,
            color: unanswered
                ? AppColors.textLight
                : correct
                    ? const Color(0xFF10B981)
                    : Colors.red,
            icon: unanswered
                ? Icons.remove_outlined
                : correct
                    ? Icons.check_circle_outline_rounded
                    : Icons.cancel_outlined,
          ),
          // Nếu sai hoặc bỏ trống → hiện đáp án đúng
          if (!correct) ...[
            const SizedBox(height: 8),
            _answerRow(
              label: 'Đáp án đúng',
              value: q.answer,
              color: const Color(0xFF10B981),
              icon: Icons.check_circle_outline_rounded,
            ),
          ],
        ],
      ),
    );
  }

  Widget _answerRow({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Explanation ───────────────────────────────────────────────────────────

  Widget _buildExplanation(String explanation) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_rounded,
              color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              explanation,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMedium,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Badges ────────────────────────────────────────────────────────────────

  Widget _difficultyBadge(String difficulty) {
    final map = {
      'easy': ('Dễ', Colors.green),
      'medium': ('Trung bình', Colors.orange),
      'hard': ('Khó', Colors.red),
    };
    final info =
        map[difficulty.toLowerCase()] ?? ('Trung bình', Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: info.$2.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        info.$1,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: info.$2),
      ),
    );
  }

  Widget _typeBadge(String type) {
    final map = {
      'multiple_choice': ('Trắc nghiệm', AppColors.primary),
      'true_false': ('Đúng/Sai', Colors.teal),
      'fill_in': ('Điền từ', Colors.deepPurple),
    };
    final info = map[type] ??
        (type, AppColors.textMedium);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: info.$2.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        info.$1,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: info.$2),
      ),
    );
  }

  // ── Grade helper ──────────────────────────────────────────────────────────

  (String, Color) _getGrade(double score) {
    if (score >= 9) return ('Xuất sắc', const Color(0xFF10B981));
    if (score >= 8) return ('Giỏi', AppColors.primary);
    if (score >= 6.5) return ('Khá', const Color(0xFF3B82F6));
    if (score >= 5) return ('Trung bình', Colors.orange);
    return ('Yếu', Colors.red);
  }
}