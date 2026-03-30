// core/navigation/app_navigator.dart
import 'package:flutter/material.dart';
import '../../screens/student/student_home_screen.dart';
import '../../screens/student/student_class_list_screen.dart';

class AppNavigator {
  static void handleBottomNavTapSt(BuildContext context, int index) {
    switch (index) {
      case 0: // Trang chủ
        _goToHome(context);
        break;

      case 1: // Lớp học
        _goToClassList(context);
        break;

      case 2: // Kết quả
       
        break;

      case 3: // Cá nhân
       
        break;
    }
  }

  static void _goToHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
      (route) => route.isFirst,
    );
  }

  static void _goToClassList(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;

    if (currentRoute != '/student/class-list') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const StudentClassListScreen(),
          settings: const RouteSettings(name: '/student/class-list'),
        ),
      );
    }
  }

 
}