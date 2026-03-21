import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. ĐĂNG KÝ KÈM ROLE & HỌ TÊN
  Future<String?> register({
    required String email,
    required String password,
    required String fullName,
    required String role, 
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await _db.collection('users').doc(result.user!.uid).set({
          'fullName': fullName,
          'email': email,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return "Success";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return "Email này đã được đăng ký.";
      if (e.code == 'weak-password') return "Mật khẩu quá yếu.";
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // 2. ĐĂNG NHẬP
  Future<String?> login({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return "Success";
    } on FirebaseAuthException catch (e) {
      return "Email hoặc mật khẩu không chính xác.";
    }
  }

  // 3. QUÊN MẬT KHẨU
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return "Success";
    } catch (e) {
      return "Không thể gửi yêu cầu. Vui lòng kiểm tra lại email.";
    }
  }

  // 4. LẤY THÔNG TIN ROLE & PROFILE
  Future<DocumentSnapshot> getUserProfile() async {
    return await _db.collection('users').doc(_auth.currentUser!.uid).get();
  }

  // 5. THEO DÕI TRẠNG THÁI (Stream)
  Stream<User?> get userStatus => _auth.authStateChanges();

  // 6. ĐĂNG XUẤT
  Future<void> logout() async {
    await _auth.signOut();
  }
}