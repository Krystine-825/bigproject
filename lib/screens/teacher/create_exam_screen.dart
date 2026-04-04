import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button_nav.dart';

class CreateExamScreen extends StatefulWidget {
  const CreateExamScreen({super.key});

  @override
  State<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  final _examNameController = TextEditingController();
  final _questionCountController = TextEditingController(text: '10');

  // Data tạm - sau này sẽ thay bằng Controller
  String selectedDifficulty = 'Trung bình'; // Dễ - Trung bình - Khó
  bool hasUploadedFile = false;
  String? uploadedFileName;

  @override
  void dispose() {
    _examNameController.dispose();
    _questionCountController.dispose();
    super.dispose();
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
                    _buildSourceSection(),
                    const SizedBox(height: 32),
                    _buildConfigurationSection(),
                  ],
                ),
              ),
            ),
            _buildGenerateButton(),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(currentIndex: 2),
    );
  }

  Widget _buildHeader() {
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
              'Tạo đề bằng AI',
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

  Widget _buildSourceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn nguồn dữ liệu',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            // TODO: Mở bottom sheet chọn upload file / chụp ảnh / dán text
            _showUploadOptions();
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.upload_file_rounded,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Upload file',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasUploadedFile ? uploadedFileName ?? '' : 'PDF, DOCX, ảnh, text',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

 
  Widget _buildConfigurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cấu hình đề thi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 20),

        // Tên đề
        CustomTextField(
          label: 'Tên đề',
          hint: 'Nhập tên đề thi của bạn...',
          ctrl: _examNameController,
          prefixIcon: Icons.edit_note_rounded,
        ),

        const SizedBox(height: 24),

        // Cấp độ
        const Text(
          'Cấp độ',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textLabel),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _difficultyButton('Dễ', 'Dễ'),
            const SizedBox(width: 12),
            _difficultyButton('Trung bình', 'Trung bình'),
            const SizedBox(width: 12),
            _difficultyButton('Khó', 'Khó'),
          ],
        ),

        const SizedBox(height: 24),

        // Số câu
        CustomTextField(
          label: 'Số câu',
          hint: 'Ví dụ: 10',
          ctrl: _questionCountController,
          prefixIcon: Icons.numbers_rounded,
          type: TextInputType.number,
        ),
      ],
    );
  }

  Widget _difficultyButton(String label, String value) {
    final isSelected = selectedDifficulty == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedDifficulty = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textDark,
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildGenerateButton() {
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
          onPressed: () {
            // TODO: Gọi Controller để sinh đề bằng AI
            final name = _examNameController.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vui lòng nhập tên đề')),
              );
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đang sinh đề bằng AI...'),
                backgroundColor: AppColors.primary,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            elevation: 4,
            shadowColor: AppColors.primary.withOpacity(0.3),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bolt_rounded),
              SizedBox(width: 8),
              Text(
                'Sinh đề bằng AI',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUploadOptions() {
    // TODO: Mở bottom sheet chọn upload file / chụp ảnh / dán text
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng upload đang phát triển')),
    );
  }
}
