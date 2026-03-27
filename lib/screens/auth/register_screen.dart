import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/validators.dart';
import '../../widgets/common/custom_text_field.dart';
import 'login_screen.dart';
import '../../../auth_service.dart'; // Import AuthService để gọi Backend

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _hidePass = true;
  bool _hideConfirm = true;
  String _role = 'student';
  bool _agreed = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topBar(),
              _illustration(),
              _titleSection(),
              _roleSelector(),
              _form(),
              _termsCheckbox(),
              _registerBtn(),
              _footer(),
              const SizedBox(height: 32),
            ],
          ),
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
              'Đăng ký tài khoản',
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'assets/images/signup.png',
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _titleSection() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 4),
      child: Column(
        children: [
          Text(
            'Tham gia EduExam',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Vui lòng chọn vai trò và điền thông tin bên dưới để bắt đầu hành trình học tập.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, color: AppColors.textLight, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _roleSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Container(
        height: 52,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.bgLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _roleBtn(
                role: 'student',
                label: 'Học sinh',
                icon: Icons.school_rounded),
            _roleBtn(
                role: 'teacher',
                label: 'Giáo viên',
                icon: Icons.edit_note_rounded),
          ],
        ),
      ),
    );
  }

  Widget _roleBtn({
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
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: selected ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textHint),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _form() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
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
            label: 'Email',
            hint: 'example@gmail.com',
            ctrl: _emailCtrl,
            prefixIcon: Icons.mail_outline_rounded,
            type: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Mật khẩu',
            hint: 'Tối thiểu 8 ký tự',
            ctrl: _passCtrl,
            prefixIcon: Icons.lock_outline_rounded,
            isPass: true,
            hide: _hidePass,
            onToggle: () => setState(() => _hidePass = !_hidePass),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Xác nhận mật khẩu',
            hint: 'Nhập lại mật khẩu',
            ctrl: _confirmCtrl,
            prefixIcon: Icons.lock_outline_rounded,
            isPass: true,
            hide: _hideConfirm,
            onToggle: () =>
                setState(() => _hideConfirm = !_hideConfirm),
          ),
        ],
      ),
    );
  }

  Widget _termsCheckbox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: _agreed,
              onChanged: (v) => setState(() => _agreed = v ?? false),
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
                    height: 1.5),
                children: [
                  TextSpan(text: 'Tôi đồng ý với '),
                  TextSpan(
                    text: 'Điều khoản dịch vụ',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: ' và '),
                  TextSpan(
                    text: 'Chính sách bảo mật',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: ' của EduExam.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Khối code nút bấm chứa logic Đăng ký (Backend)
  Widget _registerBtn() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () async {
            final error =
                Validators.name(_nameCtrl.text.trim()) ??
                Validators.email(_emailCtrl.text.trim()) ??
                Validators.password(_passCtrl.text.trim()) ??
                Validators.confirmPassword(
                    _passCtrl.text.trim(),
                    _confirmCtrl.text.trim()) ??
                (_agreed
                    ? null
                    : 'Vui lòng đồng ý với điều khoản dịch vụ');
            
            if (error != null) {
              _showError(error);
              return;
            }

            
            String? result = await AuthService().register(
              email: _emailCtrl.text.trim(),
              password: _passCtrl.text.trim(),
              fullName: _nameCtrl.text.trim(),
              role: _role, 
            );

           
            if (result == "Success") {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Đăng ký thành công!"),
                  backgroundColor: AppColors.success,
                ));
                Navigator.pushReplacement(
                  context, 
                  MaterialPageRoute(builder: (_) => const LoginScreen())
                );
              }
            } else {
              _showError(result!);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28)),
            elevation: 4,
            shadowColor: AppColors.primary.withOpacity(0.4),
          ),
          child: const Text(
            'Đăng ký ngay',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Đã có tài khoản? ',
            style:
                TextStyle(fontSize: 14, color: AppColors.textLight),
          ),
          GestureDetector(
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
            child: const Text(
              'Đăng nhập',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}