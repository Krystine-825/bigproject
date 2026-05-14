import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/common/custom_button_nav.dart';
import '../../controllers/class_controller.dart';
import 'create_class_screen.dart';
import 'class_detail_screen.dart';
import '../../data/models/class_model.dart';

class ClassListScreen extends StatefulWidget {
  const ClassListScreen({super.key});

  @override
  State<ClassListScreen> createState() => _ClassListScreenState();
}

class _ClassListScreenState extends State<ClassListScreen> {
  final _searchController = TextEditingController();
  final _classController  = ClassController();
  String _searchText = '';

  // Khởi tạo 1 lần duy nhất — tránh tạo stream mới mỗi lần rebuild khi search
  late final Stream<List<ClassModel>> _classStream;

  @override
  void initState() {
    super.initState();
    _classStream = _classController.streamMyClasses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ClassModel> _filter(List<ClassModel> all) {
    if (_searchText.isEmpty) return all;
    return all
        .where((c) => (c.name ?? '').toLowerCase().contains(_searchText))
        .toList();
  }

  Future<void> _goCreate() async {
    // StreamBuilder tự refresh — push và chờ kết quả (ClassModel hoặc null)
    await Navigator.push<ClassModel>(
      context,
      MaterialPageRoute(builder: (_) => const CreateClassScreen()),
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
            _buildSearchBar(),
            Expanded(child: _buildClassList()),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
    );
  }

  Widget _buildHeader() {
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
            onPressed: _goCreate,
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchText = v.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm lớp học...',
          hintStyle: const TextStyle(color: AppColors.textHint),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint),
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

  Widget _buildClassList() {
    return StreamBuilder<List<ClassModel>>(
      stream: _classStream,
      builder: (context, snapshot) {
        
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

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allData = snapshot.data!;
        final list = _filter(allData);

        // Trống hoàn toàn (chưa có lớp nào trên database/cache)
        if (allData.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.school_outlined,
                    size: 64, color: AppColors.textHint),
                const SizedBox(height: 12),
                const Text(
                  'Chưa có lớp nào',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMedium),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Nhấn + để tạo lớp đầu tiên',
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
              ],
            ),
          );
        }

        // Không tìm thấy khi search
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_off_rounded,
                    size: 52, color: AppColors.textHint),
                const SizedBox(height: 12),
                Text(
                  'Không tìm thấy "$_searchText"',
                  style: const TextStyle(color: AppColors.textMedium),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: list.length,
          itemBuilder: (_, i) => _buildClassCard(list[i]),
        );
      },
    );
  }

  Widget _buildClassCard(ClassModel cls) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClassDetailScreen(
            classId:   cls.id,     // truyền id thật để load member
            className: cls.name,
            classCode: cls.code,
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
                    cls.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mã: ${cls.code}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}