import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/common/custom_text_field.dart';
import '../teacher/dashboard_screen.dart';
//import '../student/student_home_screen.dart';
import '../../../auth_service.dart'; 
import '../../../main.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _role = 'student';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _illustration(),
                    _titleSection(),
                    _roleSelector(),
                    _form(),
                  ],
                ),
              ),
            ),
            _submitBtn(),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            color: AppColors.textDark,
          ),
          const Expanded(
            child: Text(
              'Hoàn thiện hồ sơ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _illustration() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'assets/images/profile.png',
          width: double.infinity,
          height: 160,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _titleSection() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Text(
            'Sẵn sàng để bắt đầu?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Chọn vai trò và bổ sung thông tin để tiếp tục.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMedium,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bạn là?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textLabel,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _roleCard(
                role: 'student',
                label: 'Học sinh',
                icon: Icons.school_rounded),
            const SizedBox(width: 16),
            _roleCard(
                role: 'teacher',
                label: 'Giáo viên',
                icon: Icons.co_present_rounded),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _roleCard({
    required String role,
    required String label,
    required IconData icon,
  }) {
    final selected = _role == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon,
                    size: 26,
                    color: selected ? AppColors.white : AppColors.textLight),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: selected ? AppColors.primary : AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _form() {
    return Column(
      children: [
        CustomTextField(
          label: 'Họ và tên',
          hint: 'Nhập họ và tên của bạn',
          ctrl: _nameCtrl,
          prefixIcon: Icons.person_outline_rounded,
          type: TextInputType.name,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Số điện thoại (không bắt buộc)',
          hint: '0123 456 789',
          ctrl: _phoneCtrl,
          prefixIcon: Icons.call_outlined,
          type: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _submitBtn() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: () async {
            // 1. Thu thập dữ liệu từ các ô nhập liệu
            String name = _nameCtrl.text.trim();
            String phone = _phoneCtrl.text.trim();
            
            // (Bạn có thể thêm hàm kiểm tra Validator ở đây nếu cần, ví dụ bắt buộc nhập tên)
            
            // 2. Gọi hàm lưu lên Firestore
            await AuthService().completeUserProfile(
              name: name,
              phone: phone,
              role: _role, // Biến _role này thay đổi khi người dùng click vào thẻ Giáo viên/Học sinh
            );

            if (!context.mounted) return;
            
            // 3. Đăng ký thành công -> Đẩy về AuthWrapper
            // AuthWrapper sẽ quét Database, thấy role vừa lưu và đẩy họ vào đúng màn hình!
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const AuthWrapper()),
              (route) => false,
            );
          },
          icon: const Icon(Icons.arrow_forward_rounded),
          label: const Text(
            'Bắt đầu ngay',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            shadowColor: AppColors.primary.withOpacity(0.3),
          ),
        ),
      ),
    );
  }
}