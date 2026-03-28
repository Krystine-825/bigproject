import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_colors.dart';
import '../../widgets/common/custom_button_nav.dart';
 
class ClassDetailScreen extends StatefulWidget {
  // Nhận tên lớp + mã lớp từ màn ClassListScreen truyền sang
  // Khi kết nối Firebase sau thì thay bằng ClassModel
  final String className;
  final String classCode;
 
  const ClassDetailScreen({
    super.key,
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
 

  final List<Map<String, dynamic>> _members = [
    {'name': 'Nguyễn Thành Trung',  'email': 'trung.nt@gmail.com'},
    {'name': 'Lê Hồng Hạnh',        'email': 'hanh.lh@gmail.com'},
    {'name': 'Phan Thanh Tùng',     'email': 'tung.pt@gmail.com'},
    {'name': 'Vũ Minh Anh',         'email': 'anh.vm@gmail.com'},
    {'name': 'Đỗ Kim Liên',         'email': 'lien.dk@gmail.com'},
    {'name': 'Trần Văn Tú',         'email': 'tu.tv@gmail.com'},
    {'name': 'Nguyễn Thị Mai',      'email': 'mai.nt@gmail.com'},
    {'name': 'Hoàng Quốc Bảo',      'email': 'bao.hq@gmail.com'},
  ];
 
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
 
 
  List<Map<String, dynamic>> get _filtered {
    if (_searchText.isEmpty) return _members;
    return _members
        .where((m) =>
            m['name'].toString().toLowerCase().contains(_searchText) ||
            m['email'].toString().toLowerCase().contains(_searchText))
        .toList();
  }
 
  // Lấy 2 chữ cái đầu của tên — hiện trong avatar
  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[parts.length - 2][0] + parts.last[0]).toUpperCase();
  }
 
  // Copy mã lớp vào clipboard
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
 
  // Hộp thoại xác nhận kick — chỉ UI, chưa gọi Firebase
  void _showKickDialog(String name) {
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
            onPressed: () {
              Navigator.pop(context);
              // TODO: gọi ClassController.kickStudent() sau khi kết nối Firebase
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã kick "$name" khỏi lớp'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
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
                Text(
                  '${_members.length} học sinh',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMedium,
                  ),
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
    final list = _filtered;
 
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: list.length,
      itemBuilder: (_, i) => _buildMemberCard(list[i], i),
    );
  }
 
  Widget _buildMemberCard(Map<String, dynamic> member, int index) {
    // Lấy màu từ AppColors theo index — xoay vòng
    final colorIndex = index % AppColors.avatarBgColors.length;
 
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Avatar chữ cái
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.avatarBgColors[colorIndex],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initials(member['name']),
                style: TextStyle(
                  color: AppColors.avatarTextColors[colorIndex],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
 
          // Tên + email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  member['email'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
 
          // Nút kick
          GestureDetector(
            onTap: () => _showKickDialog(member['name']),
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