// core/navigation/app_navigator.dart
import 'package:flutter/material.dart';
import '../../screens/teacher/dashboard_screen.dart';
import '../../screens/teacher/class_list_screen.dart';
import '../../screens/teacher/create_exam_screen.dart';
import '../../screens/teacher/exam_bank_screen.dart';
import '../../screens/common/user_profile_screen.dart';


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
      _goToCreateExam(context);
        break;

      case 3: // Kho đề
      _goToExamBank(context);
        break;

      case 4: // Cá nhân
       _goToProfile(context);
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

  static void _goToCreateExam(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;

    if (currentRoute != '/create-exam') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const CreateExamScreen(),
          settings: const RouteSettings(name: '/create-exam'),
        ),
      );
    }
  }

  static void _goToExamBank(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;

    if (currentRoute != '/exam-bank') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ExamBankScreen(),
          settings: const RouteSettings(name: '/exam-bank'),
        ),
      );
    }
}

  static void _goToProfile(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;

    if (currentRoute != '/profile') {
      Navigator.push(context,
        MaterialPageRoute(
          builder: (_) => const UserProfileScreen(),
          settings: const RouteSettings(name: '/profile'),
        ),
      );
    }
  }
}