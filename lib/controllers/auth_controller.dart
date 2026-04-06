
import 'package:firebase_auth/firebase_auth.dart';
import '../data/services/auth_service.dart';
import '../data/services/firestore_service.dart';
import '../data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthController {
  final authService = AuthService();
  final fireStoreService = FireStoreService();
  String userName = "";


  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      
      final isDuplicate = await checkEmailExists(email);
      if (isDuplicate) {
        return 'Email này đã được sử dụng trong hệ thống.';
      }

      
      final credential = await authService.createUser(
        email: email,
        password: password,
      );

      
      final user = UserModel(
        uid: credential.user!.uid,
        name: name,
        email: email,
        role: role,
      );

      await fireStoreService.setDocument('users', user.uid, user.toJson());
      return null; // Đăng ký thành công
      
    } on FirebaseAuthException catch (e) {
      return translateError(e.code);
    } catch (_) {
      return 'Đăng ký thất bại. Vui lòng thử lại.';
    }
  }


  Future<String?> login({
      required String email,
      required String password,
  }) async {
    try {
      await authService.signIn(email: email, password: password);
      return null;
    }on FirebaseAuthException catch (e) {
      return translateError(e.code);
    } catch (_){
      return 'Đăng nhập thất bại. Vui lòng thử lại.';
    }

  }

  Future<String?> signInWithGoogle() async {
    try {
      
      final userCredential = await authService.signInWithGoogle();
      
      if (userCredential == null) return 'cancel';

      final uid = userCredential.user!.uid;
      final doc = await fireStoreService.getDocument('users', uid);

      if (doc.exists) {
        return null; 
      } else {
        return 'new_user'; 
      }
    } on FirebaseAuthException catch (e) {
      return translateError(e.code);
    } catch (_) {
      return 'Đăng nhập Google thất bại. Vui lòng thử lại.';
    }
  }

  Future<String> getUserName() async {
  final uid = authService.currentUid;
  if (uid == null) return '';
  final doc = await fireStoreService.getDocument('users', uid);
  return doc.data()?['name'] as String? ?? '';
  }
   Future<String?> resetPassword(String email) async {
    try {
      await authService.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return translateError(e.code);
    } catch (_) {
      return 'Gửi email đặt lại mật khẩu thất bại. Vui lòng thử lại.';
    }
   }


   Future<String?> getRole() async {
    final user = authService.currentUser; 
    if (user == null) return null;

    final doc = await fireStoreService.getDocument('users', user.uid);
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      
      userName = user.displayName ?? (data['name'] ?? ""); 
      
      return data['role'] as String?;
    }
    return null;
  }
   

   Future<String?> saveProfile({
     required String name,
    required String role,
    String? phone,
   })async {
    final uid = authService.currentUid;
    if (uid == null) return 'Phiên đăng nhập hết hạn.';
    try {
      final user = UserModel(
        uid: uid,
        name: name,
        email: authService.currentUser?.email ?? '',
        role: role,
        phone: phone?.isNotEmpty == true ? phone : null,
      );
      await fireStoreService.setDocument('users', uid, user.toJson());
      return null;
    } catch (_) {
      return 'Không thể lưu thông tin.';
    }
   }

   bool get isLoggedIn => authService.currentUser != null;


  String translateError(String code) {
    switch (code) {
      case 'email-already-in-use':   return 'Email đã được đăng ký rồi.';
      case 'invalid-email':          return 'Email không hợp lệ.';
      case 'weak-password':          return 'Mật khẩu quá yếu (tối thiểu 8 ký tự).';
      case 'user-not-found':         return 'Không tìm thấy tài khoản này.';
      case 'wrong-password':
      case 'invalid-credential':     return 'Email hoặc mật khẩu không đúng.';
      case 'too-many-requests':      return 'Thử lại quá nhiều lần. Vui lòng chờ.';
      case 'network-request-failed': return 'Mất kết nối mạng.';
      default:                       return 'Đã có lỗi xảy ra. Vui lòng thử lại.';
    }
  }

  // Hàm kiểm tra xem email đã tồn tại trong database chưa
  Future<bool> checkEmailExists(String email) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1) 
          .get();
          
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print("Lỗi kiểm tra email trùng: $e");
      return true; 
    }
  }

  // Hàm đăng xuất
  Future<void> signOut() async {
    await authService.signOut();
    userName = ""; 
  }
}