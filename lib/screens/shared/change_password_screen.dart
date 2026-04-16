import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  String _strength = '';
  Color _strengthColor = Colors.grey;
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _checkStrength(String val) {
    if (val.isEmpty) {
      setState(() { _strength = ''; });
    } else if (val.length < 6) {
      setState(() { _strength = 'Yếu'; _strengthColor = Colors.red; });
    } else if (val.length < 10) {
      setState(() { _strength = 'Trung bình'; _strengthColor = Colors.orange; });
    } else {
      setState(() { _strength = 'Mạnh'; _strengthColor = Colors.green; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Đổi mật khẩu',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.security, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bảo mật tài khoản',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vui lòng nhập mật khẩu hiện tại và mật khẩu mới để cập nhật bảo mật cho bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textLight, height: 1.5),
            ),
            const SizedBox(height: 32),
            _passwordField('Mật khẩu hiện tại', 'Nhập mật khẩu hiện tại', _currentCtrl, _hideCurrent, () {
              setState(() => _hideCurrent = !_hideCurrent);
            }),
            const SizedBox(height: 16),
            _passwordField('Mật khẩu mới', 'Nhập mật khẩu mới', _newCtrl, _hideNew, () {
              setState(() => _hideNew = !_hideNew);
            }, onChanged: _checkStrength),
            if (_strength.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: _strength == 'Yếu' ? 0.33 : _strength == 'Trung bình' ? 0.66 : 1.0,
                      backgroundColor: AppColors.border,
                      color: _strengthColor,
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(_strength,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _strengthColor)),
                ],
              ),
            ],
            const SizedBox(height: 16),
            _passwordField('Xác nhận mật khẩu mới', 'Nhập lại mật khẩu mới', _confirmCtrl, _hideConfirm, () {
              setState(() => _hideConfirm = !_hideConfirm);
            }),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Cập nhật mật khẩu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordField(String label, String hint, TextEditingController ctrl, bool hide, VoidCallback onToggle, {Function(String)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          obscureText: hide,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textHint),
            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textLight),
            suffixIcon: IconButton(
              icon: Icon(hide ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.textLight),
              onPressed: onToggle,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}