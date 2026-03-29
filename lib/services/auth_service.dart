import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sambhasha_app/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<String?> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final usernameCheck = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (usernameCheck.docs.isNotEmpty) {
        return 'Username already exists';
      }

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await _saveUserToFirestore(result.user!, username);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (result.user != null) {
        await _updateLastSeen(result.user!.uid);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return 'Google sign in cancelled';

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      if (result.user != null) {
        final doc = await _firestore.collection('users').doc(result.user!.uid).get();
        if (!doc.exists) {
          await _saveUserToFirestore(result.user!, result.user!.displayName ?? 'User_${result.user!.uid.substring(0, 5)}');
        } else {
          await _updateLastSeen(result.user!.uid);
        }
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> verifyPhone({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) => onError(e.message ?? 'Verification failed'),
      codeSent: (String verificationId, int? resendToken) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<String?> signInWithPhone(String verificationId, String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode);
      UserCredential result = await _auth.signInWithCredential(credential);
      if (result.user != null) {
        final doc = await _firestore.collection('users').doc(result.user!.uid).get();
        if (!doc.exists) {
          await _saveUserToFirestore(result.user!, 'User_${result.user!.uid.substring(0, 5)}');
        }
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> _saveUserToFirestore(User user, String username) async {
    UserModel userModel = UserModel(
      uid: user.uid,
      username: username,
      email: user.email ?? '',
      photoURL: user.photoURL,
      bio: '',
      createdAt: DateTime.now(),
      isOnline: true,
      lastSeen: DateTime.now(),
    );
    await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
  }

  Future<void> _updateLastSeen(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Future<void> logout() async {
    if (currentUser != null) {
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
