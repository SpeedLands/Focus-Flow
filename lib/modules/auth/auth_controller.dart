import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:focus_flow/data/models/app_notification_model.dart';
import 'package:focus_flow/data/services/notification_service.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:focus_flow/data/models/user_model.dart';
import 'package:focus_flow/data/providers/auth_provider.dart';
import 'package:focus_flow/routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthProvider _authProvider = Get.find<AuthProvider>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController loginEmailController = TextEditingController();
  final TextEditingController loginPasswordController = TextEditingController();
  final RxBool isLoginLoading = false.obs;
  final RxString loginError = ''.obs;
  final RxBool loginPasswordVisible = false.obs;

  final TextEditingController registerNameController = TextEditingController();
  final TextEditingController registerEmailController = TextEditingController();
  final TextEditingController registerPasswordController =
      TextEditingController();
  final TextEditingController registerConfirmPasswordController =
      TextEditingController();
  final RxBool isRegisterLoading = false.obs;
  final RxString registerError = ''.obs;
  final RxBool registerPasswordVisible = false.obs;
  final RxBool registerConfirmPasswordVisible = false.obs;

  final TextEditingController editNameController = TextEditingController();
  final RxBool isProfileUpdating = false.obs;

  NotificationService get _notificationService =>
      Get.find<NotificationService>();

  final Rx<UserData?> currentUser = Rx<UserData?>(null);
  final RxBool isAuthenticated = false.obs;
  StreamSubscription<firebase_auth.User?>? _authStateSubscription;

  @override
  void onInit() {
    super.onInit();
    _listenToAuthStateChanges();
  }

  Future<void> updateUserDeviceToken(String? newDeviceToken) async {
    final firebase_auth.User? firebaseUser = _authProvider.currentUser;
    if (firebaseUser == null ||
        newDeviceToken == null ||
        newDeviceToken.isEmpty) {
      debugPrint(
        "AuthController: Usuario no logueado o token nulo, no se guardará el token FCM.",
      );
      return;
    }

    final String userId = firebaseUser.uid;
    final userDocRef = _firestore.collection('users').doc(userId);

    debugPrint(
      "AuthController: Actualizando token FCM ('$newDeviceToken') para el usuario: $userId",
    );
    try {
      await userDocRef.update({
        'fcmTokens': FieldValue.arrayUnion([newDeviceToken]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
      debugPrint(
        "AuthController: Token FCM añadido/actualizado exitosamente en Firestore para el usuario $userId.",
      );
    } catch (e) {
      if (e is FirebaseException && e.code == 'not-found') {
        debugPrint(
          "AuthController: El documento del usuario o el campo fcmTokens no existe. Creando/actualizando con set merge.",
        );
        try {
          await userDocRef.set({
            'fcmTokens': [newDeviceToken],
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          debugPrint(
            "AuthController: Campo fcmTokens creado y token añadido para el usuario $userId.",
          );
        } catch (e2) {
          debugPrint(
            "AuthController: Error al crear/actualizar fcmTokens con set merge para $userId: $e2",
          );
        }
      } else {
        debugPrint(
          "AuthController: Error al actualizar el token FCM en Firestore para $userId: $e",
        );
      }
    }
  }

  Future<void> removeUserDeviceToken(String? deviceTokenToRemove) async {
    final firebase_auth.User? firebaseUser = _authProvider.currentUser;
    if (firebaseUser == null ||
        deviceTokenToRemove == null ||
        deviceTokenToRemove.isEmpty) {
      debugPrint(
        "AuthController: Usuario no logueado o token a eliminar nulo, no se removerá el token FCM.",
      );
      return;
    }
    final String userId = firebaseUser.uid;
    final userDocRef = _firestore.collection('users').doc(userId);

    debugPrint(
      "AuthController: Intentando remover el token FCM ('$deviceTokenToRemove') del usuario: $userId",
    );
    try {
      await userDocRef.update({
        'fcmTokens': FieldValue.arrayRemove([deviceTokenToRemove]),
      });
      debugPrint(
        "AuthController: Token FCM '$deviceTokenToRemove' removido exitosamente de Firestore para el usuario $userId.",
      );
    } catch (e) {
      debugPrint(
        "AuthController: Error al remover el token FCM '$deviceTokenToRemove' de Firestore para $userId: $e",
      );
    }
  }

  final GlobalKey<FormState> registerFormKey = GlobalKey<FormState>();

  Future<void> registerWithFormValidation() async {
    if (registerFormKey.currentState?.validate() ?? false) {
      await register();
    } else {}
  }

  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  Future<void> loginWithFormValidation() async {
    if (loginFormKey.currentState?.validate() ?? false) {
      await login();
    }
  }

  void _listenToAuthStateChanges() {
    _authStateSubscription?.cancel();
    _authStateSubscription = _authProvider.authStateChanges.listen((
      firebaseUser,
    ) async {
      if (firebaseUser != null) {
        try {
          final bool wasAlreadyAuthenticated = isAuthenticated.value;

          final userData = await _authProvider.getUserData(firebaseUser.uid);
          if (userData != null) {
            currentUser.value = userData;
            isAuthenticated.value = true;
            editNameController.text = userData.name ?? '';

            final String? currentDeviceToken =
                NotificationService.instance.currentDeviceToken;
            await NotificationService.instance
                .uploadCurrentDeviceTokenIfAvailable();

            if (!wasAlreadyAuthenticated && currentDeviceToken != null) {
              debugPrint(
                "AuthController: New login detected for user ${firebaseUser.uid} on device with token $currentDeviceToken. Checking for other devices.",
              );
              await _sendNewDeviceLoginNotificationToOtherDevices(
                firebaseUser.uid,
                currentDeviceToken,
              );
            }

            final bool isNavigatingFromNotification =
                NotificationService.instance.isNavigatingFromNotification;

            if (isNavigatingFromNotification) {
              debugPrint(
                "AuthController: Navegación por notificación en curso, omitiendo redirección a HOME.",
              );
            } else {
              final authRoutes = [AppRoutes.LOGIN, AppRoutes.REGISTER];
              if (authRoutes.contains(Get.currentRoute) ||
                  Get.currentRoute.isEmpty) {
                Get.offAllNamed(AppRoutes.HOME);
              } else {
                debugPrint(
                  "Usuario autenticado y ya en una ruta válida: ${Get.currentRoute}",
                );
              }
            }
          } else {
            debugPrint(
              "Error: Usuario en Firebase Auth pero sin datos en Firestore. UID: ${firebaseUser.uid}",
            );
            await logout();
          }
        } catch (e) {
          debugPrint(
            "Error al obtener UserData tras cambio de estado de auth: $e",
          );
          await logout();
        }
      } else {
        final lastKnownToken = NotificationService.instance.currentDeviceToken;

        NotificationService.instance.setNavigatingFromNotification(false);

        currentUser.value = null;
        isAuthenticated.value = false;
        loginError.value = '';
        registerError.value = '';
        clearLoginFields();
        clearRegisterFields();
        editNameController.clear();

        final authRoutes = [AppRoutes.LOGIN, AppRoutes.REGISTER];
        if (!authRoutes.contains(Get.currentRoute)) {
          Get.offAllNamed(AppRoutes.LOGIN);
        } else {
          debugPrint(
            "Usuario no autenticado y ya en una ruta de autenticación: ${Get.currentRoute}",
          );
        }
      }
    });
  }

  Future<void> login() async {
    if (loginEmailController.text.isEmpty ||
        loginPasswordController.text.isEmpty) {
      loginError.value = "Por favor, completa todos los campos.";
      Get.snackbar(
        "Campos incompletos",
        "Por favor, completa todos los campos.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }
    isLoginLoading.value = true;
    loginError.value = '';
    try {
      final UserData? user = await _authProvider.login(
        loginEmailController.text.trim(),
        loginPasswordController.text.trim(),
      );
      if (user == null && _authProvider.currentUser == null) {
        loginError.value = "Credenciales incorrectas o error desconocido.";
        Get.snackbar(
          "Error de Inicio de Sesión",
          "Credenciales incorrectas o error desconocido.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      loginError.value = _mapFirebaseAuthExceptionMessage(e);
      Get.snackbar(
        "Error de Inicio de Sesión",
        _mapFirebaseAuthExceptionMessage(e),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      loginError.value = "Ocurrió un error inesperado: ${e.toString()}";
      Get.snackbar(
        "Error Inesperado",
        "Ocurrió un error: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isLoginLoading.value = false;
    }
  }

  Future<void> register() async {
    if (registerNameController.text.isEmpty ||
        registerEmailController.text.isEmpty ||
        registerPasswordController.text.isEmpty ||
        registerConfirmPasswordController.text.isEmpty) {
      registerError.value = "Por favor, completa todos los campos.";
      Get.snackbar(
        "Campos incompletos",
        "Por favor, completa todos los campos de registro.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }
    if (registerPasswordController.text !=
        registerConfirmPasswordController.text) {
      registerError.value = "Las contraseñas no coinciden.";
      Get.snackbar(
        "Error de Contraseña",
        "Las contraseñas no coinciden.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }
    isRegisterLoading.value = true;
    registerError.value = '';
    UserData newUserModel = UserData(
      uid: '',
      email: registerEmailController.text.trim(),
      name: registerNameController.text.trim(),
    );
    try {
      final UserData? user = await _authProvider.register(
        registerEmailController.text.trim(),
        registerPasswordController.text.trim(),
        newUserModel,
      );
      if (user != null) {
        Get.snackbar(
          "Registro Exitoso",
          "Se ha enviado un correo de verificación a ${user.email}. Por favor, verifica tu cuenta.",
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
        clearRegisterFields();
      } else {
        registerError.value = "Error desconocido durante el registro.";
        Get.snackbar(
          "Error de Registro",
          "No se pudo completar el registro.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      registerError.value = _mapFirebaseAuthExceptionMessage(e);
      Get.snackbar(
        "Error de Registro",
        _mapFirebaseAuthExceptionMessage(e),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      registerError.value = "Ocurrió un error inesperado: ${e.toString()}";
      Get.snackbar(
        "Error Inesperado",
        "Ocurrió un error: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isRegisterLoading.value = false;
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      await _authProvider.sendEmailVerification();
      Get.snackbar(
        "Correo Enviado",
        "Se ha reenviado el correo de verificación.",
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudo reenviar el correo: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> checkEmailVerificationStatus() async {
    if (_authProvider.currentUser != null) {
      await _authProvider.currentUser!.reload();
      if (await _authProvider.isCurrentUserEmailVerified()) {
        final userData = await _authProvider.getUserData(
          _authProvider.currentUser!.uid,
        );
        if (userData != null) {
          currentUser.value = userData;
          isAuthenticated.value = true;
          if (Get.currentRoute != AppRoutes.HOME &&
              Get.currentRoute.isNotEmpty) {
            Get.offAllNamed(AppRoutes.HOME);
          } else if (Get.currentRoute.isEmpty) {
            Get.offAllNamed(AppRoutes.HOME);
          }
        } else {
          await logout();
        }
      } else {
        Get.snackbar(
          "Verificación Pendiente",
          "Tu correo electrónico aún no ha sido verificado.",
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Future<void> logout() async {
    try {
      final currentToken = NotificationService.instance.currentDeviceToken;
      if (currentToken != null && isAuthenticated.value) {
        await removeUserDeviceToken(currentToken);
      }
      await _authProvider.logout();
    } catch (e) {
      Get.snackbar(
        "Error al cerrar sesión",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> resetPassword(String email) async {
    if (email.isEmpty || !GetUtils.isEmail(email)) {
      Get.snackbar(
        "Error",
        "Por favor, introduce un correo electrónico válido.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    isLoginLoading.value = true;
    try {
      await _authProvider.resetPassword(email);
      Get.snackbar(
        "Correo Enviado",
        "Si el correo está registrado, recibirás un enlace para restablecer tu contraseña.",
        snackPosition: SnackPosition.BOTTOM,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      Get.snackbar(
        "Error",
        _mapFirebaseAuthExceptionMessage(e),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Ocurrió un error: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoginLoading.value = false;
    }
  }

  Future<void> updateUserName(String newName) async {
    if (newName.trim().isEmpty) {
      Get.snackbar(
        "Error",
        "El nombre no puede estar vacío.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    if (currentUser.value == null) {
      Get.snackbar(
        "Error",
        "Usuario no autenticado.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isProfileUpdating.value = true;
    final String userId = currentUser.value!.uid;
    final String oldName = currentUser.value!.name ?? "Usuario";
    final String? currentDeviceToken = _notificationService.currentDeviceToken;

    try {
      final firebaseUser = _authProvider.currentUser;
      if (firebaseUser != null) {
        await firebaseUser.updateDisplayName(newName.trim());
      }

      await _firestore.collection('users').doc(userId).update({
        'name': newName.trim(),
      });

      currentUser.value = currentUser.value?.copyWith(name: newName.trim());
      editNameController.text = newName.trim();

      Get.snackbar(
        "Éxito",
        "Nombre actualizado correctamente.",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      await _sendNameUpdateNotificationToOtherDevices(
        userId,
        newName.trim(),
        oldName,
        currentDeviceToken,
      );
    } catch (e) {
      debugPrint("Error al actualizar nombre: $e");
      Get.snackbar(
        "Error",
        "No se pudo actualizar el nombre: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isProfileUpdating.value = false;
    }
  }

  Future<void> _sendNameUpdateNotificationToOtherDevices(
    String userId,
    String newName,
    String oldName,
    String? currentDeviceToken,
  ) async {
    if (currentDeviceToken == null) {
      debugPrint(
        "AuthController: No current device token, cannot determine 'other' devices for name update notification.",
      );
      return;
    }

    List<String>? allUserTokens = await getUserFcmTokens(userId);
    if (allUserTokens == null || allUserTokens.isEmpty) {
      debugPrint(
        "AuthController: User $userId has no FCM tokens, no name update notification sent.",
      );
      return;
    }

    final List<String> otherDeviceTokens = allUserTokens
        .where((token) => token != currentDeviceToken && token.isNotEmpty)
        .toList();

    if (otherDeviceTokens.isEmpty) {
      debugPrint(
        "AuthController: No other devices found for user $userId to send name update notification.",
      );
      return;
    }

    final String title = "Perfil Actualizado";
    final String body =
        "Tu nombre ha sido cambiado de '$oldName' a '$newName'.";
    final Map<String, String> dataPayload = {
      'type': 'user_profile_name_updated',
      'newName': newName,
      'oldName': oldName,
      'userId': userId,
    };

    debugPrint(
      "AuthController: Sending name update notification to tokens: $otherDeviceTokens",
    );

    for (String token in otherDeviceTokens) {
      try {
        await _notificationService.sendNotificationToDevice(
          targetDeviceToken: token,
          title: title,
          body: body,
          data: dataPayload,
        );
        debugPrint(
          "AuthController: Name update notification sent to token $token",
        );
      } catch (e) {
        debugPrint(
          "AuthController: Failed to send name update notification to token $token: $e",
        );
      }
    }
  }

  Future<void> _sendNewDeviceLoginNotificationToOtherDevices(
    String userId,
    String currentDeviceToken,
  ) async {
    List<String>? allUserTokens = await getUserFcmTokens(userId);

    if (allUserTokens == null || allUserTokens.isEmpty) {
      debugPrint(
        "AuthController: User $userId has no FCM tokens. No new device login notification to send.",
      );
      return;
    }

    final List<String> otherDeviceTokens = allUserTokens
        .where((token) => token != currentDeviceToken && token.isNotEmpty)
        .toList();

    if (otherDeviceTokens.isEmpty) {
      debugPrint(
        "AuthController: No other previously active devices found for user $userId. No new device login notification sent.",
      );
      return;
    }

    final String title = "Nuevo Inicio de Sesión";
    final String body =
        "Tu cuenta ha sido accedida desde un nuevo dispositivo.";
    final Map<String, String> dataPayload = {
      'type': 'new_device_login',
      'userId': userId,
    };

    debugPrint(
      "AuthController: Sending new device login notification to tokens: $otherDeviceTokens",
    );

    for (String token in otherDeviceTokens) {
      try {
        await _notificationService.sendNotificationToDevice(
          targetDeviceToken: token,
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
  }

  Future<void> addUserNotification(
    String userId,
    AppNotificationModel notification,
  ) async {
    if (userId.isEmpty) {
      debugPrint(
        "AuthController: User ID vacío, no se puede guardar AppNotification.",
      );
      return;
    }
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('app_notifications')
          .add(notification.toJson());
      debugPrint("AppNotification guardada para $userId");
    } catch (e) {
      debugPrint("Error guardando AppNotification para $userId: $e");
    }
  }

  Future<List<String>?> getUserFcmTokens(String memberId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(memberId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null && data.containsKey('fcmTokens')) {
          final fcmTokens = List<String>.from(data['fcmTokens'] ?? []);
          debugPrint("Tokens FCM del usuario $memberId: $fcmTokens");
          return fcmTokens;
        } else {
          debugPrint("El usuario $memberId no tiene tokens FCM registrados.");
        }
      } else {
        debugPrint("No se encontró el documento del usuario $memberId.");
      }
    } catch (e) {
      debugPrint("Error al obtener los tokens FCM del usuario $memberId: $e");
    }
    return null;
  }

  Future<List<String>?> getUserFcmTokensByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        final userDoc = querySnapshot.docs.first;
        final data = userDoc.data();
        if (data.containsKey('fcmTokens')) {
          final fcmTokens = List<String>.from(data['fcmTokens'] ?? []);
          debugPrint("Tokens FCM del usuario con email $email: $fcmTokens");
          return fcmTokens;
        } else {
          debugPrint(
            "El usuario con email $email no tiene tokens FCM registrados.",
          );
        }
      } else {
        debugPrint("No se encontró un usuario con el email $email.");
      }
    } catch (e) {
      debugPrint(
        "Error al obtener los tokens FCM del usuario con email $email: $e",
      );
    }
    return null;
  }

  Future<UserData?> getUserDataByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        return UserData.fromFirestore(querySnapshot.docs.first);
      }
    } catch (e) {
      debugPrint("Error al obtener UserData por email $email: $e");
    }
    return null;
  }

  void toggleLoginPasswordVisibility() {
    loginPasswordVisible.value = !loginPasswordVisible.value;
  }

  void toggleRegisterPasswordVisibility() {
    registerPasswordVisible.value = !registerPasswordVisible.value;
  }

  void toggleRegisterConfirmPasswordVisibility() {
    registerConfirmPasswordVisible.value =
        !registerConfirmPasswordVisible.value;
  }

  void clearLoginFields() {
    loginEmailController.clear();
    loginPasswordController.clear();
    loginError.value = '';
  }

  void clearRegisterFields() {
    registerNameController.clear();
    registerEmailController.clear();
    registerPasswordController.clear();
    registerConfirmPasswordController.clear();
    registerError.value = '';
  }

  String _mapFirebaseAuthExceptionMessage(
    firebase_auth.FirebaseAuthException e,
  ) {
    switch (e.code) {
      case 'user-not-found':
        return 'No se encontró un usuario con ese correo electrónico.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'email-already-in-use':
        return 'Este correo electrónico ya está en uso.';
      case 'weak-password':
        return 'La contraseña es demasiado débil.';
      case 'invalid-email':
        return 'El formato del correo electrónico no es válido.';
      case 'operation-not-allowed':
        return 'Operación no permitida. Contacta al administrador.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';
      default:
        return 'Ocurrió un error de autenticación: ${e.message} (código: ${e.code})';
    }
  }
}
