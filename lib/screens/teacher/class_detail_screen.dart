import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_colors.dart';
import '../../widgets/common/custom_button_nav.dart';
import '../../data/models/class_member_model.dart';
import '../../controllers/class_controller.dart';
 
class ClassDetailScreen extends StatefulWidget {

  final String classId;
  final String className;
  final String classCode;
 
  const ClassDetailScreen({
    super.key,
    required this.classId, // THÊM
    required this.className,
    required this.classCode,
  });
 
  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}
 
class _ClassDetailScreenState extends State<ClassDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _searchText = '';
 

  final classController = ClassController();
 

 
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
 
  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }
 

  List<ClassMemberModel> _filterMembers(List<ClassMemberModel> members) {
    if (_searchText.isEmpty) return members;
    return members
        .where((m) =>
            (m.studentName ?? '').toLowerCase().contains(_searchText) ||
            (m.studentEmail ?? '').toLowerCase().contains(_searchText))
        .toList();
  }
 
  
  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[parts.length - 2][0] + parts.last[0]).toUpperCase();
  }
 
 
  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.classCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Đã sao chép mã lớp!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
 
 
  void _showKickDialog(ClassMemberModel member) {
    final name = member.studentName ?? 'học sinh này';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xác nhận',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text('Bạn có chắc muốn kick "$name" khỏi lớp không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Huỷ',
              style: TextStyle(color: AppColors.textMedium),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // THÊM: gọi Firebase kick thật
              try {
                await classController.kickMember(member.id);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã kick "$name" khỏi lớp'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi: $e'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            child: const Text(
              'Kick',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
            _buildCodeCard(),
            _buildTabs(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Thành viên
                  _buildMembersTab(),
                  // Tab 2: Kết quả — làm sau
                  _buildResultsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
    );
  }
 
 
  Widget _buildHeader() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.textDark,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  widget.className,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                // THÊM: đếm thành viên thật từ stream
                StreamBuilder<List<ClassMemberModel>>(
                  stream: classController.streamMembers(widget.classId),
                  builder: (context, snap) {
                    final count = snap.data?.length ?? 0;
                    return Text(
                      '$count học sinh',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMedium,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 48), // giữ tiêu đề căn giữa
        ],
      ),
    );
  }
 
 
  Widget _buildCodeCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Mã lớp
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mã lớp',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.classCode,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const Spacer(),
 
          // Nút chia sẻ
          GestureDetector(
            onTap: _copyCode,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.share_rounded, color: AppColors.primary, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Chia sẻ',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
 

  Widget _buildTabs() {
    return Container(
      color: AppColors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMedium,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        indicatorColor: AppColors.primary,
        indicatorWeight: 2.5,
        tabs: const [
          Tab(text: 'Thành viên'),
          Tab(text: 'Kết quả'),
        ],
      ),
    );
  }
 

  Widget _buildMembersTab() {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(child: _buildMembersList()),
      ],
    );
  }
 
 
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchText = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm học sinh...',
                hintStyle: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textHint,
                  size: 20,
                ),
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
 
 
  Widget _buildMembersList() {
    return StreamBuilder<List<ClassMemberModel>>(
      stream: classController.streamMembers(widget.classId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Lỗi: ${snapshot.error}',
                style: const TextStyle(color: AppColors.textMedium)),
          );
        }
 
        final list = _filterMembers(snapshot.data ?? []);
 
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_off_rounded,
                    size: 52, color: AppColors.textHint),
                const SizedBox(height: 12),
                Text(
                  _searchText.isEmpty
                      ? 'Chưa có học sinh nào trong lớp'
                      : 'Không tìm thấy "$_searchText"',
                  style: const TextStyle(color: AppColors.textMedium),
                ),
              ],
            ),
          );
        }
 
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
          itemCount: list.length,
          itemBuilder: (_, i) => _buildMemberCard(list[i], i),
        );
      },
    );
  }
 
  
  Widget _buildMemberCard(ClassMemberModel member, int index) {
    final colorIndex = index % AppColors.avatarBgColors.length;
    final name  = member.studentName  ?? 'Không rõ';
    final email = member.studentEmail ?? '';
 
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Avatar chữ cái (GIỮ NGUYÊN)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.avatarBgColors[colorIndex],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initials(name),
                style: TextStyle(
                  color: AppColors.avatarTextColors[colorIndex],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
 
          // Tên + email (GIỮ NGUYÊN layout)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
 
          
          GestureDetector(
            onTap: () => _showKickDialog(member),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_remove_rounded,
                color: Colors.red,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
 

  Widget _buildResultsTab() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_rounded, size: 56, color: AppColors.textHint),
          SizedBox(height: 12),
          Text(
            'Chưa có kết quả nào',
            style: TextStyle(color: AppColors.textMedium, fontSize: 15),
          ),
          SizedBox(height: 6),
          Text(
            'Giao đề thi để xem kết quả học sinh',
            style: TextStyle(color: AppColors.textHint, fontSize: 13),
          ),
        ],
      ),
    );
  }
}