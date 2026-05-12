import '../data/models/submission_model.dart';
import '../data/models/question_model.dart';
import '../data/services/auth_service.dart';
import '../data/services/firestore_service.dart';
import 'notification_controller.dart'; 

class SubmissionController {
  final auth      = AuthService();
  final firestore = FireStoreService();
  final _notif    = NotificationController(); 

  String get _myUid => auth.currentUid ?? '';

  // Lấy số attempt tiếp theo cho bài thi này
  Future<int> _getNextAttemptNumber(String examId, String classId) async {
    final snap = await firestore.queryWhere(
      'submissions',
      field: 'exam_id',
      isEqualTo: examId,
      field2: 'student_id',
      isEqualTo2: _myUid,
    );

    if (snap.docs.isEmpty) return 1;

    // Tìm attempt number cao nhất
    int maxAttempt = 0;
    for (final doc in snap.docs) {
      final data = doc.data();
      final attempt = (data['attempt_number'] as num?)?.toInt() ?? 1;
      if (attempt > maxAttempt) maxAttempt = attempt;
    }

    return maxAttempt + 1;
  }

  // Lấy số attempt đã làm cho bài thi này
  Future<int> getAttemptCount(String examId, String classId) async {
    final snap = await firestore.queryWhere(
      'submissions',
      field: 'exam_id',
      isEqualTo: examId,
      field2: 'student_id',
      isEqualTo2: _myUid,
    );
    return snap.docs.length;
  }

  // Lấy submission tốt nhất (điểm cao nhất, nếu bằng điểm thì lấy lần làm gần nhất)
  Future<SubmissionModel?> getBestSubmission(String examId, String classId) async {
    final snap = await firestore.queryWhere(
      'submissions',
      field: 'exam_id',
      isEqualTo: examId,
      field2: 'student_id',
      isEqualTo2: _myUid,
    );

    if (snap.docs.isEmpty) return null;

    SubmissionModel? best;
    for (final doc in snap.docs) {
      final submission = SubmissionModel.fromJson(doc.data(), id: doc.id);
      if (best == null ||
          submission.score > best.score ||
          (submission.score == best.score &&
           DateTime.parse(submission.submittedAt).isAfter(DateTime.parse(best.submittedAt)))) {
        best = submission;
      }
    }

    return best;
  }

  // Nộp bài 

  Future<SubmissionModel> submitExam({
    required String examId,
    required String classId,
    required List<QuestionModel> questions,
    required Map<int, String> studentAnswers,
    required int durationSeconds,
    String examName = '', 
  }) async {
    if (_myUid.isEmpty) throw Exception('Chưa đăng nhập');

    // Lấy attempt number tiếp theo
    final attemptNumber = await _getNextAttemptNumber(examId, classId);

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
      attemptNumber: attemptNumber, // ← MỚI
    );

    final docRef =
        await firestore.addDocument('submissions', submission.toJson());
    final saved =
        SubmissionModel.fromJson(submission.toJson(), id: docRef.id);

    // Gửi thông báo bất đồng bộ — không chặn trả về kết quả cho user
    _sendNotificationsAfterSubmit(
      saved: saved,
      examId: examId,
      classId: classId,
      examName: examName,
      score: saved.score,
    );

    return saved;
  }

  // gửi tất cả thông báo sau khi nộp bài
  Future<void> _sendNotificationsAfterSubmit({
    required SubmissionModel saved,
    required String examId,
    required String classId,
    required String examName,
    required double score,
  }) async {
    try {
      // Lấy tên bài thi nếu không được truyền vào
      String resolvedExamName = examName;
      String teacherId = '';

      final examDoc = await firestore.getDocument('exams', examId);
      if (examDoc.exists && examDoc.data() != null) {
        final d = examDoc.data()!;
        if (resolvedExamName.isEmpty) {
          resolvedExamName = (d['title'] ?? d['name'] ?? 'Bài kiểm tra') as String;
        }
        teacherId = (d['teacher_id'] as String?) ?? '';
      }

      // Lấy tên học sinh
      String studentName = '';
      final userDoc = await firestore.getDocument('users', _myUid);
      if (userDoc.exists && userDoc.data() != null) {
        studentName = (userDoc.data()!['name'] as String?) ?? '';
      }

      // Đếm số bài đã nộp trong lớp
      final subSnap = await firestore.queryWhere(
        'submissions',
        field: 'exam_id',
        isEqualTo: examId,
      );
      final submittedCount =
          subSnap.docs.where((d) => d.data()['class_id'] == classId).length;

      // Lấy tổng số học sinh trong lớp
      final memberSnap = await firestore.queryWhere(
        'class_members',
        field: 'class_id',
        isEqualTo: classId,
      );
      final totalCount =
          memberSnap.docs.where((d) => d.data()['status'] == 'active').length;

      // HS: xác nhận nộp bài
      await _notif.notifySubmissionSuccess(
        studentId: _myUid,
        examName: resolvedExamName,
        examId: examId,
        classId: classId,
        score: score,
      );

      if (teacherId.isNotEmpty) {
        // GV: có bài nộp mới
        await _notif.notifyTeacherNewSubmission(
          teacherId: teacherId,
          studentName: studentName.isNotEmpty ? studentName : 'Học sinh',
          examName: resolvedExamName,
          examId: examId,
          classId: classId,
          submittedCount: submittedCount,
          totalCount: totalCount,
        );

        // GV: cột mốc 100% (submittedCount đã bao gồm bài vừa nộp)
        if (totalCount > 0 && submittedCount >= totalCount) {
          final classDoc = await firestore.getDocument('classes', classId);
          final className =
              (classDoc.data()?['name'] as String?) ?? 'Lớp học';
          await _notif.notifyAllStudentsSubmitted(
            teacherId: teacherId,
            examName: resolvedExamName,
            examId: examId,
            classId: classId,
            className: className,
            totalCount: totalCount,
          );
        }
      }
    } catch (_) {
      // Lỗi thông báo không làm fail luồng nộp bài
    }
  }

 

  Future<SubmissionModel?> getMySubmission(
      {required String examId, required String classId}) async {
    return getBestSubmission(examId, classId);
  }


 Stream<Map<String, SubmissionModel>> streamMySubmissionsForClass(String classId) {
    if (_myUid.isEmpty) return Stream.value({});
    
    // gọi thẳng lên Firebase với 2 điều kiện (cần tạo Composite Index trên Firebase Console)
    return firestore
        .streamWhere(
          'submissions', 
          field: 'student_id', 
          isEqualTo: _myUid,
          field2: 'class_id', 
          isEqualTo2: classId,
        )
        .map((snap) {
          final map = <String, SubmissionModel>{};
          for (final d in snap.docs) {
            final sub = SubmissionModel.fromJson(d.data(), id: d.id);
            // Lấy submission tốt nhất cho mỗi exam (điểm cao nhất, nếu bằng điểm thì lấy lần gần nhất)
            final existing = map[sub.examId];
            if (existing == null ||
                sub.score > existing.score ||
                (sub.score == existing.score &&
                 DateTime.parse(sub.submittedAt).isAfter(DateTime.parse(existing.submittedAt)))) {
              map[sub.examId] = sub;
            }
          }
          return map;
        });
  }
  //chạy app màn hình danh sách có thể báo lỗi đỏ ở Debug Console yêu cầu tạo Index. 
  //click vào link xanh trong báo lỗi để Firebase tự động tạo Index



  Stream<List<SubmissionModel>> streamSubmissionsForExamAndClass({
    required String examId,
    required String classId,
  }) {
    return firestore
        .streamWhere('submissions', field: 'exam_id', isEqualTo: examId)
        .map((snap) => snap.docs
            .map((d) => SubmissionModel.fromJson(d.data(), id: d.id))
            .where((s) => s.classId == classId)
            .toList());
  }


  Future<Map<String, int>> getStudentStats() async {
    if (_myUid.isEmpty) return {'pending': 0, 'newToday': 0, 'done': 0};
    try {
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
    final studentAnswer  = chosen.trim().toLowerCase();
    switch (q.type) {
      case 'multiple_choice':
      case 'true_false':
      case 'fill_in':
      default:
        return studentAnswer == correctAnswer;
    }
  }

}