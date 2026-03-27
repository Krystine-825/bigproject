import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ĐĂNG KÝ KÈM ROLE & HỌ TÊN
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
        await _firestore.collection('users').doc(result.user!.uid).set({
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

  // ĐĂNG NHẬP
  Future<String?> login({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return "Success";
    } on FirebaseAuthException catch (e) {
      return "Email hoặc mật khẩu không chính xác.";
    }
  }

  // QUÊN MẬT KHẨU
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return "Success";
    } catch (e) {
      return "Không thể gửi yêu cầu. Vui lòng kiểm tra lại email.";
    }
  }

  Future<String> signInWithGoogle() async {
    try {
      // 1. Dùng phiên bản mới nhất của thư viện (Bắt buộc dùng instance)
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();

      // 2. Mở cửa sổ chọn tài khoản Google
      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
      if (googleUser == null) return "cancel";

      // 3. Chỉ lấy idToken (Firebase KHÔNG CẦN accessToken để đăng nhập thông thường)
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 4. Đưa idToken cho Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        // Đã xóa bỏ hoàn toàn dòng accessToken gây lỗi
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return "existing";
        } else {
          return "new"; 
        }
      }
      return "error";
    } catch (e) {
      print("Lỗi đăng nhập Google: $e");
      return "error";
    }
  }

  Future<void> completeUserProfile({
    required String name,
    required String phone,
    required String role,
  }) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        // Nếu ng dùng không nhập tên, tự động lấy tên từ Google Gmail
        'fullName': name.isNotEmpty ? name : (user.displayName ?? 'Học viên mới'),
        'email': user.email,
        'phone': phone,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // LẤY THÔNG TIN ROLE & PROFILE
  Future<DocumentSnapshot> getUserProfile() async {
    return await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
  }

  // THEO DÕI TRẠNG THÁI (Stream)
  Stream<User?> get userStatus => _auth.authStateChanges();

  // ĐĂNG XUẤT
  Future<void> logout() async {
    await _auth.signOut();
  }
}