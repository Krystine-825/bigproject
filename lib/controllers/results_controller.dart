import '../data/models/submission_model.dart';
import '../data/services/auth_service.dart';
import '../data/services/firestore_service.dart';

class StudentResultsController {
  final _auth = AuthService();
  final _firestore = FireStoreService();

  
  final Map<String, String> _examNameCache = {};
  final Map<String, String> _classNameCache = {};

  String get _uid => _auth.currentUid ?? '';

  Stream<List<Map<String, dynamic>>> streamResults() {
    if (_uid.isEmpty) return Stream.value([]);

    return _firestore
        .streamWhere(
          'submissions',
          field: 'student_id',
          isEqualTo: _uid,
          orderBy: 'submitted_at',
          descending: true,
        )
        .asyncMap((snap) async {
          if (snap.docs.isEmpty) return <Map<String, dynamic>>[];

          final results = await Future.wait(
            snap.docs.map((doc) async {
              final sub = SubmissionModel.fromJson(doc.data(), id: doc.id);

              // Lấy tên Đề thi (Ưu tiên RAM Cache)
              String examName = 'Bài kiểm tra';
              if (sub.examId.isNotEmpty) {
                if (_examNameCache.containsKey(sub.examId)) {
                  examName = _examNameCache[sub.examId]!;
                } else {
                  try {
                    final examDoc = await _firestore.getDocument('exams', sub.examId);
                    if (examDoc.exists && examDoc.data() != null) {
                      final raw = (examDoc.data()!['title'] ?? examDoc.data()!['name'] ?? '') as String;
                      if (raw.isNotEmpty) {
                        examName = raw;
                        _examNameCache[sub.examId] = raw; // Lưu vào Cache
                      }
                    }
                  } catch (_) {}
                }
              }

              // Lấy tên Lớp học (Ưu tiên RAM Cache)
              String className = 'Lớp học';
              if (sub.classId.isNotEmpty) {
                if (_classNameCache.containsKey(sub.classId)) {
                  className = _classNameCache[sub.classId]!;
                } else {
                  try {
                    final classDoc = await _firestore.getDocument('classes', sub.classId);
                    if (classDoc.exists && classDoc.data() != null) {
                      final raw = (classDoc.data()!['name'] ?? '') as String;
                      if (raw.isNotEmpty) {
                        className = raw;
                        _classNameCache[sub.classId] = raw; // Lưu vào Cache
                      }
                    }
                  } catch (_) {}
                }
              }

              DateTime submittedAt;
              try {
                submittedAt = sub.submittedAt.isNotEmpty
                    ? DateTime.parse(sub.submittedAt)
                    : DateTime.now();
              } catch (_) {
                submittedAt = DateTime.now();
              }

              return {
                'examName': examName,
                'className': className,
                'classId': sub.classId,
                'score': sub.score,
                'correctCount': sub.correctCount,
                'totalCount': sub.totalCount,
                'submittedAt': submittedAt,
              };
            }),
          );

          return results;
        });
  }
}