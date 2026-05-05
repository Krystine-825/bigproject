import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../controllers/results_controller.dart';
import '../../widgets/common/custom_button_nav_student.dart';

class StudentResultsScreen extends StatefulWidget {
  const StudentResultsScreen({super.key});

  @override
  State<StudentResultsScreen> createState() => _StudentResultsScreenState();
}

class _StudentResultsScreenState extends State<StudentResultsScreen> {
  final ctrl = StudentResultsController();

  static const int pageSize = 4;
  int currentPage = 1;

  double _avgScore(List<Map<String, dynamic>> results) => results.isEmpty
      ? 0.0
      : double.parse(
          (results.fold(0.0, (s, r) => s + ((r['score'] as num).toDouble())) /
                  results.length)
              .toStringAsFixed(1),
        );

  int _totalClasses(List<Map<String, dynamic>> results) =>
      results.map((r) => r['classId'] as String).toSet().length;

  int _totalPages(int total) =>
      total == 0 ? 1 : (total / pageSize).ceil();

  List<Map<String, dynamic>> _pageItems(List<Map<String, dynamic>> results) {
    final start = (currentPage - 1) * pageSize;
    final end = (start + pageSize).clamp(0, results.length);
    return results.sublist(start, end);
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} tuần trước';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Map<String, dynamic> _gradeInfo(double score) {
    if (score >= 9) return {
      'label': 'Xuất sắc', 'color': const Color(0xFF22C55E),
      'bg': const Color(0xFFECFDF5), 'icon': Icons.verified_rounded,
    };
    if (score >= 8) return {
      'label': 'Giỏi', 'color': const Color(0xFF22C55E),
      'bg': const Color(0xFFECFDF5), 'icon': Icons.check_circle_rounded,
    };
    if (score >= 6.5) return {
      'label': 'Khá', 'color': const Color(0xFFF97316),
      'bg': const Color(0xFFFFF7ED), 'icon': Icons.star_rounded,
    };
    if (score >= 5) return {
      'label': 'Đạt', 'color': const Color(0xFF3B82F6),
      'bg': const Color(0xFFEFF6FF), 'icon': Icons.thumb_up_rounded,
    };
    return {
      'label': 'Yếu', 'color': const Color(0xFFEF4444),
      'bg': const Color(0xFFFFF1F2), 'icon': Icons.warning_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ctrl.streamResults(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Lỗi tải dữ liệu'));
          }

          // Firestore tự cache → dùng data trực tiếp, không chặn bằng waiting
          final results = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: () async {
              // Stream tự cập nhật, chỉ cần reset page
              setState(() => currentPage = 1);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              children: [
                _overviewCard(results),
                const SizedBox(height: 20),
                _filterRow(),
                const SizedBox(height: 12),
                if (results.isEmpty)
                  _buildEmpty()
                else ...[
                  ..._pageItems(results).map(_resultCard),
                  const SizedBox(height: 8),
                  _pagination(results.length),
                ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const CustomBottomNavSt(currentIndex: 2),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: const Text(
        'Kết quả học tập',
        style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B)),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFF1F5F9)),
      ),
    );
  }

  Widget _overviewCard(List<Map<String, dynamic>> results) {
    final avg = _avgScore(results);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 128,
            height: 128,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(128, 128),
                  painter: _CircleProgressPainter(
                    progress: (avg / 10.0).clamp(0.0, 1.0),
                    bgColor: const Color(0xFFF1F5F9),
                    fgColor: AppColors.primary,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      avg.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          height: 1),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'TRUNG BÌNH',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 1.2),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Điểm trung bình',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
          Text(
            '${results.length} bài đã nộp · ${_totalClasses(results)} lớp',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _filterRow() {
    return const Row(
      children: [
        Text(
          'GẦN ĐÂY',
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF94A3B8),
              letterSpacing: 1.2),
        ),
      ],
    );
  }

  Widget _resultCard(Map<String, dynamic> item) {
    final score = item['score'] as double;
    final grade = _gradeInfo(score);
    final submittedAt = item['submittedAt'] as DateTime;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: grade['bg'] as Color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(grade['icon'] as IconData,
                size: 28, color: grade['color'] as Color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['examName'] as String,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _infoChip(Icons.school_rounded, item['className'] as String),
                    const SizedBox(width: 14),
                    _infoChip(Icons.history_rounded, _timeAgo(submittedAt)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${score.toStringAsFixed(1)}/10',
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    height: 1),
              ),
              const SizedBox(height: 4),
              Text(
                (grade['label'] as String).toUpperCase(),
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: grade['color'] as Color,
                    letterSpacing: 0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _pagination(int total) {
    final totalPages = _totalPages(total);
    if (totalPages <= 1) return const SizedBox.shrink();

    int startPage = math.max(1, currentPage - 2);
    int endPage = math.min(totalPages, startPage + 4);
    if (endPage - startPage < 4) startPage = math.max(1, endPage - 4);
    final pages = List.generate(endPage - startPage + 1, (i) => startPage + i);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pageArrowBtn(
            icon: Icons.chevron_left_rounded,
            enabled: currentPage > 1,
            onTap: () => setState(() => currentPage--),
          ),
          const SizedBox(width: 4),
          ...pages.map((p) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _pageNumberBtn(p),
              )),
          const SizedBox(width: 4),
          _pageArrowBtn(
            icon: Icons.chevron_right_rounded,
            enabled: currentPage < totalPages,
            onTap: () => setState(() => currentPage++),
          ),
        ],
      ),
    );
  }

  Widget _pageNumberBtn(int page) {
    final isActive = page == currentPage;
    return GestureDetector(
      onTap: () => setState(() => currentPage = page),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border:
              isActive ? null : Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: isActive
              ? [BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2))]
              : null,
        ),
        child: Center(
          child: Text('$page',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : const Color(0xFF475569))),
        ),
      ),
    );
  }

  Widget _pageArrowBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Icon(icon,
            size: 22,
            color: enabled
                ? const Color(0xFF475569)
                : const Color(0xFFCBD5E1)),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, size: 56, color: Color(0xFFCBD5E1)),
          SizedBox(height: 16),
          Text('Chưa có bài nộp nào',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8))),
          SizedBox(height: 4),
          Text('Bài làm sau khi nộp sẽ hiển thị ở đây',
              style:
                  TextStyle(fontSize: 12, color: Color(0xFFCBD5E1))),
        ],
      ),
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color bgColor;
  final Color fgColor;

  const _CircleProgressPainter({
    required this.progress,
    required this.bgColor,
    required this.fgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;
    const strokeWidth = 8.0;

    canvas.drawCircle(center, radius,
        Paint()
          ..color = bgColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = fgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CircleProgressPainter old) => old.progress != progress;
}