// core/navigation/app_navigator.dart
import 'package:flutter/material.dart';
import '../../screens/teacher/dashboard_screen.dart';
import '../../screens/teacher/class_list_screen.dart';

class AppNavigator {
  static void handleBottomNavTap(BuildContext context, int index) {
    switch (index) {
      case 0: // Trang chủ (Dashboard)
        _goToDashboard(context);
        break;

      case 1: // Lớp học
        _goToClassList(context);
        break;

      case 2: // Tạo đề
        break;

      case 3: // Kho đề
        break;

      case 4: // Cá nhân
        break;
    }
  }

  // Hàm riêng để quay về Dashboard
  static void _goToDashboard(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const DashboardScreen(),
        settings: const RouteSettings(name: '/dashboard'),
      ),
      (route) => route.isFirst,        // Giữ lại màn hình đầu tiên (Onboarding)
    );
  }

  // Hàm riêng để đi đến ClassList
  static void _goToClassList(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;

    if (currentRoute != '/class-list') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ClassListScreen(),
          settings: const RouteSettings(name: '/class-list'),
        ),
      );
    }
  }
}