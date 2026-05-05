import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../data/models/exam_model.dart';
import '../../data/models/question_model.dart';
import '../../data/models/submission_model.dart';
import '../../controllers/submission_controller.dart';
import 'exam_review_screen.dart'; // ← MỚI
import 'list_exam.dart';

class ExamTakeScreen extends StatefulWidget {
  final ExamModel exam;
  final String classId;

  const ExamTakeScreen({
    super.key,
    required this.exam,
    required this.classId,
  });

  @override
  State<ExamTakeScreen> createState() => _ExamTakeScreenState();
}

class _ExamTakeScreenState extends State<ExamTakeScreen> {
  final _submissionController = SubmissionController();
  final PageController _pageController = PageController();

  late int _totalSeconds;
  late Timer _timer;
  int _remainingSeconds = 0;
  int _currentPage = 0;

  // questionId → answer đã chọn
  final Map<int, String> _answers = {};
  bool _isSubmitting = false;
  bool _submitted = false;
  SubmissionModel? _result;

  late List<QuestionModel> _questions;

  @override
  void initState() {
    super.initState();
    _questions = widget.exam.questions;

    final assignment = widget.exam.assignments.firstWhere(
      (a) => a.classId == widget.classId,
      orElse: () => widget.exam.assignments.first,
    );
    _totalSeconds = assignment.durationMinutes * 60;
    _remainingSeconds = _totalSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds <= 0) {
        t.cancel();
        _autoSubmit();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  Future<void> _autoSubmit() async {
    if (_submitted || _isSubmitting) return;
    await _doSubmit();
  }

  Future<void> _doSubmit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    _timer.cancel();

    try {
      final result = await _submissionController.submitExam(
        examId: widget.exam.id,
        classId: widget.classId,
        questions: _questions,
        studentAnswers: _answers,
        durationSeconds: _totalSeconds - _remainingSeconds,
        examName: widget.exam.name,
      );
      setState(() {
        _submitted = true;
        _result = result;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi nộp bài: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  String get _timerText {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_remainingSeconds <= 60) return Colors.red;
    if (_remainingSeconds <= 300) return Colors.orange;
    return AppColors.primary;
  }

  int get _answeredCount =>
      _questions.where((q) => _answers.containsKey(q.id)).length;

  @override
  Widget build(BuildContext context) {
    if (_submitted && _result != null) {
      return _buildResultScreen();
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final confirm = await _showExitDialog();
        if (confirm == true && mounted) {
          _timer.cancel();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgLight,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              _buildProgressBar(),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _questions.length,
                  itemBuilder: (ctx, i) =>
                      _buildQuestionPage(_questions[i], i),
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textDark),
            onPressed: () async {
              final confirm = await _showExitDialog();
              if (confirm == true && mounted) {
                _timer.cancel();
                Navigator.of(context).pop();
              }
            },
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  widget.exam.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_answeredCount}/${_questions.length} câu đã trả lời',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textLight),
                ),
              ],
            ),
          ),
          // Đồng hồ đếm ngược
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _timerColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _timerColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.timer_rounded, size: 16, color: _timerColor),
                const SizedBox(width: 4),
                Text(
                  _timerText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _timerColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = _questions.isEmpty
        ? 0.0
        : (_currentPage + 1) / _questions.length;
    return LinearProgressIndicator(
      value: progress,
      backgroundColor: AppColors.border,
      color: AppColors.primary,
      minHeight: 3,
    );
  }

  Widget _buildQuestionPage(QuestionModel q, int index) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header câu hỏi
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Câu ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _difficultyBadge(q.difficulty),
            ],
          ),
          const SizedBox(height: 16),
          // Nội dung câu hỏi
          Text(
            q.question,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          // Đáp án
          if (q.type == 'multiple_choice' && q.options != null)
            ...q.options!.map((opt) => _buildMCOption(q, opt))
          else if (q.type == 'true_false')
            ...[
              _buildTFOption(q, 'True', 'Đúng'),
              _buildTFOption(q, 'False', 'Sai'),
            ]
          else
            _buildFillInField(q),
        ],
      ),
    );
  }

  Widget _difficultyBadge(String difficulty) {
    final map = {
      'easy': ('Dễ', Colors.green),
      'medium': ('Trung bình', Colors.orange),
      'hard': ('Khó', Colors.red),
    };
    final info = map[difficulty.toLowerCase()] ?? ('Trung bình', Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: info.$2.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        info.$1,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: info.$2),
      ),
    );
  }

  Widget _buildMCOption(QuestionModel q, String option) {
    final selected = _answers[q.id] == option;
    // Tách label (A, B, C, D) từ "A. ..." hoặc dùng nguyên
    final parts = option.split('. ');
    final label = parts.length >= 2 ? parts[0] : option;
    final text = parts.length >= 2 ? parts.sublist(1).join('. ') : option;

    return GestureDetector(
      onTap: () => setState(() => _answers[q.id] = option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.bgLight,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : AppColors.textMedium,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  color: selected ? AppColors.primary : AppColors.textDark,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTFOption(QuestionModel q, String value, String label) {
    final selected = _answers[q.id] == value;
    final color = value == 'True' ? Colors.green : Colors.red;
    final icon =
        value == 'True' ? Icons.check_rounded : Icons.close_rounded;

    return GestureDetector(
      onTap: () => setState(() => _answers[q.id] = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected ? color : AppColors.bgLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: selected ? Colors.white : AppColors.textLight),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: selected ? color : AppColors.textDark,
              ),
            ),
            const Spacer(),
            if (selected)
              Icon(Icons.check_circle_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFillInField(QuestionModel q) {
    return TextField(
      onChanged: (v) => _answers[q.id] = v,
      decoration: InputDecoration(
        hintText: 'Nhập câu trả lời...',
        hintStyle: const TextStyle(color: AppColors.textHint),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      style:
          const TextStyle(fontSize: 16, color: AppColors.textDark),
    );
  }

  Widget _buildBottomBar() {
    final isFirst = _currentPage == 0;
    final isLast = _currentPage == _questions.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Prev
          if (!isFirst)
            OutlinedButton.icon(
              onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.ease),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Trước'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            )
          else
            const SizedBox(width: 100),

          const Spacer(),

          // Question dots indicator (tối đa 7 dots)
          _buildDotIndicator(),

          const Spacer(),

          // Next / Submit
          if (!isLast)
            ElevatedButton.icon(
              onPressed: () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.ease),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Tiếp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _confirmSubmit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 18),
              label:
                  Text(_isSubmitting ? 'Đang nộp...' : 'Nộp bài'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDotIndicator() {
    const maxDots = 7;
    final count = _questions.length;
    if (count <= maxDots) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(count, (i) {
          final answered = _answers.containsKey(_questions[i].id);
          final isCurrent = i == _currentPage;
          return GestureDetector(
            onTap: () => _pageController.animateToPage(i,
                duration: const Duration(milliseconds: 250),
                curve: Curves.ease),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isCurrent ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isCurrent
                    ? AppColors.primary
                    : answered
                        ? AppColors.success
                        : AppColors.border,
              ),
            ),
          );
        }),
      );
    }
    // Nhiều câu thì chỉ hiển thị số
    return Text(
      '${_currentPage + 1} / $count',
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textMedium),
    );
  }

  Future<void> _confirmSubmit() async {
    final unanswered = _questions.length - _answeredCount;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Nộp bài?'),
        content: unanswered > 0
            ? Text(
                'Bạn còn $unanswered câu chưa trả lời. Vẫn muốn nộp?')
            : const Text('Bạn đã trả lời tất cả các câu. Nộp bài?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Làm tiếp'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Nộp bài'),
          ),
        ],
      ),
    );
    if (confirm == true) await _doSubmit();
  }

  Future<bool?> _showExitDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Thoát bài thi?'),
        content: const Text(
            'Bài làm sẽ không được lưu nếu bạn thoát ra.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Ở lại')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Thoát'),
          ),
        ],
      ),
    );
  }

  // ── Màn hình kết quả ──────────────────────────────────────────────────────
  Widget _buildResultScreen() {
    final result = _result!;
    final percentage = result.totalCount > 0
        ? (result.correctCount / result.totalCount * 100).round()
        : 0;
    final grade = _getGrade(result.score);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Icon kết quả
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: grade.$2.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(grade.$3, color: grade.$2, size: 52),
              ),
              const SizedBox(height: 20),
              Text(
                'Nộp bài thành công!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.exam.name,
                style: const TextStyle(
                    fontSize: 15, color: AppColors.textMedium),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Điểm số lớn
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Text(
                      result.score.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        color: grade.$2,
                        height: 1,
                      ),
                    ),
                    const Text(
                      '/ 10',
                      style: TextStyle(
                          fontSize: 22, color: AppColors.textLight),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: grade.$2.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        grade.$1,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: grade.$2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Stats row
              Row(
                children: [
                  _resultStat(
                      '${result.correctCount}',
                      'Câu đúng',
                      Icons.check_circle_rounded,
                      AppColors.success),
                  const SizedBox(width: 12),
                  _resultStat(
                      '${result.totalCount - result.correctCount}',
                      'Câu sai',
                      Icons.cancel_rounded,
                      Colors.red),
                  const SizedBox(width: 12),
                  _resultStat('$percentage%', 'Tỉ lệ đúng',
                      Icons.percent_rounded, AppColors.primary),
                ],
              ),
              const SizedBox(height: 20),

              // Thời gian làm bài
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_rounded,
                        color: AppColors.textLight, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Thời gian làm bài: ${_formatDuration(result.durationSeconds)}',
                      style: const TextStyle(
                          color: AppColors.textMedium, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ← MỚI: nút "Xem đáp án" nếu giáo viên cho phép
              ..._buildResultButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // ← MỚI: trả về danh sách nút dưới màn hình kết quả
  List<Widget> _buildResultButtons() {
    // Lấy assignment tương ứng với classId đang thi
    ExamAssignment? assignment;
    try {
      assignment = widget.exam.assignments
          .firstWhere((a) => a.classId == widget.classId);
    } catch (_) {
      assignment = widget.exam.assignments.isNotEmpty
          ? widget.exam.assignments.first
          : null;
    }

    final canReview =
        assignment?.showAnswerAfterSubmit ?? false;

    return [
      // Nút "Xem đáp án" — chỉ hiện khi giáo viên cho phép
      if (canReview && _result != null) ...[
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExamReviewScreen(
                    exam: widget.exam,
                    classId: widget.classId,
                    submission: _result!,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.visibility_rounded),
            label: const Text(
              'Xem đáp án chi tiết',
              style: TextStyle(fontSize: 16),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
      // Nút về danh sách
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const ListExamsScreen()),
            (route) => route.isFirst,
          ),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text(
            'Về danh sách đề thi',
            style: TextStyle(fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    ];
  }

  Widget _resultStat(
      String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }

  // (label, color, icon)
  (String, Color, IconData) _getGrade(double score) {
    if (score >= 9) return ('Xuất sắc', const Color(0xFF10B981), Icons.emoji_events_rounded);
    if (score >= 8) return ('Giỏi', AppColors.primary, Icons.star_rounded);
    if (score >= 6.5) return ('Khá', const Color(0xFF3B82F6), Icons.thumb_up_rounded);
    if (score >= 5) return ('Trung bình', Colors.orange, Icons.sentiment_neutral_rounded);
    return ('Yếu', Colors.red, Icons.sentiment_dissatisfied_rounded);
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}p ${s}s';
  }
}