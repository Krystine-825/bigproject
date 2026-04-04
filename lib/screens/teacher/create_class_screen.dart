import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../controllers/class_controller.dart';
import '../../data/models/class_model.dart';
 
class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({super.key});
 
  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}
 
class _CreateClassScreenState extends State<CreateClassScreen> {
  final _classNameController = TextEditingController();
  final _passwordController  = TextEditingController();
  final _controller          = ClassController();
 
  bool _isLoading = false;
 
  @override
  void dispose() {
    _classNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
 
 
  Future<void> _handleCreate() async {
    final name = _classNameController.text.trim();
 
    // Validate tên lớp
    if (name.isEmpty) {
      _showSnack('Vui lòng nhập tên lớp', isError: true);
      return;
    }
 
    setState(() => _isLoading = true);
 
    try {
      final ClassModel created = await _controller.createClass(
        name: name,
        passwordHash: _passwordController.text.trim().isEmpty
            ? null
            : _passwordController.text.trim(), // TODO: hash trước khi lưu
      );
 
      if (!mounted) return;
 
      // Thành công → hiện dialog mã lớp rồi quay lại
      await _showSuccessDialog(created);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Tạo lớp thất bại: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
 

  Future<void> _showSuccessDialog(ClassModel cls) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Tạo lớp thành công!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Mã lớp của bạn:',
                style: TextStyle(color: AppColors.textMedium)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                cls.code,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Chia sẻ mã này cho học sinh để tham gia lớp.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textMedium),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);  // đóng dialog
                Navigator.pop(context, cls); // trả ClassModel về ClassListScreen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Xong'),
            ),
          ),
        ],
      ),
    );
  }
 
  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
 
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
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
                    _buildInfoNote(),
                  ],
                ),
              ),
            ),
            _buildCreateButton(),
          ],
        ),
      ),
    );
  }
 
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
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
          const SizedBox(width: 48),
        ],
      ),
    );
  }
 
  Widget _buildInfoNote() {
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
          Icon(Icons.info_outline_rounded, color: AppColors.white, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sau khi hoàn tất, hệ thống sẽ tự động tạo một mã lớp gồm 6 ký tự để học sinh tham gia.',
              style: TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _buildCreateButton() {
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
          onPressed: _isLoading ? null : _handleCreate,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28)),
            elevation: 4,
            shadowColor: AppColors.primary.withOpacity(0.3),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  'Tạo lớp',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}
 