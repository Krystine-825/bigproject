import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/common/custom_button_nav_student.dart';
import 'join_class_screen.dart';
import '../../controllers/class_controller.dart';
import 'student_class_detail_screen.dart';

class StudentClassListScreen extends StatefulWidget {
  const StudentClassListScreen({super.key});

  @override
  State<StudentClassListScreen> createState() => _StudentClassListScreenState();
}

class _StudentClassListScreenState extends State<StudentClassListScreen> {
  final searchController = TextEditingController();
  final  classController = ClassController();
  String searchText ='';
  

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> goJoin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const JoinClassScreen()),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            header(),
            searchBar(),
            filterTabs(),
            Expanded(child: _classList()),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavSt(
        currentIndex: 1,
      ), // Tab Lớp học đang active
    );
  }

  Widget header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          const SizedBox(width: 40),
          const Expanded(
            child: Text(
              'Lớp học ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          IconButton(
            onPressed: goJoin,
            icon: const Icon(Icons.add_rounded),
            color: AppColors.primary,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: TextField(
        controller: searchController,
        onChanged: (m) => setState(() => searchText = m.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm lớp học...',
          hintStyle: const TextStyle(color: AppColors.textHint),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textHint,
          ),
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget filterTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            filterChip('Tất cả (3)', true),
            const SizedBox(width: 8),
            filterChip('Chưa xong (2)', false),
            const SizedBox(width: 8),
            filterChip('Xong (1)', false),
          ],
        ),
      ),
    );
  }

  Widget filterChip(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.white,
        borderRadius: BorderRadius.circular(999),
        border: isActive ? null : Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.white : AppColors.textDark,
        ),
      ),
    );
  }

  Widget _classList() {
   return StreamBuilder<List<Map<String, dynamic>>>(
      stream: classController.streamStudentClasses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
           return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: Colors.redAccent),
                const SizedBox(height: 12),
                Text(
                  'Lỗi tải dữ liệu\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMedium),
                ),
              ],
            ),
          );
        }
        final classes = snapshot.data ?? [];
        final filteredClasses = searchText.isEmpty?classes:classes.where((cls) {
          final name = cls['name'].toString().toLowerCase();
          return name.contains(searchText);
        }).toList();
        
        //chưa tham gia lớp nào 
        if (classes.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.school_outlined,
                    size: 64, color: AppColors.textHint),
                const SizedBox(height: 12),
                const Text(
                  'Chưa tham gia lớp nào',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Nhấn + để tham gia lớp học',
                  style: TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
              ],
            ),
          );
        }
 
       // không tìm thấy lớp nào sau khi search
          if (filteredClasses.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_off_rounded,
                    size: 52, color: AppColors.textHint),
                const SizedBox(height: 12),
                Text(
                  'Không tìm thấy "$searchText"',
                  style: const TextStyle(color: AppColors.textMedium),
                ),
              ],
            ),
          );
        }
 

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: filteredClasses.length,
          itemBuilder: (context, index) {
            final cls = filteredClasses[index];
            return classCard(cls);
          },
        );
      },
    );
  }

 Widget classCard(Map<String, dynamic> cls) {
  final isCompleted = (cls['status'] ?? 'inProgress') == 'completed';
  final newCount = cls['newCount'] as int? ?? 0;

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentClassDetailScreen(
            classId: cls['classId'] as String,           // ← Truyền classId quan trọng nhất
            className: cls['name'] as String,
            teacherName: cls['teacher'] as String,
            // Có thể truyền thêm nếu sau này cần
            code: cls['code'] as String? ?? '',
          ),
        ),
      );
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.school_rounded,
                  color: isCompleted
                      ? const Color(0xFF10B981)
                      : AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cls['name'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        if (newCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$newCount mới',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF9800),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cls['teacher'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mã: ${cls['code']}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMedium,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textHint,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget bottomNav() {
    return const CustomBottomNavSt(currentIndex: 1); // Tab Lớp học đang active
  }
}
