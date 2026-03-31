import 'package:flutter/material.dart';
import 'package:sambhasha_app/models/user_model.dart';
import 'package:sambhasha_app/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Google Sign In
  Future<String?> signInWithGoogle() async {
    setLoading(true);
    String? error = await _authService.signInWithGoogle();
    if (error == null) {
      await fetchUserData();
    }
    setLoading(false);
    return error;
  }

  // Phone Auth
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    setLoading(true);
    await _authService.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      onCodeSent: (id) {
        setLoading(false);
        onCodeSent(id);
      },
      onError: (err) {
        setLoading(false);
        onError(err);
      },
    );
  }

  Future<String?> signInWithPhone(String verificationId, String smsCode) async {
    setLoading(true);
    String? error = await _authService.signInWithPhone(verificationId, smsCode);
    if (error == null) {
      await fetchUserData();
    }
    setLoading(false);
    return error;
  }


  // Save user data (for manual profile updates)
  Future<void> saveUserDataToFirestore({
    required String name,
    required String profilePic,
    required Function onSuccess,
  }) async {
    setLoading(true);
    await _authService.saveUserData(name: name, profilePic: profilePic);
    _userModel = await _authService.getUserData(_authService.currentUser!.uid);
    setLoading(false);
    onSuccess();
  }

  // Fetch current user data
  Future<void> fetchUserData() async {
    if (_authService.currentUser != null) {
      _userModel = await _authService.getUserData(_authService.currentUser!.uid);
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    await _authService.logout();
    _userModel = null;
    notifyListeners();
  }
}

