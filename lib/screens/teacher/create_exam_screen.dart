import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../core/app_colors.dart';
import '../../core/pdf_validator.dart';
import '../../controllers/exam_controller.dart';
import '../../widgets/common/custom_button_nav.dart';
import 'exam_preview_screen.dart';
import '../../controllers/auth_controller.dart';


class CreateExamScreen extends StatefulWidget {
  const CreateExamScreen({super.key});

  @override
  State<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  final examNameController = TextEditingController();
  final examController     = ExamController();

  
  File?   _pickedFile;
  String? _fileName;
  int?    _fileSizeBytes;
  String? _extractedText;
  bool    _isExtracting = false;
  bool    _fileIsValid  = false;

 
  int    _questionCount = 10; 
  String _difficulty    = 'medium'; 

  bool _isGenerating = false;

  @override
  void dispose() {
    examNameController.dispose();
    super.dispose();
  }

  
  // kiểm tra file hợp lệ
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    if (picked.path == null) return;

    setState(() {
      _isExtracting = true;
      _fileIsValid  = false;
      _extractedText = null;
      _pickedFile    = File(picked.path!);
      _fileName      = picked.name;
      _fileSizeBytes = picked.size;
    });

    await _validateAndExtract();
  }

  Future<void> _validateAndExtract() async {
    try {
      final bytes = await _pickedFile!.readAsBytes();

      final result = PdfValidator.validate(
        fileName:      _fileName!,
        fileSizeBytes: _fileSizeBytes!,
        bytes:         bytes,
      );

      if (!result.isValid) {
        setState(() {
          _isExtracting  = false;
          _fileIsValid   = false;
          _pickedFile    = null;
          _fileName      = null;
          _fileSizeBytes = null;
        });
        if (mounted) _showErrorDialog(result.errorMessage!);
        return;
      }

      final doc       = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(doc);
      final rawText   = extractor.extractText();
      doc.dispose();

      setState(() {
        _extractedText = rawText.trim();
        _fileIsValid   = true;
        _isExtracting  = false;
      });
    } catch (_) {
      setState(() {
        _isExtracting  = false;
        _fileIsValid   = false;
        _pickedFile    = null;
        _fileName      = null;
        _fileSizeBytes = null;
      });
      if (mounted) {
        _showErrorDialog('Không mở được file PDF.\nVui lòng thử lại với file khác.');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.error_outline_rounded, color: Colors.red, size: 26),
          SizedBox(width: 10),
          Text('File không hợp lệ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        content: Text(message,
            style: const TextStyle(fontSize: 14, height: 1.6,
                color: AppColors.textMedium)),
        actions: [
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: () { Navigator.pop(context); _pickFile(); },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Chọn file khác'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng',
                style: TextStyle(color: AppColors.textMedium)),
          ),
        ],
      ),
    );
  }

  //sinh đề
  Future<void> _handleGenerate() async {
  final name = examNameController.text.trim();

  if (name.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vui lòng nhập tên đề'),
        backgroundColor: AppColors.error,
      ),
    );
    return;
  }

  if (!_fileIsValid) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vui lòng upload file PDF hợp lệ'),
        backgroundColor: AppColors.error,
      ),
    );
    return;
  }

  setState(() => _isGenerating = true);

  try {
   
    final exam = await examController.generateExam(
      examName: name,
      pdfFile: _pickedFile!,         
      extractedText: _extractedText!,
      fileName: _fileName!,
      questionCount: _questionCount,
      difficulty: _difficulty,
    );

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamPreviewScreen(exam: exam),
      ),
    );

  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppColors.error,
      ),
    );
  } finally {
    if (mounted) setState(() => _isGenerating = false);
  }
}

  bool get _canGenerate =>
      _fileIsValid && !_isExtracting && !_isGenerating;

 
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
                    const SizedBox(height: 24),
                    _buildConfigSection(),
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
      child: Row(children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.textDark,
        ),
        const Expanded(
          child: Text('Tạo đề bằng AI',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
                  color: AppColors.textDark)),
        ),
        const SizedBox(width: 48),
      ]),
    );
  }


  Widget _buildSourceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tài liệu nguồn',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                color: AppColors.textDark)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: (_isExtracting || _isGenerating) ? null : _pickFile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _fileIsValid
                    ? Colors.green.withOpacity(0.5)
                    : AppColors.primary.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: _isExtracting
                ? const Column(children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Đang kiểm tra file...',
                        style: TextStyle(fontSize: 13,
                            color: AppColors.textMedium)),
                  ])
                : _fileIsValid
                    ? Row(children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.check_circle_rounded,
                              color: Colors.green, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_fileName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppColors.textDark)),
                            const SizedBox(height: 3),
                            Text(
                              '${(_fileSizeBytes! / 1024 / 1024).toStringAsFixed(1)}MB · Hợp lệ',
                              style: const TextStyle(fontSize: 12,
                                  color: Colors.green),
                            ),
                          ],
                        )),
                        if (!_isGenerating)
                          IconButton(
                            onPressed: _pickFile,
                            icon: const Icon(Icons.refresh_rounded),
                            color: AppColors.textHint,
                            tooltip: 'Chọn file khác',
                          ),
                      ])
                    : Column(children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.upload_file_rounded,
                              color: AppColors.primary, size: 32),
                        ),
                        const SizedBox(height: 12),
                        const Text('Nhấn để chọn file PDF',
                            style: TextStyle(fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark)),
                        const SizedBox(height: 4),
                        const Text(
                            'Tiếng Anh · Không công thức · Không scan ảnh · ≤ 10MB',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12,
                                color: AppColors.textMedium)),
                      ]),
          ),
        ),
      ],
    );
  }

 
  Widget _buildConfigSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cấu hình đề thi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                color: AppColors.textDark)),
        const SizedBox(height: 16),
        _configCard(children: [

          // Tên đề
          _fieldRow(
            label: 'Tên đề',
            child: TextField(
              controller: examNameController,
              style: const TextStyle(fontSize: 14, color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: 'Ví dụ: Unit 5 Vocabulary Test',
                hintStyle: const TextStyle(color: AppColors.textHint,
                    fontSize: 14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                filled: true,
                fillColor: const Color(0xFFF5F7F8),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                isDense: true,
              ),
            ),
          ),
          const Divider(height: 1),

          // Số câu — giới hạn 10–30
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('Số câu hỏi',
                      style: TextStyle(fontSize: 14,
                          color: AppColors.textDark)),
                  const Spacer(),
                  _counterBtn(Icons.remove_rounded,
                      _questionCount > 10
                          ? () => setState(() => _questionCount--)
                          : null),
                  SizedBox(width: 44,
                    child: Text('$_questionCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark)),
                  ),
                  _counterBtn(Icons.add_rounded,
                      _questionCount < 30
                          ? () => setState(() => _questionCount++)
                          : null),
                ]),
                const SizedBox(height: 6),
                // Slider 10–30
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    thumbColor: AppColors.primary,
                    inactiveTrackColor:
                        AppColors.primary.withOpacity(0.15),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8),
                    overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 16),
                  ),
                  child: Slider(
                    value: _questionCount.toDouble(),
                    min: 10,
                    max: 30,
                    divisions: 20,
                    onChanged: (v) =>
                        setState(() => _questionCount = v.round()),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('10', style: TextStyle(fontSize: 11,
                        color: AppColors.textHint)),
                    Text('30', style: TextStyle(fontSize: 11,
                        color: AppColors.textHint)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Cấp độ
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cấp độ',
                    style: TextStyle(fontSize: 14,
                        color: AppColors.textDark)),
                const SizedBox(height: 10),
                Row(children: [
                  _diffBtn('Dễ', 'easy', Colors.green),
                  const SizedBox(width: 10),
                  _diffBtn('Trung bình', 'medium', Colors.orange),
                  const SizedBox(width: 10),
                  _diffBtn('Khó', 'hard', Colors.red),
                ]),
              ],
            ),
          ),
        ]),
      ],
    );
  }

  Widget _configCard({required List<Widget> children}) => Container(
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
          blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(children: children),
  );

  Widget _fieldRow({required String label, required Widget child}) =>
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14,
              color: AppColors.textDark)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );

  Widget _counterBtn(IconData icon, VoidCallback? onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppColors.primaryLight
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18,
            color: onTap != null ? AppColors.primary : AppColors.textHint),
      ),
    );

  Widget _diffBtn(String label, String value, Color color) {
    final on = _difficulty == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _difficulty = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: on ? color.withOpacity(0.12) : const Color(0xFFF5F7F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: on ? color : Colors.transparent, width: 1.5),
          ),
          child: Center(child: Text(label,
              style: TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: on ? color : AppColors.textMedium))),
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
        width: double.infinity, height: 56,
        child: ElevatedButton(
          onPressed: _canGenerate ? _handleGenerate : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28)),
            elevation: 4,
            shadowColor: AppColors.primary.withOpacity(0.3),
          ),
          child: _isGenerating
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: AppColors.white, strokeWidth: 2.5)),
                    SizedBox(width: 12),
                    Text('Đang sinh đề...', style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                  ])
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt_rounded),
                    SizedBox(width: 8),
                    Text('Sinh đề bằng AI', style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
                  ]),
        ),
      ),
    );
  }
}