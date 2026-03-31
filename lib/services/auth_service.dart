import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sambhasha_app/models/user_model.dart';
import 'package:sambhasha_app/services/encryption_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final EncryptionService _encryption = EncryptionService();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // Google Sign In
  Future<String?> signInWithGoogle() async {
    try {
      debugPrint('Initiating Google Sign-In...');
      GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) return "Sign-in cancelled";

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Sync user data to Firestore
        await saveUserData(
          name: user.displayName ?? 'User',
          profilePic: user.photoURL ?? '',
        );
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Google Auth Error: ${e.code} - ${e.message}');
      return e.message;
    } catch (e) {
      debugPrint('General Auth Error: $e');
      return e.toString();
    }
  }

  // Phone Authentication: Step 1 - Send OTP
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolution (mostly Android)
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? "Verification failed");
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  // Phone Authentication: Step 2 - Sign In with OTP
  Future<String?> signInWithPhone(String verificationId, String smsCode) async {
    try {
      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // For new phone users, name is initially the phone number
        await saveUserData(
          name: user.phoneNumber ?? 'User',
          profilePic: '',
        );
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // Store user in Firestore with E2EE PubKey
  Future<void> saveUserData({
    required String name,
    required String profilePic,
  }) async {
    if (currentUser != null) {
      // 1. Check if user already exists to preserve PublicKey
      var doc = await _firestore.collection('users').doc(currentUser!.uid).get();
      String pubKey = '';
      
      if (doc.exists && doc.data()?['publicKey'] != null && (doc.data()?['publicKey'] as String).isNotEmpty) {
        pubKey = doc.data()!['publicKey'];
      } else {
        // 2. New User or Missing Key: Generate RSA Pair
        final keys = await _encryption.generateRSAKeys();
        pubKey = keys['publicKey'] ?? '';
      }

      UserModel user = UserModel(
        uid: currentUser!.uid,
        name: name,
        nameLowerCase: name.toLowerCase(),
        profilePic: profilePic,
        lastSeen: DateTime.now(),
        isOnline: true,
        publicKey: pubKey,
      );
      
      await _firestore.collection('users').doc(currentUser!.uid).set(user.toMap(), SetOptions(merge: true));
    }
  }

  // Get user data
  Future<UserModel?> getUserData(String uid) async {
    var doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  // Logout
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}

