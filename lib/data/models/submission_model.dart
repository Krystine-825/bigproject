class SubmissionAnswer {
  final int questionId;
  final String answer;

  const SubmissionAnswer({required this.questionId, required this.answer});

  factory SubmissionAnswer.fromJson(Map<String, dynamic> json) {
    return SubmissionAnswer(
      questionId: (json['question_id'] as num).toInt(),
      answer: json['answer'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'question_id': questionId,
        'answer': answer,
      };
}

class SubmissionModel {
  final String id;
  final String examId;
  final String classId;
  final String studentId;
  final List<SubmissionAnswer> answers;
  final double score; // 0–10
  final int correctCount;
  final int totalCount;
  final String status; // 'submitted'
  final String submittedAt;
  final int durationSeconds;
  final int attemptNumber; 

  const SubmissionModel({
    required this.id,
    required this.examId,
    required this.classId,
    required this.studentId,
    required this.answers,
    required this.score,
    required this.correctCount,
    required this.totalCount,
    required this.status,
    required this.submittedAt,
    required this.durationSeconds,
    required this.attemptNumber, // ← MỚI
  });

  factory SubmissionModel.fromJson(Map<String, dynamic> json,
      {required String id}) {
    return SubmissionModel(
      id: id,
      examId: json['exam_id'] as String? ?? '',
      classId: json['class_id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      answers: (json['answers'] as List<dynamic>? ?? [])
          .map((a) => SubmissionAnswer.fromJson(a as Map<String, dynamic>))
          .toList(),
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      correctCount: (json['correct_count'] as num?)?.toInt() ?? 0,
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'submitted',
      submittedAt: json['submitted_at'] as String? ?? '',
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      attemptNumber: (json['attempt_number'] as num?)?.toInt() ?? 1, // ← MỚI
    );
  }

  Map<String, dynamic> toJson() => {
        'exam_id': examId,
        'class_id': classId,
        'student_id': studentId,
        'answers': answers.map((a) => a.toJson()).toList(),
        'score': score,
        'correct_count': correctCount,
        'total_count': totalCount,
        'status': status,
        'submitted_at': submittedAt,
        'duration_seconds': durationSeconds,
        'attempt_number': attemptNumber, // ← MỚI
      };
}