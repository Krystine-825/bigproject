import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Singleton giữ cache danh sách lớp học toàn app.
/// Warm ngay khi ExamBankScreen khởi động → AssignExamScreen
/// luôn hiển thị danh sách lớp tức thì, không cần chờ Firestore.
class ClassCacheService {
  ClassCacheService._();
  static final ClassCacheService instance = ClassCacheService._();

  List<Map<String, String>>? _cache;
  bool _isLoading = false;

  /// Cache hiện tại (null = chưa load lần nào).
  List<Map<String, String>>? get cache => _cache;

  bool get hasCache => _cache != null;

  /// Xoá cache — gọi sau khi giao đề thành công để lần mở
  /// AssignExamScreen tiếp theo fetch lại dữ liệu mới.
  void invalidate() => _cache = null;

  /// Warm cache trong background.
  /// Gọi từ ExamBankScreen.initState() để cache sẵn sàng
  /// trước khi user bấm vào một đề bất kỳ.
  Future<void> warmUp() async {
    if (_cache != null || _isLoading) return; // đã có / đang load
    _isLoading = true;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isEmpty) return;

      final snap = await FirebaseFirestore.instance
          .collection('classes')
          .where('teacher_id', isEqualTo: uid)
          .get();

      _cache = snap.docs
          .map((d) => {'id': d.id, 'name': (d.data()['name'] ?? '') as String})
          .toList();
    } catch (_) {
      // Silent fail — AssignExamScreen sẽ tự fetch lại nếu cache vẫn null
    } finally {
      _isLoading = false;
    }
  }

  /// Fetch đồng bộ (dùng trong AssignExamScreen khi cache chưa có).
  /// Trả về danh sách lớp, đồng thời lưu vào cache.
  Future<List<Map<String, String>>> fetchAndCache() async {
    if (_cache != null) return _cache!;
    if (_isLoading) {
      // Chờ warmUp() đang chạy xong (polling nhẹ)
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return _cache ?? [];
    }

    _isLoading = true;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isEmpty) return [];

      final snap = await FirebaseFirestore.instance
          .collection('classes')
          .where('teacher_id', isEqualTo: uid)
          .get();

      _cache = snap.docs
          .map((d) => {'id': d.id, 'name': (d.data()['name'] ?? '') as String})
          .toList();

      return _cache!;
    } catch (_) {
      return [];
    } finally {
      _isLoading = false;
    }
  }
}