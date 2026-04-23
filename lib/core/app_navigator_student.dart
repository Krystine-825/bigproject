
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
    final currentRoute = ModalRoute.of(context)?.settings.name;
    
    // Thêm check currentRoute để tránh bấm 2 lần vào tab hiện tại
    if (currentRoute != '/student/home') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const StudentHomeScreen(),
          settings: const RouteSettings(name: '/student/home'), // Đặt tên route để dễ quản lý
        ),
        (route) => route.isFirst,
      );
    }
  }

  static void _goToClassList(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;

    if (currentRoute != '/student/class-list') {
      Navigator.pushReplacement( // đổi thành pushReplacement
        context,
        MaterialPageRoute(
          builder: (_) => const StudentClassListScreen(),
          settings: const RouteSettings(name: '/student/class-list'),
        ),
      );
    }
  }

<<<<<<< HEAD
 
=======
  static void _goToProfile(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    
    if (currentRoute != '/profile') {
      Navigator.pushReplacement( // đổi thành pushReplacement
        context,
        MaterialPageRoute(
          builder: (_) => const UserProfileScreen(),
          settings: const RouteSettings(name: '/profile'),
        ),
      );
    }
  }

  static void _goToResults(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    
    if (currentRoute != '/student/results') {
      Navigator.pushReplacement( // đổi thành pushReplacement
        context,
        MaterialPageRoute(
          builder: (_) => const StudentResultsScreen(),
          settings: const RouteSettings(name: '/student/results'),
        ),
      );
    }
  }
>>>>>>> 9062247 (Fix some bug  UI, controller, toi uu sinh de)
}