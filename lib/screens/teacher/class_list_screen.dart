import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/common/custom_button_nav.dart';
import '../../core/app_navigator.dart';
import 'create_class_screen.dart';
import 'class_detail_screen.dart';
import '../../controllers/class_controller.dart';
import '../../data/models/class_model.dart';
 
class ClassListScreen extends StatefulWidget {
  const ClassListScreen({super.key});
 
  @override
  State<ClassListScreen> createState() => _ClassListScreenState();
}
 
class _ClassListScreenState extends State<ClassListScreen> {
  final searchController = TextEditingController();
  int _currentNavIndex = 1;
  String _searchText = '';
 
  final _classCtrl = ClassController();
 
  /*final List<Map<String, dynamic>> _classList = [
    {'name': '12A1 — B1',             'code': 'AB12C3', 'students': 18, 'examsAssigned': 12},
    {'name': '11B2 — A2',             'code': 'XY34Z5', 'students': 25, 'examsAssigned': 8},
    {'name': '10C1 — Basic',          'code': 'MN56P7', 'students': 32, 'examsAssigned': 15},
    {'name': 'IELTS Master — Evening', 'code': 'QR78S9', 'students': 12, 'examsAssigned': 24},
  ];*/
 
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
 
  // Lọc danh sách theo ô search
  /*List<Map<String, dynamic>> get _filtered {
    if (_searchText.isEmpty) return _classList;
    return _classList
        .where((c) => c['name'].toString().toLowerCase().contains(_searchText))
        .toList();
  }*/
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      body: SafeArea(
        child: Column(
          children: [
            header(),
            searchBar(),
            Expanded(child: classList()),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(currentIndex: _currentNavIndex),
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
              'Lớp học',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateClassScreen()),
            ),
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
        onChanged: (v) => setState(() => _searchText = v.toLowerCase()), // THÊM
        decoration: InputDecoration(
          hintText: 'Tìm kiếm lớp học...',
          hintStyle: TextStyle(color: AppColors.textHint),
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.textHint),
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
 
  Widget classList() {
    return StreamBuilder<List<ClassModel>>(
      stream: _classCtrl.getMyClassesStream(), // Lấy luồng dữ liệu thật từ Firebase
      builder: (context, snapshot) {
        // Đang tải dữ liệu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        // Nếu có lỗi
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
        }

        final classes = snapshot.data ?? [];

        // Lọc danh sách theo chữ tìm kiếm
        final filteredList = classes.where((c) {
          if (_searchText.isEmpty) return true;
          return c.name.toLowerCase().contains(_searchText);
        }).toList();

        // Không có dữ liệu
        if (filteredList.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_off_rounded, size: 52, color: AppColors.textHint),
                const SizedBox(height: 12),
                Text(
                  _searchText.isEmpty ? 'Bạn chưa tạo lớp học nào' : 'Không tìm thấy "$_searchText"',
                  style: const TextStyle(color: AppColors.textMedium),
                ),
              ],
            ),
          );
        }

        // Vẽ danh sách lớp thật
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: filteredList.length,
          itemBuilder: (_, index) => classCard(filteredList[index]),
        );
      },
    );
  }
 
  Widget classCard(ClassModel classItem) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClassDetailScreen(
            className: classItem.name, // Sửa thành .name
            classCode: classItem.code, // Sửa thành .code
          ),
        ),
      ),
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
        child: Row(
          children: [
            // Icon lớp học
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classItem.name, // Sửa thành .name
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mã: ${classItem.code}', // Sửa thành .code
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      infoRow(
                        Icons.groups_rounded,
                        '0 học sinh', // Tạm thời để 0 vì ta chưa lấy số HS thật
                      ),
                      const SizedBox(width: 20),
                      infoRow(
                        Icons.assignment_rounded,
                        '0 đề', // Tạm thời để 0
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 26),
          ],
        ),
      ),
    );
  }
 
  Widget infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.textMedium),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(fontSize: 13.5, color: AppColors.textMedium),
        ),
      ],
    );
  }
}