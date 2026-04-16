import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _header(),
              _stats(),
              _menu(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: const Icon(Icons.person, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          const Text(
            'Lê Văn Bình',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'le.van.binh@gmail.com',
            style: TextStyle(fontSize: 14, color: AppColors.textLight),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'HỌC SINH',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _statItem('3', 'Lớp học'),
          _dividerVertical(),
          _statItem('16', 'Bài làm'),
          _dividerVertical(),
          _statItem('7.8', 'Điểm TB'),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _dividerVertical() {
    return Container(
      height: 40,
      width: 1,
      color: AppColors.border,
    );
  }

  Widget _menu(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _menuItem(
            icon: Icons.person_outline,
            title: 'Thông tin cá nhân',
            onTap: () {},
          ),
          _menuItem(
            icon: Icons.notifications_outlined,
            title: 'Thông báo',
            trailing: Switch(
              value: true,
              onChanged: (_) {},
              activeColor: AppColors.primary,
            ),
          ),
          _menuItem(
            icon: Icons.lock_outline,
            title: 'Đổi mật khẩu',
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _menuItem(
            icon: Icons.logout,
            title: 'Đăng xuất',
            color: Colors.red,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
    Color? color,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color ?? AppColors.textDark),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          color: color ?? AppColors.textDark,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing ?? (onTap != null
          ? const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textLight)
          : null),
      onTap: onTap,
    );
  }
}