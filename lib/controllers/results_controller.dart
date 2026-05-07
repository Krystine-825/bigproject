import '../data/models/submission_model.dart';
import '../data/services/auth_service.dart';
import '../data/services/firestore_service.dart';

class StudentResultsController {
  final _auth = AuthService();
  final _firestore = FireStoreService();

  String get _uid => _auth.currentUid ?? '';

  // Chuyển sang Stream + fix N+1: fetch exam & class song song thay vì tuần tự
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

          // Future.wait: fetch tất cả exam + class song song cùng lúc
          
          final results = await Future.wait(
            snap.docs.map((doc) async {
              final sub = SubmissionModel.fromJson(doc.data(), id: doc.id);

              // Fetch exam và class song song
              final fetched = await Future.wait([
                sub.examId.isNotEmpty
                    ? _firestore
                        .getDocument('exams', sub.examId)
                        .catchError((_) => null)
                    : Future.value(null),
                sub.classId.isNotEmpty
                    ? _firestore
                        .getDocument('classes', sub.classId)
                        .catchError((_) => null)
                    : Future.value(null),
              ]);

              final examDoc = fetched[0];
              final classDoc = fetched[1];


              String examName = 'Bài kiểm tra';
              if (examDoc != null && examDoc.exists && examDoc.data() != null) {
                final d = examDoc.data()!;
                final raw = (d['title'] ?? d['name'] ?? '') as String;
                if (raw.isNotEmpty) examName = raw;
              }


              String className = 'Lớp học';
              if (classDoc != null &&
                  classDoc.exists &&
                  classDoc.data() != null) {
                final raw =
                    (classDoc.data()!['name'] ?? '') as String;
                if (raw.isNotEmpty) className = raw;
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