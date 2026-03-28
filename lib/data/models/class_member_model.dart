class ClassMemberModel {
  final String id;
  final String classId;
  final String studentId;
  final String status;
  final String? studentName;
  final String? studentEmail;
  
  const ClassMemberModel({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.status,
    this.studentName,
    this.studentEmail,
  });
   
  bool get isActive => status == 'active';

  factory ClassMemberModel.fromJson(Map<String, dynamic> json, {required String id}) {
    return ClassMemberModel(
      id: id,
      classId: json['class_id'] ?? '',
      studentId: json['student_id'] ?? '',
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson({bool isNew = true}) {
    return {
      'class_id': classId,
      'student_id': studentId,
      'status': status,
      if (isNew)
      'joined_at': DateTime.now().toIso8601String(),
    };
  }

   ClassMemberModel copyWith({String? status, String? studentName, String? studentEmail}) {
    return ClassMemberModel(
      id:           id,
      classId:      classId,
      studentId:    studentId,
      status:       status       ?? this.status,
      studentName:  studentName  ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
    );
  }

}