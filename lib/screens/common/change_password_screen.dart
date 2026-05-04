import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../controllers/profile_controller.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final profile = ProfileController();

  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;
  bool _saving = false;

  /// 0 = empty, 1 = weak, 2 = medium, 3 = strong
  int _strengthLevel = 0;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _checkStrength(String val) {
    int level;
    if (val.isEmpty) {
      level = 0;
    } else if (val.length < 8) {
      level = 1;
    } else if (val.length < 10) {
      level = 2;
    } else {
      level = 3;
    }
    if (level != _strengthLevel) setState(() => _strengthLevel = level);
  }

  String get _strengthLabel =>
      ['', 'Yếu', 'Trung bình', 'Mạnh'][_strengthLevel];

  Color get _strengthColor => [
        Colors.transparent,
        const Color(0xFFEF4444),
        const Color(0xFFF59E0B),
        const Color(0xFF22C55E),
      ][_strengthLevel];

  double get _strengthValue => [0.0, 0.33, 0.66, 1.0][_strengthLevel];

  Future<void> _submit() async {
    final current = _currentCtrl.text.trim();
    final newPass = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      _showError('Vui lòng điền đầy đủ các trường.');
      return;
    }

    setState(() => _saving = true);
    final err = await profile.changePassword(
      currentPassword: current,
      newPassword: newPass,
      confirmPassword: confirm,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (err != null) {
      _showError(err);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đổi mật khẩu thành công!'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
      Navigator.pop(context);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Đổi mật khẩu',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child:
              Container(height: 1, color: const Color(0xFFF1F5F9)),
        ),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.fromLTRB(24, 32, 24, 120),
        child: Column(
          children: [
            
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield_rounded,
                  size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'Bảo mật tài khoản',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mật khẩu mới phải có ít nhất 8 ký tự\nđể đảm bảo an toàn cho bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.6),
            ),
            const SizedBox(height: 40),

            
            _passwordField(
              label: 'Mật khẩu hiện tại',
              hint: 'Nhập mật khẩu hiện tại',
              ctrl: _currentCtrl,
              hide: _hideCurrent,
              onToggle: () =>
                  setState(() => _hideCurrent = !_hideCurrent),
            ),
            const SizedBox(height: 20),

          
            _passwordField(
              label: 'Mật khẩu mới',
              hint: 'Nhập mật khẩu mới',
              ctrl: _newCtrl,
              hide: _hideNew,
              onToggle: () =>
                  setState(() => _hideNew = !_hideNew),
              onChanged: _checkStrength,
            ),
            if (_strengthLevel > 0) ...[
              const SizedBox(height: 10),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: _strengthValue,
                          backgroundColor:
                              const Color(0xFFF1F5F9),
                          valueColor:
                              AlwaysStoppedAnimation(_strengthColor),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _strengthLabel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _strengthColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

           
            _passwordField(
              label: 'Xác nhận mật khẩu mới',
              hint: 'Nhập lại mật khẩu mới',
              ctrl: _confirmCtrl,
              hide: _hideConfirm,
              onToggle: () =>
                  setState(() => _hideConfirm = !_hideConfirm),
            ),
          ],
        ),
      ),
     
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border:
              Border(top: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Cập nhật mật khẩu',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  
  Widget _passwordField({
    required String label,
    required String hint,
    required TextEditingController ctrl,
    required bool hide,
    required VoidCallback onToggle,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          obscureText: hide,
          onChanged: onChanged,
          style: const TextStyle(
              fontSize: 15, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: Color(0xFFCBD5E1)),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: IconButton(
              icon: Icon(
                hide
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: const Color(0xFF94A3B8),
              ),
              onPressed: onToggle,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                  color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 18),
          ),
        ),
      ],
    );
  }
}