import 'package:flutter/material.dart';
import '../../../auth_service.dart';
import '../../../main.dart'; // Để gọi lại AuthWrapper khi đăng xuất

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ Học sinh (Tạm)'),
        backgroundColor: const Color(0xFF007BFF),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_rounded, size: 80, color: Color(0xFF007BFF)),
            const SizedBox(height: 16),
            const Text(
              'Đăng nhập thành công!\nĐây là màn hình tạm thời để test luồng.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 32),
            
            // --- NÚT ĐĂNG XUẤT ĐÃ GẮN BACKEND ---
            ElevatedButton.icon(
              onPressed: () async {
                // 1. Gọi hàm xóa phiên làm việc trên Firebase
                await AuthService().logout();
                
                // 2. Xóa lịch sử trang và đẩy về cổng AuthWrapper
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthWrapper()),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Đăng xuất ngay', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            )
          ],
        ),
      ),
    );
  }
}