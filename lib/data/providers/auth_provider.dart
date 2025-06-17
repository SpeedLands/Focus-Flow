import "package:focus_flow/data/services/auth_service.dart";
import "package:focus_flow/data/models/user_model.dart";
import "package:firebase_auth/firebase_auth.dart";

class AuthProvider {
  final AuthService _authService;

  AuthProvider(this._authService);

  Future<UserData?> getUserData(String uid) async {
    UserData? userData = await _authService.getUserData(uid);
    if (userData == null) {}
    return userData;
  }

  Future<UserData?> register(
    String email,
    String password,
    UserData userDataModel,
  ) async {
    UserData? user = await _authService.register(
      email,
      password,
      userDataModel,
    );
    if (user != null) {
      await _authService.sendEmailVerification();
    }
    return user;
  }

  Future<UserData?> login(String email, String password) async {
    return await _authService.login(email, password);
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  Future<void> resetPassword(String email) async {
    await _authService.resetPassword(email);
  }

  Future<void> sendEmailVerification() async {
    await _authService.sendEmailVerification();
  }

  Future<bool> isCurrentUserEmailVerified() async {
    return await _authService.isEmailVerified();
  }

  Stream<User?> get authStateChanges => _authService.authStateChanges;

  User? get currentUser => FirebaseAuth.instance.currentUser;
}
