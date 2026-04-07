import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../data/models/exam_model.dart';
import '../../controllers/exam_controller.dart';

class AssignExamScreen extends StatefulWidget {
  final ExamModel exam;
  const AssignExamScreen({super.key, required this.exam});

  @override
  State<AssignExamScreen> createState() => _AssignExamScreenState();
}

class _AssignExamScreenState extends State<AssignExamScreen> {
  final _controller = ExamController();

  
  List<Map<String, String>> _classes      = [];
  String?                   _selectedClassId;
  String?                   _selectedClassName;
  bool                      _isLoadingClasses = true;

  int      _durationMinutes = 45;   // thời gian làm bài
  DateTime _openAt  = DateTime.now().add(const Duration(hours: 1));
  DateTime _closeAt = DateTime.now().add(const Duration(days: 7));
  int      _maxAttempts = 1;        // 1 hoặc 2 lần

  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final list = await _controller.getMyClasses();
      setState(() {
        _classes          = list;
        _isLoadingClasses = false;
        if (list.isNotEmpty) {
          _selectedClassId   = list.first['id'];
          _selectedClassName = list.first['name'];
        }
      });
    } catch (_) {
      setState(() => _isLoadingClasses = false);
    }
  }

  //giao đề
  Future<void> _handleAssign() async {
    if (_selectedClassId == null) {
      _snack('Vui lòng chọn lớp', isError: true);
      return;
    }
    if (_closeAt.isBefore(_openAt)) {
      _snack('Thời gian hết hạn phải sau thời gian mở đề', isError: true);
      return;
    }

    setState(() => _isAssigning = true);
    try {
      await _controller.assignExam(
        examId:          widget.exam.id,
        classId:         _selectedClassId!,
        durationMinutes: _durationMinutes,
        openAt:          _openAt,
        closeAt:         _closeAt,
        maxAttempts:     _maxAttempts,
      );
      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isAssigning = false);
    }
  }

  void _showSuccessDialog() {
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
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.assignment_turned_in_rounded,
              size: 56, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(widget.exam.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16,
                  fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 6),
          Text('đã được giao cho lớp $_selectedClassName',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13,
                  color: AppColors.textMedium)),
        ]),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Đóng dialog + về kho đề (pop hết stack đến màn kho đề)
                Navigator.of(context)
                  ..pop()            // đóng dialog
                  ..popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Về kho đề'),
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
                  // Info đề
                  _buildExamInfoCard(),
                  const SizedBox(height: 20),
                  // Chọn lớp
                  _buildSectionTitle('Chọn lớp'),
                  const SizedBox(height: 10),
                  _buildClassPicker(),
                  const SizedBox(height: 20),
                  // Thời gian
                  _buildSectionTitle('Cài đặt thời gian'),
                  const SizedBox(height: 10),
                  _buildTimeCard(),
                  const SizedBox(height: 20),
                  // Số lần làm
                  _buildSectionTitle('Số lần làm bài'),
                  const SizedBox(height: 10),
                  _buildAttemptsCard(),
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
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('${widget.exam.questions.length} câu hỏi',
                style: const TextStyle(fontSize: 12,
                    color: AppColors.primary)),
          ],
        )),
      ]),
    );
  }

 
  Widget _buildClassPicker() {
    if (_isLoadingClasses) {
      return const Center(
          child: Padding(padding: EdgeInsets.all(20),
              child: CircularProgressIndicator()));
    }
    if (_classes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.white,
            borderRadius: BorderRadius.circular(16)),
        child: const Center(child: Text('Bạn chưa có lớp nào',
            style: TextStyle(color: AppColors.textMedium))),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedClassId,
          isExpanded: true,
          style: const TextStyle(fontSize: 14, color: AppColors.textDark),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textMedium),
          items: _classes.map((c) => DropdownMenuItem(
            value: c['id'],
            child: Text(c['name']!),
          )).toList(),
          onChanged: (v) => setState(() {
            _selectedClassId   = v;
            _selectedClassName = _classes
                .firstWhere((c) => c['id'] == v)['name'];
          }),
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

        // Thời gian làm bài
        _timeRow(
          icon: Icons.timer_outlined,
          label: 'Thời gian làm bài',
          value: '$_durationMinutes phút',
          child: Row(children: [
            _smallBtn(Icons.remove_rounded,
                _durationMinutes > 10
                    ? () => setState(() => _durationMinutes -= 5)
                    : null),
            SizedBox(width: 52,
                child: Text('$_durationMinutes ph',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark))),
            _smallBtn(Icons.add_rounded,
                _durationMinutes < 180
                    ? () => setState(() => _durationMinutes += 5)
                    : null),
          ]),
        ),
        const Divider(height: 1),

        // Thời gian mở đề
        _timeRow(
          icon: Icons.lock_open_rounded,
          label: 'Mở đề lúc',
          value: _formatDateTime(_openAt),
          child: IconButton(
            onPressed: () => _pickDateTime(
              initial: _openAt,
              onPicked: (dt) => setState(() => _openAt = dt),
            ),
            icon: const Icon(Icons.edit_calendar_rounded,
                color: AppColors.primary, size: 20),
          ),
        ),
        const Divider(height: 1),

        // Thời gian hết hạn
        _timeRow(
          icon: Icons.lock_clock_outlined,
          label: 'Hết hạn lúc',
          value: _formatDateTime(_closeAt),
          child: IconButton(
            onPressed: () => _pickDateTime(
              initial: _closeAt,
              onPicked: (dt) => setState(() => _closeAt = dt),
            ),
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

    onPicked(DateTime(date.year, date.month, date.day,
        time.hour, time.minute));
  }

  String _formatDateTime(DateTime dt) {
    final pad = (int n) => n.toString().padLeft(2, '0');
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
                    style: TextStyle(fontSize: 12,
                        color: AppColors.textHint)),
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

  
  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: [

        // Nút huỷ → về kho đề
        Expanded(
          flex: 2,
          child: OutlinedButton(
            onPressed: _isAssigning
                ? null
                : () => Navigator.of(context)
                    .popUntil((route) => route.isFirst),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textMedium,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Huỷ', style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 12),

        // Nút giao đề
        Expanded(
          flex: 3,
          child: ElevatedButton(
            onPressed: (_isAssigning || _selectedClassId == null)
                ? null
                : _handleAssign,
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
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: AppColors.white, strokeWidth: 2.5))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Giao đề', style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                    ]),
          ),
        ),
      ]),
    );
  }
}