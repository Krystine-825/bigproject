// core/navigation/app_navigator.dart
import 'package:flutter/material.dart';
import '../../screens/student/student_home_screen.dart';
import '../../screens/student/student_class_list_screen.dart';
import '../../screens/common/user_profile_screen.dart';
import '../../screens/student/results_screen.dart';

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
       _goToResults(context);
        break;

      case 3: // Cá nhân
       _goToProfile(context);
        break;
    }
  }

  static void _goToHome(BuildContext context) {
    // Luôn dọn dẹp Stack và đưa về trang chủ làm gốc
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const StudentHomeScreen(),
        settings: const RouteSettings(name: '/student/home'),
      ),
      (route) => route.isFirst,
    );
  }

  static void _goToClassList(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;

    if (currentRoute != '/student/class-list') {
      // Dùng pushReplacement để thay thế màn hình hiện tại bằng màn hình Lớp học
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const StudentClassListScreen(),
          settings: const RouteSettings(name: '/student/class-list'),
        ),
      );
    }
  }

  static void _goToProfile(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute != '/student/profile') {
      // Dùng pushReplacement để thay thế màn hình hiện tại bằng màn hình Cá nhân
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const UserProfileScreen(),
          settings: const RouteSettings(name: '/student/profile'),
        ),
      );
    }
  }

  static void _goToResults(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute != '/student/results') {
      // Dùng pushReplacement để thay thế màn hình hiện tại bằng màn hình Kết quả
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const StudentResultsScreen(),
          settings: const RouteSettings(name: '/student/results'),
        ),
      );
    }
  }
}
// làm thế này thì học viên đỡ lag máy 
// vì cách cũ thì bật đi bật lại các màn nó sẽ giữ các màn cũ chồng lớp lên nhau còn cách này thì không 
// xem thử cách này được không thì thử lại cách cũ nhé