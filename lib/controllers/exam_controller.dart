import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import '../data/models/exam_model.dart';
import '../data/services/auth_service.dart';
import '../data/services/firestore_service.dart';
import '../data/services/storage_service.dart';
import 'dart:convert';

class ExamController {
  final functions = FirebaseFunctions.instance;
  final firestore = FireStoreService();
  final auth = AuthService();
  final storage = StorageService();

  Future<ExamModel> generateExam({
    required String classId,
    required String examName,
    required File pdfFile,
    required String extractedText,
    required String fileName,
    required int questionCount,
    required String difficulty,
  }) async {
    final teacherId = auth.currentUid;
    if (teacherId == null) throw Exception('Người dùng chưa đăng nhập');

    final uploaded = await storage.uploadPdf(pdfFile, teacherId, fileName);

    final callable = functions.httpsCallable(
      'generateExamFromPdf',
      options: HttpsCallableOptions(timeout: const Duration(minutes: 3)),
    );

    final result = await callable.call({
      'classId': classId,
      'teacherId': teacherId,
      'pdfUrl': uploaded.downloadUrl,
      'storagePath': uploaded.storagePath,
      'extractedText': extractedText,
      'fileName': fileName,
      'config': {
        'questionCount': questionCount,
        'difficulty': difficulty,
        'questionTypes': ['multiple_choice', 'fill_in', 'true_false'],
      },
    });

    final String jsonString = jsonEncode(result.data);
    final Map<String, dynamic> data = jsonDecode(jsonString);

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Tạo đề thi thất bại');
    }

    final examJson = data['exam'] as Map<String, dynamic>;
    final examId = (examJson['exam_id'] ?? examJson['id'] ?? '') as String;

    if (examId.isEmpty) throw Exception('Không nhận được ID đề từ server');

    return ExamModel.fromJson(examJson, id: examId);
  }

  //lưu đề vào firestore
  Future<void> saveExam(ExamModel exam) async {
    await firestore.setDocument('exams', exam.id, exam.toJson());
  }

  // giao dề thi
  Future<void> assignExam({
    required String examId,
    required String classId,
    required String className,
    required int durationMinutes,
    required DateTime openAt,
    required DateTime closeAt,
    required int maxAttempts,
  }) async {
    final doc = await firestore.getDocument('exams', examId);
    final data = doc.data() ?? {};

    final existing = (data['assignments'] as List<dynamic>? ?? [])
        .map((a) => ExamAssignment.fromJson(a as Map<String, dynamic>))
        .toList();

    final alreadyAssigned = existing.any((a) => a.classId == classId);
    if (alreadyAssigned) {
      throw Exception('Đề đã được giao cho lớp này rồi');
    }

    final newAssignment = ExamAssignment(
      classId: classId,
      className: className,
      durationMinutes: durationMinutes,
      openAt: openAt,
      closeAt: closeAt,
      maxAttempts: maxAttempts,
      assignedAt: DateTime.now().toIso8601String(),
    );

    final updated = [...existing, newAssignment];
    final classIds = updated.map((a) => a.classId).toList();

    await firestore.updateDocument('exams', examId, {
      'status': 'assigned',
      'class_id': classId,
      'assignments': updated.map((a) => a.toJson()).toList(),
      'assigned_at': DateTime.now().toIso8601String(),
      'assigned_class_ids': classIds,
    });
  }

  // Lấy danh sách lớp để giao đề 
  Future<List<Map<String, String>>> getMyClasses() async {
    final teacherId = auth.currentUid ?? '';
    final snap = await firestore.queryWhere(
      'classes',
      field: 'teacher_id',
      isEqualTo: teacherId,
    );

    return snap.docs
        .map((d) => {
              'id': d.id,
              'name': (d.data()['name'] ?? '') as String,
            })
        .toList();
  }

  //  Stream đề thi của giáo viên
  Stream<List<ExamModel>> streamMyExams() {
    final teacherId = auth.currentUid ?? '';
    if (teacherId.isEmpty) return Stream.value([]);

    return firestore
        .streamWhere('exams', field: 'teacher_id', isEqualTo: teacherId)
        .map((snap) => snap.docs
            .map((doc) => ExamModel.fromJson(doc.data(), id: doc.id))
            .toList());
  }

  // Stream đề thi đã giao cho học sinh
  Stream<List<ExamModel>> streamAssignedExamsForStudent(String classId) {
    final studentId = auth.currentUid ?? '';
    if (studentId.isEmpty || classId.isEmpty) return Stream.value([]);

    return firestore
        .streamArrayContains(
          'exams',
          field: 'assigned_class_ids',
          value: classId,
        )
        .map((snap) {
          return snap.docs
              .map((doc) => ExamModel.fromJson(doc.data(), id: doc.id))
              .where((exam) => exam.assignments.any((a) => a.classId == classId))
              .toList()
            ..sort((a, b) {
              final closeA = a.assignments
                  .firstWhere((ass) => ass.classId == classId)
                  .closeAt;
              final closeB = b.assignments
                  .firstWhere((ass) => ass.classId == classId)
                  .closeAt;
              return closeA.compareTo(closeB);
            });
        });
  }

  // Xoá đề 
  Future<void> deleteExam(String examId) async {
    await firestore.deleteDocument('exams', examId);
  }
}