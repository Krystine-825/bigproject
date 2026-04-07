import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import '../data/models/exam_model.dart';
import '../data/services/auth_service.dart';
import '../data/services/firestore_service.dart';
import '../data/services/storage_service.dart';

class ExamController {
  final  functions = FirebaseFunctions.instance;
  final  firestore = FireStoreService();
  final  auth      = AuthService();
  final  storage   = StorageService(); 

 //sinh đề
  Future<ExamModel> generateExam({
    required String examName,
    required File   pdfFile,
    required String extractedText,
    required String fileName,
    required int    questionCount,
    required String difficulty,
  }) async {
    final teacherId = auth.currentUid;
    if (teacherId == null) throw Exception('Người dùng chưa đăng nhập');

    final uploaded = await storage.uploadPdf(pdfFile, teacherId, fileName);

    final callable = functions.httpsCallable(
      'generateExamFromPdf',
      options: HttpsCallableOptions(
        timeout: const Duration(minutes: 3), 
      ),
    );

    final result = await callable.call<Map<String, dynamic>>({
      'teacherId':     teacherId,
      'pdfUrl':        uploaded.downloadUrl,
      'storagePath':   uploaded.storagePath,
      'extractedText': extractedText,
      'fileName':      fileName,
      'examName':      examName,
      'config': {
        'questionCount': questionCount,
        'difficulty':    difficulty,
        'questionTypes': ['multiple_choice', 'fill_in', 'true_false'],
      },
    });

    final data = result.data;
    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Tạo đề thi thất bại');
    }

    final examJson = data['exam'] as Map<String, dynamic>;
    final examId   = (examJson['exam_id'] ?? examJson['id'] ?? '') as String;
    if (examId.isEmpty) throw Exception('Không nhận được ID đề từ server');

    return ExamModel.fromJson(examJson, id: examId);
  }

 //lưu đề
  Future<void> saveExam(ExamModel exam) async {
    await firestore.setDocument('exams', exam.id, exam.toJson());
  }

  //  Giao đề cho lớp 
  Future<void> assignExam({
    required String   examId,
    required String   classId,
    required int      durationMinutes,
    required DateTime openAt,
    required DateTime closeAt,
    required int      maxAttempts,
  }) async {
    await firestore.updateDocument('exams', examId, {
      'status':           'assigned',
      'class_id':         classId,
      'duration_minutes': durationMinutes,
      'open_at':          openAt.toIso8601String(),
      'close_at':         closeAt.toIso8601String(),
     // 'max_attempts':     maxAttempts,
      'assigned_at':      DateTime.now().toIso8601String(),
    });
  }

  // Lấy danh sách lớp của giáo viên để giao đề
  Future<List<Map<String, String>>> getMyClasses() async {
    final teacherId = auth.currentUid ?? '';
    final snap = await firestore.queryWhere(
        'classes', field: 'teacher_id', isEqualTo: teacherId);
    return snap.docs
        .map((d) => {'id': d.id, 'name': (d.data()['name'] ?? '') as String})
        .toList();
  }

  // Xoá đề 
  Future<void> deleteExam(String examId) async {
    await firestore.deleteDocument('exams', examId);
  }
}