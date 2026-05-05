import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../data/models/user_model.dart';
import '../../widgets/common/custom_button_nav.dart';
import '../../widgets/common/custom_button_nav_student.dart';
import '../../data/services/fcm_service.dart'; 
import 'personal_info_screen.dart';
import 'change_password_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final profile = ProfileController();
  final auth    = AuthController();
  final fcm    = FcmService();


  static UserModel? _cachedUser;
  static Map<String, dynamic> _cachedStats = {};
  static bool _cachedNotif = false;

  UserModel? _user;
  Map<String, dynamic> stats = {};
  bool _statsLoading = true;
  bool notification  = false;

  @override
  void initState() {
    super.initState();
  
    if (_cachedUser != null) {
      _user         = _cachedUser;
      stats         = _cachedStats;
      notification  = _cachedNotif;
      _statsLoading = _cachedStats.isEmpty;
    }

    _loadData();
  }

  Future<void> _loadData() async {
    final user = await profile.getCurrentUser();
    if (user == null) return;

    // Cập nhật user ngay nếu chưa có trong cache
    if (_cachedUser == null && mounted) {
      setState(() => _user = user);
    }
    _cachedUser = user;

    // Tải song song: thông báo + stats
    final results = await Future.wait([
      fcm.hasToken(),
      _fetchStats(user),
    ]);

    final hasNotif = results[0] as bool;
    final s        = results[1] as Map<String, dynamic>;

    // Lưu vào cache
    _cachedStats = s;
    _cachedNotif = hasNotif;

    if (mounted) {
      setState(() {
        _user         = user;
        stats         = s;
        notification  = hasNotif;
        _statsLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _fetchStats(UserModel user) async {
    if (user.isTeacher) {
      final raw = await profile.getTeacherStats();
      return {
        'val1': '${raw['classes']}', 'lbl1': 'Lớp học',
        'val2': '${raw['students']}', 'lbl2': 'Học sinh',
        'val3': '${raw['exams']}',   'lbl3': 'Đề thi',
      };
    } else {
      final raw = await profile.getStudentStats();
      return {
        'val1': '${raw['classes']}',  'lbl1': 'Lớp học',
        'val2': '${raw['exams']}',    'lbl2': 'Đã nộp',
        'val3': '${raw['avgScore']}', 'lbl3': 'Điểm TB',
      };
    }
  }

  void _refresh() {
    // Khi người dùng chủ động refresh: xóa cache để thấy skeleton
    _cachedStats = {};
    _statsLoading = true;
    _loadData();
  }

  // Xử lý bật/tắt thông báo
  Future<void> _onToggleNotification(bool value) async {
    setState(() => notification = value);

    if (value) {
      final granted = await fcm.requestPermissionAndSaveToken();
      if (!granted && mounted) {
        // Hệ thống từ chối quyền → đổi Switch lại
        setState(() => notification = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Vui lòng cấp quyền thông báo trong Cài đặt điện thoại.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      await fcm.removeToken();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = _user?.isTeacher ?? true;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              header(),
              statsCard(),
              const SizedBox(height: 24),
              if (_user != null) menuCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: isTeacher
          ? const CustomBottomNav(currentIndex: 4)
          : const CustomBottomNavSt(currentIndex: 3),
    );
  }

  Widget header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        children: [
          Container(
            width: 132,
            height: 132,
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, Color(0xFF93C5FD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: const CircleAvatar(
                backgroundColor: Colors.transparent,
                child: Icon(Icons.person_rounded,
                    size: 64, color: Color(0xFFCBD5E1)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Hiện tên ngay khi có, không thì placeholder nhạt
          _user != null
              ? Text(
                  _user!.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                )
              : Container(
                  width: 140,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
          const SizedBox(height: 4),
          _user != null
              ? Text(
                  _user!.email,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                )
              : Container(
                  width: 180,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Text(
              _user == null
                  ? '...'
                  : (_user!.isTeacher ? 'GIÁO VIÊN' : 'HỌC SINH'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget statsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _statsLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(3, (i) => Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 48, height: 22,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 40, height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                )),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  statItem(stats['val1'] ?? '0', stats['lbl1'] ?? ''),
                  Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
                  statItem(stats['val2'] ?? '0', stats['lbl2'] ?? ''),
                  Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
                  statItem(stats['val3'] ?? '0', stats['lbl3'] ?? ''),
                ],
              ),
      ),
    );
  }

  Widget statItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget menuCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            menuItem(
              icon: Icons.person_rounded,
              iconBg: const Color(0xFFEFF6FF),
              iconColor: AppColors.primary,
              title: 'Thông tin cá nhân',
              showArrow: true,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PersonalInfoScreen(
                      user: _user!,
                      onSaved: _refresh,
                    ),
                  ),
                );
              },
            ),
            _divider(),
            //Switch gọi _onToggleNotification thay vì setState trực tiếp
            menuItem(
              icon: Icons.notifications_rounded,
              iconBg: const Color(0xFFEFF6FF),
              iconColor: AppColors.primary,
              title: 'Thông báo',
              trailing: Switch(
                value: notification,
                onChanged: _onToggleNotification,
                activeColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            _divider(),
            menuItem(
              icon: Icons.lock_rounded,
              iconBg: const Color(0xFFEFF6FF),
              iconColor: AppColors.primary,
              title: 'Đổi mật khẩu',
              showArrow: true,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen()),
              ),
            ),
            _divider(),
            menuItem(
              icon: Icons.logout_rounded,
              iconBg: const Color(0xFFFFF1F2),
              iconColor: const Color(0xFFEF4444),
              title: 'Đăng xuất',
              titleColor: const Color(0xFFEF4444),
              onTap: confirmLogout,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget menuItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    Color? titleColor,
    Widget? trailing,
    bool showArrow = false,
    VoidCallback? onTap,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: const Radius.circular(0),
          bottom: isLast ? const Radius.circular(24) : Radius.zero,
        ),
        highlightColor: onTap != null
            ? (titleColor == null
                ? const Color(0xFFF8FAFC)
                : const Color(0xFFFFF1F2))
            : Colors.transparent,
        splashColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: titleColor ?? const Color(0xFF334155),
                  ),
                ),
              ),
              if (trailing != null) trailing,
              if (showArrow && trailing == null)
                const Icon(Icons.chevron_right_rounded,
                    size: 20, color: Color(0xFFCBD5E1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Divider(height: 1, color: Color(0xFFF8FAFC)),
      );

  void confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đăng xuất',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Huỷ',
                style: TextStyle(color: Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Xoá token trước khi đăng xuất
              await fcm.removeToken();
              await auth.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/', (route) => false);
              }
            },
            child: const Text('Đăng xuất',
                style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}