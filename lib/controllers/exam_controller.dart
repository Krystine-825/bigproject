import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Đã thêm thư viện này để dùng FieldValue
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
    required String examName,
    required File pdfFile,
    required String extractedText,
    required String fileName,
    required int questionCount,
  }) async {
    final teacherId = auth.currentUid;
    if (teacherId == null) throw Exception('Người dùng chưa đăng nhập');

    final uploaded = await storage.uploadPdf(pdfFile, teacherId, fileName);

    final callable = functions.httpsCallable(
      'generateExamFromPdf',
      options: HttpsCallableOptions(timeout: const Duration(minutes: 3)),
    );

    final result = await callable.call({
      'teacherId': teacherId,
      'pdfUrl': uploaded.downloadUrl,
      'storagePath': uploaded.storagePath,
      'extractedText': extractedText,
      'fileName': fileName,
      'config': {
        'questionCount': questionCount,
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

  // lưu đề vào firestore
  Future<void> saveExam(ExamModel exam) async {
    await firestore.setDocument('exams', exam.id, exam.toJson());
  }

  // thử giao đề siêu tốc bằng FieldValue.arrayUnion
  Future<void> assignExam({
    required String examId,
    required String classId,
    required String className,
    required int durationMinutes,
    required DateTime openAt,
    required DateTime closeAt,
    required int maxAttempts,
  }) async {
    final newAssignment = {
      'classId': classId,
      'className': className,
      'durationMinutes': durationMinutes,
      'openAt': openAt.toIso8601String(),
      'closeAt': closeAt.toIso8601String(),
      'maxAttempts': maxAttempts,
      'assignedAt': DateTime.now().toIso8601String(),
    };

    // Bắn thẳng dữ liệu mới vào mảng trên server bằng 1 thao tác duy nhất
    await FirebaseFirestore.instance.collection('exams').doc(examId).update({
      'status': 'assigned',
      'class_id': classId,
      'assignments': FieldValue.arrayUnion([newAssignment]),
      'assigned_class_ids': FieldValue.arrayUnion([classId]),
      'assigned_at': DateTime.now().toIso8601String(),
    });
  }

  // Lấy danh sách lớp để giao đề (thêm Index hỗ trợ thử cho nhanh)
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

  // Stream đề thi của giáo viên
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