import '../data/models/submission_model.dart';
import '../data/models/question_model.dart';
import '../data/services/auth_service.dart';
import '../data/services/firestore_service.dart';

class SubmissionController {
  final auth = AuthService();
  final firestore = FireStoreService();

  String get _myUid => auth.currentUid ?? '';

  /// Nộp bài
  Future<SubmissionModel> submitExam({
    required String examId,
    required String classId,
    required List<QuestionModel> questions,
    required Map<int, String> studentAnswers, // questionId → answer
    required int durationSeconds,
  }) async {
    if (_myUid.isEmpty) throw Exception('Chưa đăng nhập');

    // Tính điểm
    int correct = 0;
    final answers = <SubmissionAnswer>[];

    for (final q in questions) {
      final chosen = studentAnswers[q.id] ?? '';
      answers.add(SubmissionAnswer(questionId: q.id, answer: chosen));
      if (_isCorrect(q, chosen)) correct++;
    }

    final total = questions.length;
    final score = total > 0 ? (correct / total) * 10 : 0.0;

    final submission = SubmissionModel(
      id: '',
      examId: examId,
      classId: classId,
      studentId: _myUid,
      answers: answers,
      score: double.parse(score.toStringAsFixed(1)),
      correctCount: correct,
      totalCount: total,
      status: 'submitted',
      submittedAt: DateTime.now().toIso8601String(),
      durationSeconds: durationSeconds,
    );

    final docRef =
        await firestore.addDocument('submissions', submission.toJson());
    return SubmissionModel.fromJson(submission.toJson(), id: docRef.id);
  }

  /// Kiểm tra xem học sinh đã nộp bài chưa (cho 1 đề + 1 lớp)
  Future<SubmissionModel?> getMySubmission(
      {required String examId, required String classId}) async {
    if (_myUid.isEmpty) return null;
    try {
      // query theo exam_id + student_id, sau đó filter classId
      final snap = await firestore.queryWhere(
        'submissions',
        field: 'exam_id',
        isEqualTo: examId,
      );
      final doc = snap.docs.firstWhere(
        (d) =>
            d.data()['student_id'] == _myUid &&
            d.data()['class_id'] == classId,
        orElse: () => throw StateError('not found'),
      );
      return SubmissionModel.fromJson(doc.data(), id: doc.id);
    } catch (_) {
      return null;
    }
  }

  /// Stream map: examId → SubmissionModel? cho học sinh hiện tại trong 1 lớp
  Stream<Map<String, SubmissionModel>> streamMySubmissionsForClass(
      String classId) {
    if (_myUid.isEmpty) return Stream.value({});
    return firestore
        .streamWhere('submissions',
            field: 'student_id', isEqualTo: _myUid)
        .map((snap) {
      final map = <String, SubmissionModel>{};
      for (final d in snap.docs) {
        final data = d.data();
        if (data['class_id'] == classId) {
          final sub = SubmissionModel.fromJson(data, id: d.id);
          map[sub.examId] = sub;
        }
      }
      return map;
    });
  }

  /// Stats cho home screen: tổng chưa làm / mới hôm nay / hoàn thành
  Future<Map<String, int>> getStudentStats() async {
    if (_myUid.isEmpty) return {'pending': 0, 'newToday': 0, 'done': 0};
    try {
      // Lấy submissions của student
      final subSnap = await firestore.queryWhere(
        'submissions',
        field: 'student_id',
        isEqualTo: _myUid,
      );
      final done = subSnap.docs.length;

      return {'pending': 0, 'newToday': 0, 'done': done};
    } catch (_) {
      return {'pending': 0, 'newToday': 0, 'done': 0};
    }
  }


  bool _isCorrect(QuestionModel q, String chosen) {
    if (chosen.isEmpty) return false;
    final correctAnswer = q.answer.trim().toLowerCase();
    final studentAnswer = chosen.trim().toLowerCase();

    switch (q.type) {
      case 'multiple_choice':
        // answer lưu dạng "A", "B", "C", "D"
        return studentAnswer == correctAnswer;
      case 'true_false':
        return studentAnswer == correctAnswer;
      case 'fill_in':
        return studentAnswer == correctAnswer;
      default:
        return studentAnswer == correctAnswer;
    }
  }
}