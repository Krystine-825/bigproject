import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../controllers/class_controller.dart';

class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({super.key});

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  final _classNameController = TextEditingController();
  final _passwordController = TextEditingController();

  final _classCtrl = ClassController(); 
  bool _isLoading = false;

  @override
  void dispose() {
    _classNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      label: 'Tên lớp',
                      hint: 'Ví dụ: 12A1 — Tiếng Anh',
                      ctrl: _classNameController,
                      prefixIcon: Icons.class_rounded,
                    ),
                    const SizedBox(height: 24),

                    CustomTextField(
                      label: 'Mật khẩu lớp',
                      hint: 'Nhập mật khẩu (tùy chọn)',
                      ctrl: _passwordController,
                      prefixIcon: Icons.lock_outline_rounded,
                      isPass: true,
                    ),
                    const SizedBox(height: 32),

                    _InfoNote(),
                  ],
                ),
              ),
            ),
            _CreateButton(),
          ],
        ),
      ),
    );
  }

  Widget _Header() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.textDark,
          ),
          const Expanded(
            child: Text(
              'Tạo lớp mới',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(width: 48), // để căn giữa tiêu đề
        ],
      ),
    );
  }

  Widget _InfoNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withOpacity(0.3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.white,
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sau khi hoàn tất, hệ thống sẽ tự động tạo một mã lớp gồm 6 ký tự để học sinh tham gia.',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _CreateButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : () async {
            final className = _classNameController.text.trim();
            if (className.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Vui lòng nhập tên lớp'),
                  backgroundColor: AppColors.error,
                ),
              );
              return;
            }

            // BẮT ĐẦU GỌI FIREBASE
            setState(() => _isLoading = true);
            
            final error = await _classCtrl.createClass(
              name: className,
              password: _passwordController.text.trim(),
            );
            
            setState(() => _isLoading = false);

            if (!context.mounted) return;

            // KIỂM TRA KẾT QUẢ
            if (error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error), backgroundColor: AppColors.error),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tạo lớp thành công!'), 
                  backgroundColor: AppColors.success, // Màu xanh lá
                ),
              );
              Navigator.pop(context); // Tạo xong thì tự động quay về màn hình trước
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 4,
            shadowColor: AppColors.primary.withOpacity(0.3),
          ),
          // HIỆN VÒNG XOAY NẾU ĐANG LOADING
          child: _isLoading 
            ? const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : const Text(
                'Tạo lớp',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
        ),
      ),
    );
  }
}