import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  Future<UserCredential> createUser({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() =>    _auth.signOut();
    

  Future<void> sendPasswordResetEmail({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  User? get currentUser => _auth.currentUser;
  //String? get currentUid  => _auth.currentUser?.uid;
  
  Stream<User?> authStateChanges() => _auth.authStateChanges();

   Future<UserCredential?> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize();

    final GoogleSignInAccount googleUser = await googleSignIn.authenticate();
    if (googleUser == null) return null; // Người dùng bấm Hủy

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

}
