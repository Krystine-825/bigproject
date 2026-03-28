class ClassModel {
  final String id;
  final String name;
  final String code;
  final String teacherId;
  final String? passwordHash;

   const ClassModel({
    required this.id,
    required this.name,
    required this.code,
    required this.teacherId,
    this.passwordHash,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json, {required String id}) {
    return ClassModel(
      id: id,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      teacherId: json['teacher_id'] ?? '',
      passwordHash: json['password_hash'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'teacher_id': teacherId,
      if (passwordHash != null && passwordHash!.isNotEmpty) 'password_hash': passwordHash,
    };
  }
}