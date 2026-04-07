import 'question_model.dart';

class ExamModel {
  final String id;
  final String name;
  final String classId;
  final String teacherId;
  final String source;
  final List<QuestionModel> questions;
  final String status;
  final String createdAt;

  const ExamModel({
    required this.id,
    required this.name,
    required this.classId,
    required this.teacherId,
    required this.source,
    required this.questions,
    this.status = 'draft',
    required this.createdAt,
  });

  // Tạo bản copy để chỉnh sửa danh sách câu hỏi
  ExamModel copyWith({
    String? name,
    List<QuestionModel>? questions,
    String? status,
  }) {
    return ExamModel(
      id:        id,
      name:      name      ?? this.name,
      classId:   classId,
      teacherId: teacherId,
      source:    source,
      questions: questions ?? this.questions,
      status:    status    ?? this.status,
      createdAt: createdAt,
    );
  }

  // Cloud Function trả về snake_case: exam_id, class_id, teacher_id...
  factory ExamModel.fromJson(Map<String, dynamic> json, {required String id}) {
    return ExamModel(
      id:        id,
      name:      (json['title'] ?? json['name'] ?? '') as String,
      classId:   (json['class_id'] ?? json['classId'] ?? '') as String,
      teacherId: (json['teacher_id'] ?? json['teacherId'] ?? '') as String,
      source:    (json['source_pdf_name'] ?? json['source'] ?? '') as String,
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
          .toList(),
      status:    (json['status'] ?? 'draft') as String,
      createdAt: (json['created_at'] ?? json['createdAt'] ??
          DateTime.now().toIso8601String()) as String,
    );
  }

  // Firestore lưu snake_case
  Map<String, dynamic> toJson() {
    return {
      'name':       name,
      'class_id':   classId,
      'teacher_id': teacherId,
      'source':     source,
      'questions':  questions.map((q) => q.toJson()).toList(),
      'status':     status,
      'created_at': createdAt,
    };
  }
}