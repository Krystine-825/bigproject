import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/validators.dart';
import '../../widgets/common/custom_text_field.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../teacher/dashboard_screen.dart';
import 'profile_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _hidePass = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
              _header(),
              _form(),
              _loginBtn(),
              _divider(),
              _googleBtn(),
              _footer(),
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
              'EduExam',
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

  Widget _header() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chào mừng quay trở lại',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              height: 1.2,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Vui lòng đăng nhập để tiếp tục học tập và thi cử',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textMedium,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _form() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            label: 'Email',
            hint: 'nhapemail@example.com',
            ctrl: _emailCtrl,
            prefixIcon: Icons.mail_outline_rounded,
            type: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          // Dòng label + quên mật khẩu nằm ngoài CustomTextField
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mật khẩu',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textLabel,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ForgotPasswordScreen(),
                  ),
                ),
                child: const Text(
                  'Quên mật khẩu?',
                  style: TextStyle(fontSize: 14, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Dùng CustomTextField nhưng ẩn label vì đã có ở trên
          CustomTextField(
            label: '',
            hint: 'Nhập mật khẩu của bạn',
            ctrl: _passCtrl,
            prefixIcon: Icons.lock_outline_rounded,
            isPass: true,
            hide: _hidePass,
            onToggle: () => setState(() => _hidePass = !_hidePass),
          ),
        ],
      ),
    );
  }

  Widget _loginBtn() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            final error =
                Validators.email(_emailCtrl.text.trim()) ??
                Validators.password(_passCtrl.text.trim());
            if (error != null) {
              _showError(error);
              return;
            }
            // Test tạm với data
            const testEmail = 'test@gmail.com';
            const testPass = '12345678';

            if (_emailCtrl.text.trim() == testEmail &&
                _passCtrl.text.trim() == testPass) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              );
            } else {
              _showError('Email hoặc mật khẩu không đúng');
            }
            // TODO: Firebase login
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: const StadiumBorder(),
            elevation: 4,
            shadowColor: AppColors.primary.withOpacity(0.4),
          ),
          child: const Text(
            'Đăng nhập',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Hoặc đăng nhập với',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
        ],
      ),
    );
  }

  Widget _googleBtn() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton(
          onPressed: () {
            // TODO: Google sign in (v2.0)
            //test trước khi có firevase
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
            );
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuBAsgLvV1j6cQEHf2kmDtBH6paOST5U0hREfLeiLIf2pkv0DSYRE-TaMWjdYjKPWtWkn9MEVgzvehlTgijLrcl8MnggkD2pzYeQ5U0Vt5DDxk4ICcb3lzvikK8esskqBf_zOy4rOKwDgWwEADNJixxGEl77fcRwmvrQRh7pYaZBtpq-aapegJsBsgpc2zSmSIbNyHaMfNF98Ob6G80Zq6hUGQBFhN9lDUoyV-PvYnWSgB11bfBdfXdxNugjXTjIKTtPEeLzg_uq9l8',
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 10),
              const Text(
                'Google',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textLabel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Chưa có tài khoản? ',
            style: TextStyle(fontSize: 14, color: AppColors.textLight),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterScreen()),
            ),
            child: const Text(
              'Đăng ký ngay',
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
