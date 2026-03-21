class Validators {
  static String? email(String value) {
    if (value.isEmpty) return 'Vui lòng nhập email';
    if (!value.contains('@')) return 'Email không hợp lệ';
    return null;
  }

  static String? password(String value) {
    if (value.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (value.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự';
    return null;
  }

  static String? name(String value) {
    if (value.isEmpty) return 'Vui lòng nhập họ và tên';
    return null;
  }

  static String? confirmPassword(String pass, String confirm) {
    if (confirm.isEmpty) return 'Vui lòng xác nhận mật khẩu';
    if (pass != confirm) return 'Mật khẩu xác nhận không khớp';
    return null;
  }
}
