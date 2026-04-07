import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
//import 'package:firebase_auth/firebase_auth.dart';


class UploadResult {
  final String downloadUrl;
  final String storagePath;
 
  const UploadResult({
    required this.downloadUrl,
    required this.storagePath,
  });
}
 
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
 
  Future<UploadResult> uploadPdf(
  // final user = FirebaseAuth.instance.currentUser;
  // print('=== DEBUG: currentUser = ${user?.uid}');
    File file,
    String teacherId,
    String fileName,
  ) async {
    try {
      // Clean file name (tránh lỗi ký tự đặc biệt)
      final cleanName = fileName
          .replaceAll(RegExp(r'[^\w\s.-]'), '')
          .replaceAll(' ', '_');
 
      // Path tạo 1 lần duy nhất — dùng chung cho upload lẫn getDownloadURL
      final storagePath =
          'exam_materials/$teacherId/${DateTime.now().millisecondsSinceEpoch}_$cleanName';
 
      final ref = _storage.ref(storagePath);
 
      //  Lấy snapshot để kiểm tra TaskState trước khi getDownloadURL
      final snapshot = await ref.putFile(
        file,
        SettableMetadata(contentType: 'application/pdf'),
      );
 
      if (snapshot.state != TaskState.success) {
        throw Exception('Upload thất bại');
      }
 
      // Buffer nhỏ để Storage propagate trước khi Cloud Function đọc
      await Future.delayed(const Duration(milliseconds: 500));
 
      final downloadUrl = await ref.getDownloadURL();
 
      return UploadResult(downloadUrl: downloadUrl, storagePath: storagePath);
    } catch (e) {
      throw Exception('Upload PDF lỗi: $e');
    }
  }
}
 