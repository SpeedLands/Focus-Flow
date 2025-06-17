import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:focus_flow/data/models/user_model.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserData?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        return UserData.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint("AuthService Error (getUserData): $e");
      rethrow;
    }
  }

  Future<UserData?> register(
    String email,
    String password,
    UserData userDataModel,
  ) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      User? firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(
              userDataModel
                  .copyWith(uid: firebaseUser.uid, email: email)
                  .toMap(),
            );
        return userDataModel.copyWith(uid: firebaseUser.uid, email: email);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint("AuthService Error (register): ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("AuthService Error (register - general): $e");
      rethrow;
    }
  }

  Future<UserData?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      User? firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        return await getUserData(firebaseUser.uid);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint("AuthService Error (login): ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("AuthService Error (login - general): $e");
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      debugPrint("AuthService Error (logout): $e");
      rethrow;
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      debugPrint("AuthService Error (sendEmailVerification): $e");
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint("AuthService Error (resetPassword): ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("AuthService Error (resetPassword - general): $e");
      rethrow;
    }
  }

  Future<bool> isEmailVerified() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.reload();
        return user.emailVerified;
      }
      return false;
    } catch (e) {
      debugPrint("AuthService Error (isEmailVerified): $e");
      rethrow;
    }
  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}
