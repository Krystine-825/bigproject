class UserModel{
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? phone;

 const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
  });

  bool get isTeacher => role == 'teacher';
  bool get isStudent => role == 'student';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'student',
      phone: json['phone'] as String?,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'created_at': DateTime.now().toIso8601String(),
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
    };
  }
}