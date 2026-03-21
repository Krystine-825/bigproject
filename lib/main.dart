import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'auth_service.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/teacher/dashboard_screen.dart';

void main() async {
  // Bắt buộc phải có 2 dòng này để Firebase hoạt động trước khi app chạy
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
      home: const AuthWrapper(), // Trỏ về AuthWrapper để tự động điều hướng
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().userStatus,
      builder: (context, snapshot) {
        // 1. Nếu chưa đăng nhập -> Hiện Onboarding của nhóm
        if (!snapshot.hasData) return const OnboardingScreen();

        // 2. Nếu đã đăng nhập -> Kiểm tra Role từ Firestore
        return FutureBuilder<DocumentSnapshot>(
          future: AuthService().getUserProfile(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.white,
                body: Center(child: CircularProgressIndicator(color: Color(0xFF007BFF))),
              );
            }

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              String role = userSnapshot.data!.get('role');
              // Điều hướng theo Role
              if (role == 'teacher') {
                return const DashboardScreen(); // Vào màn hình Giáo viên
              } else {
                return const Scaffold(body: Center(child: Text("Giao diện Học sinh đang phát triển"))); 
              }
            }
            // Mặc định trả về Onboarding nếu có lỗi không lấy được data
            return const OnboardingScreen();
          },
        );
      },
    );
  }
}