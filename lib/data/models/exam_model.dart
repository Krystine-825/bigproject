import 'question_model.dart';

class ExamAssignment {
  final String classId;
  final String className;
  final int durationMinutes;
  final DateTime openAt;
  final DateTime closeAt;
  final int maxAttempts;
  final String assignedAt;

  const ExamAssignment({
    required this.classId,
    required this.className,
    required this.durationMinutes,
    required this.openAt,
    required this.closeAt,
    required this.maxAttempts,
    required this.assignedAt,
  });

  factory ExamAssignment.fromJson(Map<String, dynamic> json) {
    return ExamAssignment(
      classId:         json['class_id'] ?? '',
      className:       json['class_name'] ?? '',
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 45,
      openAt:          DateTime.tryParse(json['open_at'] ?? '') ?? DateTime.now(),
      closeAt:         DateTime.tryParse(json['close_at'] ?? '') ?? DateTime.now(),
      maxAttempts:     (json['max_attempts'] as num?)?.toInt() ?? 1,
      assignedAt:      json['assigned_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'class_id':         classId,
    'class_name':       className,
    'duration_minutes': durationMinutes,
    'open_at':          openAt.toIso8601String(),
    'close_at':         closeAt.toIso8601String(),
    'max_attempts':     maxAttempts,
    'assigned_at':      assignedAt,
  };
}

class ExamModel {
  final String id;
  final String name;
  final String classId;   // giữ lại để tương thích, là classId lần giao đầu
  final String teacherId;
  final String source;
  final List<QuestionModel> questions;
  final int? durationMinutes;
  final String status;    // 'draft' | 'assigned'
  final String createdAt;
  final List<ExamAssignment> assignments; // danh sách các lần giao

  const ExamModel({
    required this.id,
    required this.name,
    required this.classId,
    required this.teacherId,
    required this.source,
    required this.questions,
    this.durationMinutes,
    this.status = 'draft',
    required this.createdAt,
    this.assignments = const [],
  });

  bool get isAssigned => status == 'assigned' || assignments.isNotEmpty;

  ExamModel copyWith({
    String? name,
    List<QuestionModel>? questions,
    String? status,
    int? durationMinutes,
    List<ExamAssignment>? assignments,
  }) {
    return ExamModel(
      id:              id,
      name:            name      ?? this.name,
      classId:         classId,
      teacherId:       teacherId,
      source:          source,
      questions:       questions ?? this.questions,
      status:          status    ?? this.status,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      createdAt:       createdAt,
      assignments:     assignments ?? this.assignments,
    );
  }

  factory ExamModel.fromJson(Map<String, dynamic> json, {required String id}) {
    return ExamModel(
      id:        id,
      name:      (json['title'] ?? json['name'] ?? '') as String,
      classId:   (json['class_id'] ?? json['classId'] ?? '') as String,
      teacherId: (json['teacher_id'] ?? json['teacherId'] ?? '') as String,
      source:    (json['source_pdf_name'] ?? json['source'] ?? '') as String,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
          .toList(),
      status:    (json['status'] ?? 'draft') as String,
      createdAt: (json['created_at'] ?? json['createdAt'] ??
          DateTime.now().toIso8601String()) as String,
      assignments: (json['assignments'] as List<dynamic>? ?? [])
          .map((a) => ExamAssignment.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name':             name,
      'class_id':         classId,
      'teacher_id':       teacherId,
      'source':           source,
      'duration_minutes': durationMinutes,
      'questions':        questions.map((q) => q.toJson()).toList(),
      'status':           status,
      'created_at':       createdAt,
      'assignments':      assignments.map((a) => a.toJson()).toList(),
    };
  }
}