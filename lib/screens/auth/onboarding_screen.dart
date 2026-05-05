import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _logo(),
            _illustration(),
            _content(),
            _buttons(context),
          ],
        ),
      ),
    );
  }

  Widget _logo() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.menu_book_rounded,
                color: AppColors.white, size: 28),
          ),
          const SizedBox(width: 10),
          const Text(
            'EduExam',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _illustration() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/images/onboard.png',
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        ),
      ),
    );
  }

  Widget _content() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(32, 24, 32, 8),
      child: Column(
        children: [
          Text(
            'Nâng tầm tri thức',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              height: 1.3,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Học tập thông minh hơn mỗi ngày.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textLight,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buttons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 40),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text(
                'Bắt đầu ngay',
                style:
                TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 6,
                shadowColor: AppColors.primary.withOpacity(0.4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Bạn đã có tài khoản? ',
                style:
                TextStyle(color: AppColors.textHint, fontSize: 14),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: const Text(
                  'Đăng nhập',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}