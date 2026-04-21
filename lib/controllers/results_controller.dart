import '../data/models/submission_model.dart';
import '../data/services/auth_service.dart';
import '../data/services/firestore_service.dart';

class StudentResultsController {
  final _auth = AuthService();
  final _firestore = FireStoreService();

  String get _uid => _auth.currentUid ?? '';

  Future<List<Map<String, dynamic>>> loadResults() async {
    if (_uid.isEmpty) return [];

    try {
      final subSnap = await _firestore.queryWhere(
        'submissions',
        field: 'student_id',
        isEqualTo: _uid,
        orderBy: 'submitted_at',
        descending: true,
      );

      if (subSnap.docs.isEmpty) return [];

      final results = <Map<String, dynamic>>[];

      for (final doc in subSnap.docs) {
        // Parse đúng qua model, không tự extract tay
        final sub = SubmissionModel.fromJson(doc.data(), id: doc.id);

        // Lấy tên bài kiểm tra — Firestore lưu là 'title' (từ cloud function)
        // fallback sang 'name' nếu đã được chuẩn hóa
        String examName = 'Bài kiểm tra';
        if (sub.examId.isNotEmpty) {
          try {
            final examDoc = await _firestore.getDocument('exams', sub.examId);
            if (examDoc.exists && examDoc.data() != null) {
              final d = examDoc.data()!;
              examName = (d['title'] ?? d['name'] ?? '') as String;
              if (examName.isEmpty) examName = 'Bài kiểm tra';
            }
          } catch (_) {}
        }

        // Lấy tên lớp
        String className = 'Lớp học';
        if (sub.classId.isNotEmpty) {
          try {
            final classDoc =
                await _firestore.getDocument('classes', sub.classId);
            if (classDoc.exists && classDoc.data() != null) {
              className =
                  (classDoc.data()!['name'] ?? 'Lớp học') as String;
            }
          } catch (_) {}
        }

        // Parse submittedAt — có thể là String ISO hoặc Firestore Timestamp
        DateTime submittedAt;
        try {
          submittedAt = sub.submittedAt.isNotEmpty
              ? DateTime.parse(sub.submittedAt)
              : DateTime.now();
        } catch (_) {
          submittedAt = DateTime.now();
        }

        results.add({
          'examName': examName,
          'className': className,
          'classId': sub.classId,
          'score': sub.score,
          'correctCount': sub.correctCount,
          'totalCount': sub.totalCount,
          'submittedAt': submittedAt,
        });
      }

      return results;
    } catch (_) {
      return [];
    }
  }
}