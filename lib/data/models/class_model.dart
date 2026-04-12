class ClassModel {
  final String id;
  final String name;
  final String code;
  final String teacherId;
  final String? passwordHash;
  final int studentCount;

  const ClassModel({
    required this.id,
    required this.name,
    required this.code,
    required this.teacherId,
    this.passwordHash,
    this.studentCount = 0,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json, {required String id}) {
    return ClassModel(
      id: id,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      teacherId: json['teacher_id'] ?? '',
      passwordHash: json['password_hash'],
      studentCount: (json['student_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'teacher_id': teacherId,
      'created_at': DateTime.now().toIso8601String(), // thêm để sort được
        'student_count': studentCount,
      if (passwordHash != null && passwordHash!.isNotEmpty)
        'password_hash': passwordHash,
    };
  }
}