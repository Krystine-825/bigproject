import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../controllers/class_controller.dart';
import '../../data/models/class_model.dart';

class JoinClassScreen extends StatefulWidget {
  const JoinClassScreen({super.key});

  @override
  State<JoinClassScreen> createState() => _JoinClassScreenState();
}

class _JoinClassScreenState extends State<JoinClassScreen> {
  final classCodeController = TextEditingController();
  final passwordController = TextEditingController();
  bool hidePassword = true;

  final classController = ClassController();
  bool isLoading = false;

  @override
  void dispose() {
    classCodeController.dispose();
    passwordController.dispose();
    super.dispose();
  }
  
  Future<void> joinClass() async {
    final code = classCodeController.text.trim();
    if(code.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar( const SnackBar(
        content: Text('Vui lòng nhập mã lớp'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    setState(() => isLoading = true);
    try {
      final cls = await classController.joinClass(
        code: code,
        passwordHash: passwordController.text.trim().isEmpty? null :  passwordController.text.trim(),
      );
      if(!mounted) return;
      await _showSuccessDialog(cls);
    } catch (e) {
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(
        content: Text(e.toString()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } finally {
      setState(() => isLoading = false);
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
            Expanded(
              child: Text(
                'Tham gia thành công!',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.school_rounded,
                size: 56, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              cls.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Bạn đã được thêm vào lớp học.',
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
                Navigator.pop(context); // đóng dialog
                Navigator.pop(context, cls); // trả ClassModel về màn trước
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                child: Column(
                  children: [
                    illustration(),
                    const SizedBox(height: 32),
                    titleSection(),
                    const SizedBox(height: 40),
                    form(),
                  ],
                ),
              ),
            ),
            joinButton(),
          ],
        ),
      ),
    );
  }


  Widget header() {
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
              'Tham gia lớp học',
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


  Widget illustration() {
    return Column(
      children: [
        Container(
          width: 220,
          height: 220,
          decoration: const BoxDecoration(
            color: Color(0xFFE0F2FE),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.groups_rounded,
            size: 100,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Nhập mã lớp học',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Nhận mã lớp từ giáo viên qua Zalo hoặc tin nhắn',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.textMedium),
        ),
      ],
    );
  }


  Widget titleSection() {
    return const SizedBox.shrink(); // Đã có trong Illustration
  }

  Widget form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mã lớp
        const Text(
          'MÃ LỚP',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textLabel,
          ),
        ),
        const SizedBox(height: 8),
        CustomTextField(
          label: '',
          hint: 'ABC123',
          ctrl: classCodeController,
          prefixIcon: Icons.key_rounded,
          borderRadius: 16,
        ),

        const SizedBox(height: 24),

        // Mật khẩu lớp
        const Text(
          'MẬT KHẨU LỚP',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textLabel,
          ),
        ),
        const SizedBox(height: 8),
        CustomTextField(
          label: '',
          hint: 'Nhập mật khẩu lớp (nếu có)',
          ctrl: passwordController,
          prefixIcon: Icons.lock_outline_rounded,
          isPass: true,
          hide: hidePassword,
          onToggle: () => setState(() => hidePassword = !hidePassword),
          borderRadius: 16,
        ),
      ],
    );
  }


  Widget joinButton() {
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
          onPressed: isLoading?null: joinClass, 
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 4,
            shadowColor: AppColors.primary.withOpacity(0.3),
          ),
          child: isLoading ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
           :
          const Text(
            'Tham gia lớp',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
