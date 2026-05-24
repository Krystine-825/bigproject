import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../data/models/exam_model.dart';
import '../../controllers/exam_controller.dart';
import '../../data/services/class_cache_service.dart';
import 'exam_bank_screen.dart';

class AssignExamScreen extends StatefulWidget {
  final ExamModel exam;
  const AssignExamScreen({super.key, required this.exam});

  @override
  State<AssignExamScreen> createState() => _AssignExamScreenState();
}

class _AssignExamScreenState extends State<AssignExamScreen> {
  final _controller = ExamController();
  List<Map<String, String>> _classes = [];
  Set<String> _selectedIds = {};
  
  int _durationMinutes = 45;
  DateTime _openAt = DateTime.now().add(const Duration(hours: 1));
  DateTime _closeAt = DateTime.now().add(const Duration(days: 7));
  int _maxAttempts = 1;
  bool _showAnswerAfterSubmit = false; 
  bool _isAssigning = false;

  List<Map<String, String>>? _classList;
  // Cache được quản lý bởi ClassCacheService singleton (toàn app)

  @override
  void initState() {
    super.initState();
    final assignedIds = widget.exam.assignments.map((a) => a.classId).toSet();
    _loadClasses(assignedIds);
  }

  bool get _allSelected =>
      _classes.isNotEmpty &&
      _classes.every((c) => _selectedIds.contains(c['id']));

  Future<void> _loadClasses(Set<String> assignedIds) async {
    final svc = ClassCacheService.instance;

    // Nếu cache đã có (warm từ ExamBankScreen) → hiển thị ngay lập tức
    if (svc.hasCache) {
      final list = svc.cache!
          .where((c) => !assignedIds.contains(c['id']))
          .toList();
      if (mounted) setState(() { _classList = list; _classes = list; });
      return;
    }

    // Chưa có cache → hiển thị loading và fetch
    if (mounted) setState(() { _classList = null; _classes = []; });

    final all = await svc.fetchAndCache();
    final list = all.where((c) => !assignedIds.contains(c['id'])).toList();
    if (mounted) setState(() { _classList = list; _classes = list; });
  }

  void _showClassSelectionDialog(List<Map<String, String>> classes) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final allSelected = classes.isNotEmpty &&
              classes.every((c) => _selectedIds.contains(c['id']));

          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Chọn lớp để giao đề',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Chọn tất cả
                  InkWell(
                    onTap: () {
                      setStateDialog(() {
                        if (allSelected) {
                          _selectedIds.clear();
                        } else {
                          _selectedIds = classes.map((c) => c['id']!).toSet();
                        }
                      });
                      setState(() {}); 
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            color: allSelected ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: allSelected ? AppColors.primary : AppColors.border,
                              width: 2,
                            ),
                          ),
                          child: allSelected
                              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text('Chọn tất cả',
                              style: TextStyle(fontSize: 15,
                                  fontWeight: FontWeight.bold, color: AppColors.textDark)),
                        ),
                      ]),
                    ),
                  ),
                  const Divider(),
                  // List lớp
                  ...classes.map((cls) {
                    final id = cls['id']!;
                    final name = cls['name']!;
                    final isChecked = _selectedIds.contains(id);
                    return InkWell(
                      onTap: () {
                        setStateDialog(() {
                          if (isChecked) {
                            _selectedIds.remove(id);
                          } else {
                            _selectedIds.add(id);
                          }
                        });
                        setState(() {}); 
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 22, height: 22,
                            decoration: BoxDecoration(
                              color: isChecked ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isChecked ? AppColors.primary : AppColors.border,
                                width: 2,
                              ),
                            ),
                            child: isChecked
                                ? const Icon(Icons.check_rounded,
                                    size: 14, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.school_rounded,
                                color: AppColors.primary, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isChecked
                                      ? FontWeight.w700 : FontWeight.w500,
                                  color: isChecked
                                      ? AppColors.textDark : AppColors.textMedium,
                                )),
                          ),
                        ]),
                      ),
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Xong'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleAssign() async {
    if (_selectedIds.isEmpty) {
      _snack('Vui lòng chọn ít nhất 1 lớp', isError: true);
      return;
    }
    if (_closeAt.isBefore(_openAt)) {
      _snack('Thời gian hết hạn phải sau thời gian mở đề', isError: true);
      return;
    }

    setState(() => _isAssigning = true);

    try {
      // Gom tất cả lớp → 1 lần write Firestore duy nhất
      final selectedClasses = _selectedIds
          .map((id) => _classes.firstWhere((c) => c['id'] == id))
          .toList();

      await _controller.assignExamToClasses(
        examId:                widget.exam.id,
        classes:               selectedClasses,
        durationMinutes:       _durationMinutes,
        openAt:                _openAt,
        closeAt:               _closeAt,
        maxAttempts:           _maxAttempts,
        examName:              widget.exam.name,
        showAnswerAfterSubmit: _showAnswerAfterSubmit,
      );

      if (!mounted) return;
      // Xoá cache singleton vì danh sách lớp đã thay đổi
      ClassCacheService.instance.invalidate();
      _showSuccessDialog(_selectedIds.length);
    } catch (e) {
      if (mounted) _snack('Lỗi khi giao đề: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isAssigning = false);
    }
  }

  void _showSuccessDialog(int count) {
    final classNames = _selectedIds
        .map((id) => _classes.firstWhere((c) => c['id'] == id)['name']!)
        .join(', ');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
          SizedBox(width: 8),
          Text('Giao đề thành công!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assignment_turned_in_rounded,
                size: 56, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(widget.exam.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16,
                    fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 6),
            Text(
              count == 1
                  ? 'Đã giao cho lớp $classNames'
                  : 'Đã giao cho $count lớp:\n$classNames',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textMedium),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _showAnswerAfterSubmit
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    _showAnswerAfterSubmit
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    size: 16,
                    color: _showAnswerAfterSubmit
                        ? const Color(0xFF10B981)
                        : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _showAnswerAfterSubmit
                          ? 'Học sinh được xem đáp án sau khi nộp'
                          : 'Học sinh không được xem đáp án',
                      style: TextStyle(
                        fontSize: 12,
                        color: _showAnswerAfterSubmit
                            ? const Color(0xFF10B981)
                            : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                      
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // đóng Dialog
                Navigator.of(context).pop(true); // đóng AssignExamScreen
                Navigator.of(context).pop(); // đóng ExamDetailScreen → về ExamBankScreen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Về Kho đề', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildExamInfoCard(),
                  const SizedBox(height: 20),

                  if (widget.exam.assignments.isNotEmpty) ...[
                    _buildSectionTitle('Đã giao cho'),
                    const SizedBox(height: 10),
                    _buildAssignedList(),
                    const SizedBox(height: 20),
                  ],

                  _buildSectionTitle('Chọn lớp để giao'),
                  const SizedBox(height: 10),
                  _buildClassMultiSelect(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Cài đặt thời gian'),
                  const SizedBox(height: 10),
                  _buildTimeCard(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Số lần làm bài'),
                  const SizedBox(height: 10),
                  _buildAttemptsCard(),
                  const SizedBox(height: 20),

                  _buildSectionTitle('Cài đặt đáp án'),
                  const SizedBox(height: 10),
                  _buildShowAnswerCard(),
                ],
              ),
            ),
          ),
          _buildBottomButtons(),
        ]),
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
        const Expanded(
          child: Text('Giao đề',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                  color: AppColors.textDark)),
        ),
        const SizedBox(width: 48),
      ]),
    );
  }

  Widget _buildSectionTitle(String title) => Text(title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
          color: AppColors.textDark));

  Widget _buildExamInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.assignment_rounded,
              color: AppColors.primary, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.exam.name,
                style: const TextStyle(fontSize: 15,
                    fontWeight: FontWeight.bold, color: AppColors.primary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('${widget.exam.questions.length} câu hỏi',
                style: const TextStyle(fontSize: 12, color: AppColors.primary)),
          ],
        )),
      ]),
    );
  }

  Widget _buildAssignedList() {
    return Column(
      children: widget.exam.assignments.map((a) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.successBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withOpacity(0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.check_circle_rounded,
              size: 18, color: AppColors.success),
          const SizedBox(width: 10),
          Expanded(child: Text(a.className,
              style: const TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w600, color: AppColors.textDark))),
          Text('${a.durationMinutes} phút',
              style: const TextStyle(fontSize: 12,
                  color: AppColors.textMedium)),
        ]),
      )).toList(),
    );
  }

  Widget _buildClassMultiSelect() {
    // Đang fetch lần đầu → hiện spinner thay vì danh sách trống
    if (_classList == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final classes = _classList!;
    final selectedClasses = classes.where((c) => _selectedIds.contains(c['id'])).toList();
    final displayText = selectedClasses.isEmpty
        ? 'Chọn lớp để giao đề'
        : selectedClasses.length == 1
            ? selectedClasses.first['name']!
            : '${selectedClasses.length} lớp đã chọn';

    if (classes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: const Center(
          child: Text('Tất cả lớp đã được giao đề này',
              style: TextStyle(color: AppColors.textMedium)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        onTap: () => _showClassSelectionDialog(classes),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: selectedClasses.isEmpty
                            ? FontWeight.w500 : FontWeight.w700,
                        color: selectedClasses.isEmpty
                            ? AppColors.textHint : AppColors.textDark,
                      ),
                    ),
                    if (selectedClasses.isNotEmpty)
                      Text(
                        selectedClasses.map((c) => c['name']!).join(', '),
                        style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_drop_down_rounded,
                  color: AppColors.textHint, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        _timeRow(
          icon: Icons.timer_outlined,
          label: 'Thời gian làm bài',
          value: '$_durationMinutes phút',
          child: Row(children: [
            _smallBtn(Icons.remove_rounded,
                _durationMinutes > 10
                    ? () => setState(() => _durationMinutes -= 5) : null),
            SizedBox(
                width: 52,
                child: Text('$_durationMinutes ph',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark))),
            _smallBtn(Icons.add_rounded,
                _durationMinutes < 180
                    ? () => setState(() => _durationMinutes += 5) : null),
          ]),
        ),
        const Divider(height: 1),
        _timeRow(
          icon: Icons.lock_open_rounded,
          label: 'Mở đề lúc',
          value: _formatDateTime(_openAt),
          child: IconButton(
            onPressed: () => _pickDateTime(
                initial: _openAt,
                onPicked: (dt) => setState(() => _openAt = dt)),
            icon: const Icon(Icons.edit_calendar_rounded,
                color: AppColors.primary, size: 20),
          ),
        ),
        const Divider(height: 1),
        _timeRow(
          icon: Icons.lock_clock_outlined,
          label: 'Hết hạn lúc',
          value: _formatDateTime(_closeAt),
          child: IconButton(
            onPressed: () => _pickDateTime(
                initial: _closeAt,
                onPicked: (dt) => setState(() => _closeAt = dt)),
            icon: const Icon(Icons.edit_calendar_rounded,
                color: AppColors.primary, size: 20),
          ),
        ),
      ]),
    );
  }

  Widget _timeRow({
    required IconData icon,
    required String label,
    required String value,
    required Widget child,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12,
                  color: AppColors.textMedium)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w600, color: AppColors.textDark)),
            ],
          )),
          child,
        ]),
      );

  Widget _smallBtn(IconData icon, VoidCallback? onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: onTap != null
                ? AppColors.primaryLight
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16,
              color: onTap != null ? AppColors.primary : AppColors.textHint),
        ),
      );

  Future<void> _pickDateTime({
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    onPicked(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  String _formatDateTime(DateTime dt) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(dt.day)}/${pad(dt.month)}/${dt.year}  '
        '${pad(dt.hour)}:${pad(dt.minute)}';
  }

  Widget _buildAttemptsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Học sinh được làm tối đa:',
              style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
          const SizedBox(height: 12),
          Row(children: [
            _attemptBtn(1, '1 lần'),
            const SizedBox(width: 12),
            _attemptBtn(2, '2 lần'),
          ]),
          if (_maxAttempts == 2)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 6),
                const Text('Học sinh có thể làm lại 1 lần sau lần đầu',
                    style: TextStyle(fontSize: 12, color: AppColors.textHint)),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _attemptBtn(int value, String label) {
    final on = _maxAttempts == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _maxAttempts = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: on ? AppColors.primaryLight : const Color(0xFFF5F7F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: on ? AppColors.primary : Colors.transparent,
                width: 1.5),
          ),
          child: Center(child: Text(label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: on ? AppColors.primary : AppColors.textMedium))),
        ),
      ),
    );
  }

  Widget _buildShowAnswerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _showAnswerAfterSubmit
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _showAnswerAfterSubmit
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: _showAnswerAfterSubmit
                      ? const Color(0xFF10B981)
                      : AppColors.textHint,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cho xem đáp án sau khi nộp',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _showAnswerAfterSubmit
                          ? 'Học sinh xem được đáp án & điểm từng câu'
                          : 'Học sinh chỉ thấy điểm tổng',
                      style: TextStyle(
                        fontSize: 12,
                        color: _showAnswerAfterSubmit
                            ? const Color(0xFF10B981)
                            : AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _showAnswerAfterSubmit,
                onChanged: (v) => setState(() => _showAnswerAfterSubmit = v),
                activeColor: const Color(0xFF10B981),
              ),
            ],
          ),

          if (_showAnswerAfterSubmit) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: Color(0xFF10B981)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sau khi nộp bài, học sinh có thể xem lại từng câu hỏi, '
                      'đáp án đúng và câu mình đã chọn.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF059669),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    final canAssign = !_isAssigning &&
        _selectedIds.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: [
        Expanded(
          flex: 2,
          child: OutlinedButton(
            onPressed: _isAssigning ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textMedium,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Huỷ',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: ElevatedButton(
            onPressed: canAssign ? _handleAssign : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 4,
            ),
            child: _isAssigning
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: AppColors.white, strokeWidth: 2.5))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.send_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _selectedIds.isEmpty
                            ? 'Giao đề'
                            : 'Giao cho ${_selectedIds.length} lớp',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ]),
          ),
        ),
      ]),
    );
  }
}