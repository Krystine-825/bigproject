import 'question_model.dart';

class ExamAssignment {
  final String classId;
  final String className;
  final int durationMinutes;
  final DateTime openAt;
  final DateTime closeAt;
  final int maxAttempts;
  final String assignedAt;
  final bool showAnswerAfterSubmit; // ← MỚI

  const ExamAssignment({
    required this.classId,
    required this.className,
    required this.durationMinutes,
    required this.openAt,
    required this.closeAt,
    required this.maxAttempts,
    required this.assignedAt,
    this.showAnswerAfterSubmit = false, // ← MỚI
  });

  factory ExamAssignment.fromJson(Map<String, dynamic> json) {
    return ExamAssignment(
      classId: (json['classId'] ?? json['class_id'] ?? '') as String,
      className:
          (json['className'] ?? json['class_name'] ?? '') as String,
      durationMinutes:
          ((json['durationMinutes'] ?? json['duration_minutes']) as num?)
                  ?.toInt() ??
              45,
      openAt: DateTime.tryParse(
              (json['openAt'] ?? json['open_at'] ?? '') as String) ??
          DateTime.now(),
      closeAt: DateTime.tryParse(
              (json['closeAt'] ?? json['close_at'] ?? '') as String) ??
          DateTime.now(),
      maxAttempts:
          ((json['maxAttempts'] ?? json['max_attempts']) as num?)?.toInt() ??
              1,
      assignedAt:
          (json['assignedAt'] ?? json['assigned_at'] ?? '') as String,
      // ← MỚI: đọc cả hai key camelCase lẫn snake_case
      showAnswerAfterSubmit:
          (json['showAnswerAfterSubmit'] ??
                  json['show_answer_after_submit'] ??
                  false) as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'classId': classId,
        'className': className,
        'durationMinutes': durationMinutes,
        'openAt': openAt.toIso8601String(),
        'closeAt': closeAt.toIso8601String(),
        'maxAttempts': maxAttempts,
        'assignedAt': assignedAt,
        'showAnswerAfterSubmit': showAnswerAfterSubmit, // ← MỚI
      };
}

class ExamModel {
  final String id;
  final String name;
  final String classId;
  final String teacherId;
  final String source;
  final List<QuestionModel> questions;
  final int? durationMinutes;
  final String status; // 'draft' | 'assigned'
  final String createdAt;
  final List<ExamAssignment> assignments;

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
      id: id,
      name: name ?? this.name,
      classId: classId,
      teacherId: teacherId,
      source: source,
      questions: questions ?? this.questions,
      status: status ?? this.status,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      createdAt: createdAt,
      assignments: assignments ?? this.assignments,
    );
  }

  factory ExamModel.fromJson(Map<String, dynamic> json,
      {required String id}) {
    return ExamModel(
      id: id,
      name: (json['title'] ?? json['name'] ?? '') as String,
      classId: (json['class_id'] ?? json['classId'] ?? '') as String,
      teacherId:
          (json['teacher_id'] ?? json['teacherId'] ?? '') as String,
      source:
          (json['source_pdf_name'] ?? json['source'] ?? '') as String,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map((q) =>
              QuestionModel.fromJson(q as Map<String, dynamic>))
          .toList(),
      status: (json['status'] ?? 'draft') as String,
      createdAt: (json['created_at'] ??
          json['createdAt'] ??
          DateTime.now().toIso8601String()) as String,
      assignments: (json['assignments'] as List<dynamic>? ?? [])
          .map((a) =>
              ExamAssignment.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'class_id': classId,
      'teacher_id': teacherId,
      'source': source,
      'duration_minutes': durationMinutes,
      'questions': questions.map((q) => q.toJson()).toList(),
      'status': status,
      'created_at': createdAt,
      'assignments': assignments.map((a) => a.toJson()).toList(),
    };
  }
}