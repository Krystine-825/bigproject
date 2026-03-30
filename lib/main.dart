import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'core/app_colors.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/teacher/dashboard_screen.dart';
import 'screens/student/student_home_screen.dart';
import 'controllers/auth_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduExam',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF007BFF)),
        fontFamily: 'Lexend', 
        useMaterial3: true,
      ),
      home: const OnboardingScreen(),
    );
  }
}


class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // chờ trạng thái đăng nhập từ Firebase
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        // Nếu người dùng ĐÃ đăng nhập từ trước
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<String?>(
            future: AuthController().getRole(),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                );
              }

              final role = roleSnapshot.data;
              // Tự động phân luồng dựa trên Role
              if (role == 'teacher') {
                return const DashboardScreen();
              } else if (role == 'student') {
                return const StudentHomeScreen();
              } else {
                return const LoginScreen();
              }
            },
          );
        }

        // Nếu chưa đăng nhập thì Hiện màn hình Giới thiệu
        return const OnboardingScreen();
      },
    );
  }
}