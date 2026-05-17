import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/common/custom_button_nav.dart';
import '../../data/models/exam_model.dart';
import '../../controllers/exam_controller.dart';
import '../../data/services/class_cache_service.dart';
import 'exam_detail_screen.dart';

class ExamBankScreen extends StatefulWidget {
  const ExamBankScreen({super.key});

  @override
  State<ExamBankScreen> createState() => _ExamBankScreenState();
}

class _ExamBankScreenState extends State<ExamBankScreen> {
  final ExamController _controller = ExamController();

  int    _selectedTab  = 0;
  String _searchQuery  = '';

  // Khai báo biến lưu Stream để tối ưu hiệu năng
  late final Stream<List<ExamModel>> _examStream;

  @override
  void initState() {
    super.initState();
    // Khởi tạo Stream 1 lần duy nhất để tránh load lại khi gõ tìm kiếm
    _examStream = _controller.streamMyExams();
    
    // Warm cache lớp học ngay khi màn này load —
    // khi user bấm vào đề bất kỳ, AssignExamScreen sẽ hiển thị danh sách lớp tức thì
    ClassCacheService.instance.warmUp();
  }

  // Xác nhận và thực hiện xóa đề (chỉ dùng cho đề chưa giao)
  Future<void> _confirmDelete(ExamModel exam) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xóa đề thi?', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc muốn xóa đề "${exam.name}"? \nHành động này sẽ xóa vĩnh viễn đề thi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textMedium)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Xóa ngay', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _controller.deleteExam(exam.id); 
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa đề thi thành công'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  //  Xác nhận và thực hiện Thu hồi đề (dùng cho đề đã giao)
  Future<void> _confirmRevoke(ExamModel exam) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Thu hồi đề thi?', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc muốn thu hồi đề "${exam.name}" từ tất cả các lớp?\n\nToàn bộ bài làm của học sinh sẽ bị xóa sạch, và đề thi sẽ quay trở lại mục "Chưa giao" để bạn chỉnh sửa hoặc giao lại.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textMedium)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Thu hồi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Hiển thị vòng xoay loading mờ để chờ xử lý thu hồi (vì có thể có nhiều lớp)
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );

      try {
        // Lặp qua tất cả các lớp đang được giao đề này và thu hồi lần lượt
        for (final assignment in exam.assignments) {
          await _controller.unassignExam(examId: exam.id, classId: assignment.classId);
        }
        
        if (mounted) {
          Navigator.pop(context); // Đóng dialog loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã thu hồi đề thi thành công! Bạn có thể giao lại ngay.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Đóng dialog loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi thu hồi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Kho đề',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (v) =>
                  setState(() => _searchQuery = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm đề thi...',
                hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 15),
                prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          // Bộ lọc Tab
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              _buildTab('Tất cả', 0),
              _buildTab('Đã giao', 1),
              _buildTab('Chưa giao', 2),
            ]),
          ),

          Expanded(
            child: StreamBuilder<List<ExamModel>>(
              stream: _examStream, 
              builder: (context, snapshot) {
                
                // Chặn lỗi trước
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Đã xảy ra lỗi: ${snapshot.error}', 
                        style: const TextStyle(color: Colors.red)),
                  );
                }

                // Chặn Loading bằng !hasData (Tận dụng Cache)
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Ép kiểu 
                final allExams = snapshot.data!;
                final filtered = _filterExams(allExams);

                if (filtered.isEmpty) {
                  return _buildEmptyState(allExams.isEmpty);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _buildExamCard(filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 3),
    );
  }

  List<ExamModel> _filterExams(List<ExamModel> exams) {
    var list = exams;
    if (_selectedTab == 1) list = list.where((e) => e.isAssigned).toList();
    if (_selectedTab == 2) list = list.where((e) => !e.isAssigned).toList();
    if (_searchQuery.isNotEmpty) {
      list = list.where((e) =>
          e.name.toLowerCase().contains(_searchQuery)).toList();
    }
    return list;
  }

  Widget _buildTab(String title, int index) {
    final selected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(
                color: selected ? AppColors.primary : Colors.transparent,
                width: 3)),
          ),
          child: Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.textMedium,
              )),
        ),
      ),
    );
  }

  Widget _buildExamCard(ExamModel exam) {
    final isAssigned = exam.isAssigned;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ExamDetailScreen(exam: exam)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(exam.name,
                      style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Nhãn trạng thái
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: isAssigned ? AppColors.successBg : AppColors.bgLight,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isAssigned ? 'Đã giao' : 'Chưa giao',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isAssigned ? AppColors.success : AppColors.textHint),
                      ),
                    ),
                    
                    // Phân luồng hiển thị nút Xóa và Thu hồi
                    if (!isAssigned) ...[
                      const SizedBox(height: 12),
                      // Nút xóa (chỉ khi Chưa giao)
                      Tooltip(
                        message: 'Xóa đề thi vĩnh viễn',
                        child: GestureDetector(
                          onTap: () => _confirmDelete(exam),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      // Nút thu hồi (chỉ khi Đã giao)
                      Tooltip(
                        message: 'Thu hồi đề thi',
                        child: GestureDetector(
                          onTap: () => _confirmRevoke(exam),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.settings_backup_restore_rounded, color: Colors.red, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoItem(Icons.description_outlined, '${exam.questions.length} câu hỏi'),
                _infoItem(Icons.timer_outlined, '${exam.durationMinutes ?? 45} phút'),
                if (exam.assignments.isNotEmpty)
                  _infoItem(Icons.groups_rounded, '${exam.assignments.length} lớp'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: 18, color: AppColors.textLight),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textMedium)),
    ]);
  }

  Widget _buildEmptyState(bool isBankEmpty) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.description_outlined, size: 56, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(
            isBankEmpty ? 'Chưa có đề thi nào' : 'Không tìm thấy đề thi khớp với tìm kiếm',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textMedium),
          ),
        ],
      ),
    );
  }
}