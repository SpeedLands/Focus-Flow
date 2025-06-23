import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/material.dart";
import "package:focus_flow/data/providers/notification_provider.dart";
import "package:focus_flow/data/services/auth_service.dart";
import "package:focus_flow/data/models/user_model.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:focus_flow/data/services/firestore_service.dart";

class AuthProviderApp {
  final AuthService _authService;
  final FirestoreService _firestoreService;
  final NotificationProvider _notificationProvider;

  AuthProviderApp(
    this._authService,
    this._firestoreService,
    this._notificationProvider,
  );

  final String _collectionName = "users";
  final String emailField = "email";

  Future<UserData?> getUserData(String uid) async {
    try {
      DocumentSnapshot? doc = await _firestoreService.getDocument(
        _collectionName,
        uid,
      );
      if (doc!.exists) {
        return UserData.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint("AuthService Error (getUserData): $e");
      rethrow;
    }
  }

  Future<void> updateUserName(String newName) async {
    final currentUserAuth = _authService.currentUser;
    if (currentUserAuth == null) {
      debugPrint("UpdateUserName: Usuario no autenticado.");
      return;
    }
    final trimmedNewName = newName.trim();
    if (trimmedNewName.isEmpty) {
      debugPrint("UpdateUserName: El nuevo nombre no puede estar vacío.");
      return;
    }

    final UserData? currentUserData = await getUserData(currentUserAuth.uid);
    if (currentUserData == null) {
      debugPrint(
        "UpdateUserName: No se pudieron obtener los datos del usuario actual desde Firestore.",
      );
      return;
    }

    final String userId = currentUserAuth.uid;
    final String oldName = currentUserData.name ?? "Usuario";

    if (oldName == trimmedNewName) {
      debugPrint(
        "UpdateUserName: El nuevo nombre es igual al anterior. No se realizan cambios.",
      );
      return;
    }

    try {
      await currentUserAuth.updateDisplayName(trimmedNewName);
      debugPrint(
        "Nombre de usuario actualizado en Firebase Auth a: $trimmedNewName",
      );

      await _firestoreService.updateDocument(_collectionName, userId, {
        'name': trimmedNewName,
      });
      debugPrint(
        "Nombre de usuario actualizado en Firestore para UID: $userId a $trimmedNewName",
      );
    } catch (e, stackTrace) {
      debugPrint(
        "Error actualizando el nombre de usuario (Auth o Firestore): $e\nStackTrace: $stackTrace",
      );
    }

    try {
      final String? currentDeviceToken = await _notificationProvider
          .getCurrentDeviceToken();

      List<String>? allUserTokens = await _notificationProvider
          .getUserTokensById(userId);

      if (allUserTokens == null || allUserTokens.isEmpty) {
        debugPrint(
          "UpdateUserName: Usuario $userId no tiene tokens FCM, no se envía notificación de actualización de nombre.",
        );
        return;
      }

      final List<String> otherDeviceTokens = allUserTokens
          .where(
            (token) =>
                token.isNotEmpty &&
                (currentDeviceToken == null || token != currentDeviceToken),
          )
          .toList();

      if (otherDeviceTokens.isEmpty) {
        debugPrint(
          "UpdateUserName: No se encontraron otros dispositivos para el usuario $userId para enviar notificación de actualización de nombre.",
        );
        return;
      }

      final String notificationTitle = "Nombre actualizado";
      final String notificationBody =
          "Tu nombre ha sido cambiado de '$oldName' a '$trimmedNewName'.";
      final Map<String, dynamic> dataPayload = {
        'type': 'user_profile_name_updated',
        'newName': trimmedNewName,
        'oldName': oldName,
        'userId': userId,
      };

      debugPrint(
        "UpdateUserName: Enviando notificación de actualización de nombre a ${otherDeviceTokens.length} dispositivo(s).",
      );

      for (String token in otherDeviceTokens) {
        try {
          bool sent = await _notificationProvider.sendNotificationToToken(
            token: token,
            title: notificationTitle,
            body: notificationBody,
            data: dataPayload,
          );
          if (sent) {
            debugPrint(
              "Notificación de actualización de nombre enviada a token: $token",
            );
          } else {
            debugPrint(
              "FALLO al enviar notificación de actualización de nombre a token: $token",
            );
          }
        } catch (e, stackTrace) {
          debugPrint(
            "UpdateUserName: Falló el envío de notificación de actualización de nombre al token $token: $e\nStackTrace: $stackTrace",
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint(
        "Error en la lógica de envío de notificación de actualización de nombre: $e\nStackTrace: $stackTrace",
      );
    }
  }

  Future<UserData?> register(
    String email,
    String password,
    UserData userDataModel,
  ) async {
    UserCredential? userCredential = await _authService.register(
      email,
      password,
      userDataModel,
    );
    User? firebaseUser = userCredential?.user;
    if (firebaseUser != null) {
      await _firestoreService.setDocument(
        firebaseUser.uid,
        'users',
        userDataModel.copyWith(uid: firebaseUser.uid, email: email).toMap(),
        null,
      );
      return userDataModel.copyWith(uid: firebaseUser.uid, email: email);
    }
    return null;
  }

  Future<UserData?> login(String email, String password) async {
    UserCredential? userCredential = await _authService.login(email, password);
    User? firebaseUser = userCredential?.user;
    if (firebaseUser != null) {
      String? currentDeviceToken = await _notificationProvider
          .getCurrentDeviceToken();
      List<String>? allUserTokens = await _notificationProvider
          .getUserTokensById(firebaseUser.uid);
      final List<String> otherDeviceTokens =
          allUserTokens
              ?.where(
                (token) => token.isNotEmpty && token != currentDeviceToken,
              )
              .toList() ??
          [];
      final String title = "Nuevo Inicio de Sesión";
      final String body =
          "Tu cuenta ha sido accedida desde un nuevo dispositivo.";
      final Map<String, String> dataPayload = {
        'type': 'new_device_login',
        'userId': firebaseUser.uid,
      };
      for (String token in otherDeviceTokens) {
        try {
          await _notificationProvider.sendNotificationToToken(
            token: token,
            title: title,
            body: body,
            data: dataPayload,
          );
          debugPrint(
            "AuthController: New device login notification sent to token $token",
          );
        } catch (e) {
          debugPrint(
            "AuthController: Failed to send new device login notification to token $token: $e",
          );
        }
      }
      return await getUserData(firebaseUser.uid);
    }
    return null;
  }

  Future<UserData?> getUserDataByEmail(String email) async {
    if (email.isEmpty) {
      debugPrint("Error: Email proporcionado está vacío.");
      return null;
    }
    final String normalizedEmail = email.trim().toLowerCase();

    try {
      final List<QueryDocumentSnapshot>? userDocs = await _firestoreService
          .getDocumentsWhere(
            collectionName: _collectionName,
            field: emailField,
            isEqualToValue: normalizedEmail,
            limit: 1,
          );

      if (userDocs == null) {
        debugPrint(
          "Error al consultar usuario por email '$normalizedEmail' (el servicio retornó null).",
        );
        return null;
      }

      if (userDocs.isEmpty) {
        debugPrint(
          "No se encontró un usuario con el email '$normalizedEmail'.",
        );
        return null;
      }

      final QueryDocumentSnapshot userDocSnapshot = userDocs.first;

      try {
        final UserData userData = UserData.fromFirestore(userDocSnapshot);
        debugPrint(
          "UserData obtenido para el email '$normalizedEmail': ID ${userData.uid}",
        );
        return userData;
      } catch (e, stackTrace) {
        debugPrint(
          "Error al convertir el documento a UserData para el email '$normalizedEmail' (ID: ${userDocSnapshot.id}): $e\nStackTrace: $stackTrace",
        );
        return null;
      }
    } on FirebaseException catch (e, stackTrace) {
      debugPrint(
        "Error de Firebase al obtener UserData por email '$normalizedEmail': ${e.message} (Código: ${e.code})\nStackTrace: $stackTrace",
      );
      return null;
    } catch (e, stackTrace) {
      debugPrint(
        "Error inesperado al obtener UserData por email '$normalizedEmail': $e\nStackTrace: $stackTrace",
      );
      return null;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  Future<void> resetPassword(String email) async {
    await _authService.resetPassword(email);
  }

  Stream<User?> get authStateChanges => _authService.authStateChanges;

  User? get currentUser => _authService.currentUser;
}
