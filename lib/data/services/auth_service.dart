import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:focus_flow/data/models/user_model.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<UserCredential?> register(
    String email,
    String password,
    UserData userDataModel,
  ) async {
    try {
      final UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService Error (register): ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('AuthService Error (register - general): $e');
      rethrow;
    }
  }

  Future<UserCredential?> login(String email, String password) async {
    try {
      final UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService Error (login): ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('AuthService Error (login - general): $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      debugPrint('AuthService Error (logout): $e');
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService Error (resetPassword): ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('AuthService Error (resetPassword - general): $e');
      rethrow;
    }
  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => FirebaseAuth.instance.currentUser;
}
