// widgets/common/custom_bottom_nav.dart
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_navigator_student.dart';

class CustomBottomNavSt extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNavSt({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.95),
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _navItem(context, 0, Icons.home_rounded, 'Trang chủ'),
              _navItem(context, 1, Icons.school_rounded, 'Lớp học'),
              _navItem(context, 2, Icons.leaderboard_rounded, 'Kết quả'),
              _navItem(context, 3, Icons.person_rounded, 'Cá nhân'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, int index, IconData icon, String label) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => AppNavigator.handleBottomNavTapSt(context, index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 26,
            color: isSelected ? AppColors.primary : AppColors.textHint,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}