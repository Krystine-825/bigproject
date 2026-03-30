import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/common/custom_button_nav_student.dart';
import 'join_class_screen.dart';
import '../../controllers/class_controller.dart';
import '../../data/models/class_model.dart';

class StudentClassListScreen extends StatefulWidget {
  const StudentClassListScreen({super.key});

  @override
  State<StudentClassListScreen> createState() => _StudentClassListScreenState();
}

class _StudentClassListScreenState extends State<StudentClassListScreen> {
  final searchController = TextEditingController();
  final _classCtrl = ClassController();

  /*final List<Map<String, dynamic>> classList = [
    {
      'name': '12A1 - B1',
      'teacher': 'GV: Nguyễn Văn A',
      'exams': 8,
      'completed': '6/8',
      'status': 'inProgress',
      'newCount': 2,
    },
    {
      'name': '11B2 - A2',
      'teacher': 'GV: Trần Thị B',
      'exams': 5,
      'completed': '4/5',
      'status': 'inProgress',
      'newCount': 1,
    },
    {
      'name': '10C3 - B2',
      'teacher': 'GV: Lê Văn C',
      'exams': 6,
      'completed': '6/6',
      'status': 'completed',
      'newCount': 0,
    },
  ];*/



  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
            onPressed: () {
              // TODO: Chuyển sang màn tạo lớp
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JoinClassScreen()),
              );
            },
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
    return StreamBuilder<List<ClassModel>>(
      stream: _classCtrl.getStudentClassesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        final classes = snapshot.data ?? [];
        if (classes.isEmpty) {
          return const Center(
            child: Text('Bạn chưa tham gia lớp học nào.', style: TextStyle(color: AppColors.textMedium)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: classes.length,
          itemBuilder: (context, index) => classCard(classes[index]), // Truyền ClassModel thật
        );
      },
    );
  }

  Widget classCard(ClassModel cls) {
    
    final bool isCompleted = false;
    final int newCount = 0; 
    final int exams = 0;

    return Container(
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
                            cls.name, // Đã đổi thành .name
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        if (newCount > 0) // Dùng biến cục bộ ở trên
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
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
                      'Mã lớp: ${cls.code}', // Đã đổi thành .code
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMedium,
                        fontWeight: FontWeight.w600
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
                '$exams đề thi',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMedium,
                ),
              ),
              if (isCompleted)
                const Text(
                  'Đã hoàn tất',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                )
              else
                const Text(
                  'Chưa có đề',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
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
    );
  }
        
  }

  Widget bottomNav() {
    return const CustomBottomNavSt(currentIndex: 1); // Tab Lớp học đang active
  }

