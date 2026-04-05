import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../data/models/exam_model.dart';
import '../../data/models/question_model.dart';
import '../../controllers/exam_controller.dart';
import 'assign_exam_screen.dart';

class ExamPreviewScreen extends StatefulWidget {
  final ExamModel exam;
  const ExamPreviewScreen({super.key, required this.exam});

  @override
  State<ExamPreviewScreen> createState() => _ExamPreviewScreenState();
}

class _ExamPreviewScreenState extends State<ExamPreviewScreen> {
  late ExamModel _exam;
  final _controller = ExamController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _exam = widget.exam;
  }

  //lưu đề
  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      await _controller.saveExam(_exam);
      if (!mounted) return;
      // Sau khi lưu → chuyển sang màn giao đề
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => AssignExamScreen(exam: _exam),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lưu thất bại: $e'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  //sửa câu hỏi
  void _editQuestion(int index) {
    final q = _exam.questions[index];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditQuestionSheet(
        question: q,
        onSave: (updated) {
          setState(() {
            final list = List<QuestionModel>.from(_exam.questions);
            list[index] = updated;
            _exam = _exam.copyWith(questions: list);
          });
        },
      ),
    );
  }

  //xóa câu hỏi
  void _deleteQuestion(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xoá câu hỏi?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Câu hỏi này sẽ bị xoá khỏi đề thi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Huỷ',
                  style: TextStyle(color: AppColors.textMedium))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                final list = List<QuestionModel>.from(_exam.questions)
                  ..removeAt(index);
                // Đánh lại id
                final renumbered = list.asMap().entries
                    .map((e) => e.value.copyWith(id: e.key + 1))
                    .toList();
                _exam = _exam.copyWith(questions: renumbered);
              });
            },
            child: const Text('Xoá',
                style: TextStyle(color: Colors.red,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

 //thêm câu hỏi
  void _addQuestion() {
    final newQ = QuestionModel(
      id:          _exam.questions.length + 1,
      type:        'multiple_choice',
      difficulty:  'medium',
      question:    '',
      options:     ['A. ', 'B. ', 'C. ', 'D. '],
      answer:      'A',
      explanation: '',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditQuestionSheet(
        question: newQ,
        isNew: true,
        onSave: (created) {
          setState(() {
            _exam = _exam.copyWith(
              questions: [..._exam.questions, created],
            );
          });
        },
      ),
    );
  }

 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSummaryBar(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: _exam.questions.length + 1, // +1 cho nút thêm
                itemBuilder: (_, i) {
                  if (i == _exam.questions.length) return _buildAddButton();
                  return _buildQuestionCard(_exam.questions[i], i);
                },
              ),
            ),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  
  Widget _buildHeader() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.textDark,
        ),
        Expanded(child: Column(children: [
          Text(_exam.name,
              style: const TextStyle(fontSize: 16,
                  fontWeight: FontWeight.bold, color: AppColors.textDark),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('${_exam.questions.length} câu hỏi',
              style: const TextStyle(fontSize: 12,
                  color: AppColors.textMedium)),
        ])),
        const SizedBox(width: 48),
      ]),
    );
  }

  
  Widget _buildSummaryBar() {
    final mc = _exam.questions.where((q) => q.type == 'multiple_choice').length;
    final fi = _exam.questions.where((q) => q.type == 'fill_in').length;
    final tf = _exam.questions.where((q) => q.type == 'true_false').length;
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(children: [
        _badge('Trắc nghiệm $mc', AppColors.primary),
        const SizedBox(width: 8),
        _badge('Điền từ $fi', Colors.orange),
        const SizedBox(width: 8),
        _badge('Đúng/Sai $tf', Colors.green),
      ]),
    );
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(label, style: TextStyle(fontSize: 11,
        fontWeight: FontWeight.w600, color: color)),
  );

 
  Widget _buildQuestionCard(QuestionModel q, int index) {
    final diffColor = q.difficulty == 'easy'
        ? Colors.green
        : q.difficulty == 'medium' ? Colors.orange : Colors.red;
    final diffLabel = q.difficulty == 'easy' ? 'Dễ'
        : q.difficulty == 'medium' ? 'Trung bình' : 'Khó';
    final typeLabel = q.type == 'multiple_choice' ? 'Trắc nghiệm'
        : q.type == 'fill_in' ? 'Điền từ' : 'Đúng / Sai';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: số câu + badges + actions ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
            child: Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: Text('${index + 1}',
                    style: const TextStyle(fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary))),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: diffColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(diffLabel, style: TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w600, color: diffColor)),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(typeLabel, style: const TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
              ),
              const Spacer(),
              // Nút sửa
              IconButton(
                onPressed: () => _editQuestion(index),
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: AppColors.textMedium,
                visualDensity: VisualDensity.compact,
                tooltip: 'Sửa câu hỏi',
              ),
              // Nút xoá
              IconButton(
                onPressed: () => _deleteQuestion(index),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                color: Colors.red.withOpacity(0.7),
                visualDensity: VisualDensity.compact,
                tooltip: 'Xoá câu hỏi',
              ),
            ]),
          ),

          // ── Nội dung câu hỏi ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(q.question.isEmpty ? '(Chưa có nội dung)' : q.question,
                style: TextStyle(
                  fontSize: 14, height: 1.5,
                  color: q.question.isEmpty
                      ? AppColors.textHint : AppColors.textDark,
                  fontStyle: q.question.isEmpty
                      ? FontStyle.italic : FontStyle.normal,
                )),
          ),

          // ── Options (chỉ multiple_choice) ──
          if (q.type == 'multiple_choice' &&
              q.options != null && q.options!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                children: q.options!.map((opt) {
                  final letter = opt.isNotEmpty ? opt[0] : '';
                  final isCorrect = letter == q.answer;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? Colors.green.withOpacity(0.08)
                          : const Color(0xFFF5F7F8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCorrect
                            ? Colors.green.withOpacity(0.4)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(children: [
                      if (isCorrect)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(Icons.check_circle_rounded,
                              size: 14, color: Colors.green),
                        ),
                      Expanded(child: Text(opt,
                          style: TextStyle(
                            fontSize: 13,
                            color: isCorrect ? Colors.green.shade700
                                : AppColors.textDark,
                          ))),
                    ]),
                  );
                }).toList(),
              ),
            ),

          // ── Đáp án (fill_in / true_false) ──
          if (q.type != 'multiple_choice')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded,
                    size: 14, color: Colors.green),
                const SizedBox(width: 6),
                Text('Đáp án: ${q.answer}',
                    style: const TextStyle(fontSize: 13,
                        color: Colors.green,
                        fontWeight: FontWeight.w600)),
              ]),
            ),

          // ── Giải thích ──
          if (q.explanation.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      size: 14, color: Colors.amber),
                  const SizedBox(width: 6),
                  Expanded(child: Text(q.explanation,
                      style: const TextStyle(fontSize: 12,
                          color: Color(0xFF7A6000), height: 1.5))),
                ],
              ),
            ),

          const SizedBox(height: 14),
        ],
      ),
    );
  }


  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _addQuestion,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              style: BorderStyle.solid),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded,
                color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Thêm câu hỏi',
                style: TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

 
  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SizedBox(
        width: double.infinity, height: 56,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28)),
            elevation: 4,
          ),
          child: _isSaving
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: AppColors.white, strokeWidth: 2.5)),
                    SizedBox(width: 12),
                    Text('Đang lưu...', style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.bold)),
                  ])
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_rounded),
                    SizedBox(width: 8),
                    Text('Lưu đề', style: TextStyle(fontSize: 17,
                        fontWeight: FontWeight.bold)),
                  ]),
        ),
      ),
    );
  }
}


class _EditQuestionSheet extends StatefulWidget {
  final QuestionModel question;
  final bool isNew;
  final ValueChanged<QuestionModel> onSave;

  const _EditQuestionSheet({
    required this.question,
    required this.onSave,
    this.isNew = false,
  });

  @override
  State<_EditQuestionSheet> createState() => _EditQuestionSheetState();
}

class _EditQuestionSheetState extends State<_EditQuestionSheet> {
  late TextEditingController _questionCtrl;
  late TextEditingController _answerCtrl;
  late TextEditingController _explanationCtrl;
  late List<TextEditingController> _optionCtrls;
  late String _type;
  late String _difficulty;
  late String _answer;

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    _type        = q.type;
    _difficulty  = q.difficulty;
    _answer      = q.answer;
    _questionCtrl    = TextEditingController(text: q.question);
    _answerCtrl      = TextEditingController(text: q.answer);
    _explanationCtrl = TextEditingController(text: q.explanation);
    _optionCtrls = (q.options ?? ['A. ', 'B. ', 'C. ', 'D. '])
        .map((o) => TextEditingController(text: o))
        .toList();
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _answerCtrl.dispose();
    _explanationCtrl.dispose();
    for (final c in _optionCtrls) c.dispose();
    super.dispose();
  }

  void _handleSave() {
    final opts = _type == 'multiple_choice'
        ? _optionCtrls.map((c) => c.text.trim()).toList()
        : null;

    final updated = widget.question.copyWith(
      question:    _questionCtrl.text.trim(),
      answer:      _type == 'multiple_choice' ? _answer : _answerCtrl.text.trim(),
      explanation: _explanationCtrl.text.trim(),
      type:        _type,
      difficulty:  _difficulty,
      options:     opts,
    );
    widget.onSave(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),

            Text(widget.isNew ? 'Thêm câu hỏi' : 'Sửa câu hỏi',
                style: const TextStyle(fontSize: 17,
                    fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 16),

            // Loại + độ khó
            Row(children: [
              Expanded(child: _dropDown('Loại', _type, {
                'multiple_choice': 'Trắc nghiệm',
                'fill_in':         'Điền từ',
                'true_false':      'Đúng/Sai',
              }, (v) => setState(() {
                _type = v!;
                if (_type == 'true_false') _answer = 'True';
                if (_type == 'multiple_choice') _answer = 'A';
              }))),
              const SizedBox(width: 12),
              Expanded(child: _dropDown('Độ khó', _difficulty, {
                'easy':   'Dễ',
                'medium': 'Trung bình',
                'hard':   'Khó',
              }, (v) => setState(() => _difficulty = v!))),
            ]),
            const SizedBox(height: 14),

            // Nội dung câu hỏi
            _label('Câu hỏi'),
            const SizedBox(height: 6),
            _textField(_questionCtrl, maxLines: 3,
                hint: 'Nhập nội dung câu hỏi...'),
            const SizedBox(height: 14),

            // Options (chỉ MC)
            if (_type == 'multiple_choice') ...[
              _label('Các lựa chọn (đánh dấu đáp án đúng)'),
              const SizedBox(height: 6),
              ...List.generate(4, (i) {
                final letter = ['A', 'B', 'C', 'D'][i];
                final isCorrect = _answer == letter;
                return GestureDetector(
                  onTap: () => setState(() => _answer = letter),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? Colors.green.withOpacity(0.06)
                          : const Color(0xFFF5F7F8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCorrect ? Colors.green : Colors.transparent,
                      ),
                    ),
                    child: Row(children: [
                      Icon(isCorrect
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                          size: 18,
                          color: isCorrect ? Colors.green : AppColors.textHint),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(
                        controller: _optionCtrls[i],
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      )),
                    ]),
                  ),
                );
              }),
            ],

            // Đáp án (fill_in)
            if (_type == 'fill_in') ...[
              _label('Đáp án'),
              const SizedBox(height: 6),
              _textField(_answerCtrl, hint: 'Từ hoặc cụm từ đúng'),
            ],

            // Đáp án (true_false)
            if (_type == 'true_false') ...[
              _label('Đáp án'),
              const SizedBox(height: 6),
              Row(children: [
                _tfBtn('True', Colors.green),
                const SizedBox(width: 12),
                _tfBtn('False', Colors.red),
              ]),
            ],

            const SizedBox(height: 14),
            _label('Giải thích'),
            const SizedBox(height: 6),
            _textField(_explanationCtrl, maxLines: 2,
                hint: 'Giải thích ngắn gọn tại sao đúng...'),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(widget.isNew ? 'Thêm câu hỏi' : 'Lưu thay đổi',
                    style: const TextStyle(fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 13,
          fontWeight: FontWeight.w600, color: AppColors.textLabel));

  Widget _textField(TextEditingController ctrl,
      {int maxLines = 1, String hint = ''}) =>
    TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF5F7F8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
    );

  Widget _dropDown(String label, String value, Map<String, String> items,
      ValueChanged<String?> onChanged) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(label),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7F8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            style: const TextStyle(fontSize: 13, color: AppColors.textDark),
            items: items.entries.map((e) => DropdownMenuItem(
              value: e.key,
              child: Text(e.value),
            )).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    ]);

  Widget _tfBtn(String val, Color color) {
    final on = _answer == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _answer = val),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: on ? color.withOpacity(0.1) : const Color(0xFFF5F7F8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: on ? color : Colors.transparent),
          ),
          child: Center(child: Text(val,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: on ? color : AppColors.textMedium))),
        ),
      ),
    );
  }
}