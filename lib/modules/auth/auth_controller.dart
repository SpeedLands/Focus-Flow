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

  // ... (otros observables sin cambios) ...
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

  final Rx<UserData?> currentUser = Rx<UserData?>(null);
  final RxBool isAuthenticated = false.obs;
  StreamSubscription<firebase_auth.User?>? _authStateSubscription;

  @override
  void onInit() {
    super.onInit();
    _listenToAuthStateChanges();
  }

  Future<void> updateUserDeviceToken(String? newDeviceToken) async {
    final firebase_auth.User? firebaseUser =
        _authProvider.currentUser; // Usar el de AuthProvider
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
    final firebase_auth.User? firebaseUser =
        _authProvider.currentUser; // Usar el de AuthProvider
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
      // No es crítico si el campo o el token no existe, así que solo logueamos el error.
      debugPrint(
        "AuthController: Error al remover el token FCM '$deviceTokenToRemove' de Firestore para $userId: $e",
      );
    }
  }

  final GlobalKey<FormState> registerFormKey = GlobalKey<FormState>();

  Future<void> registerWithFormValidation() async {
    if (registerFormKey.currentState?.validate() ?? false) {
      await register();
    } else {
      // Opcional: Mostrar un snackbar si la validación falla, aunque los campos ya muestran errores.
      // Get.snackbar("Error", "Por favor, corrige los errores en el formulario.");
    }
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
        // --- USUARIO AUTENTICADO ---
        try {
          final userData = await _authProvider.getUserData(firebaseUser.uid);
          if (userData != null) {
            currentUser.value = userData;
            isAuthenticated.value = true;

            // --- INICIO DE MODIFICACIÓN ---
            // Intentar subir el token FCM del dispositivo actual
            // NotificationService debe estar inicializado antes de este punto (ej. en main.dart o un binding inicial)
            await NotificationService.instance
                .uploadCurrentDeviceTokenIfAvailable();
            // --- FIN DE MODIFICACIÓN ---

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
                Get.offAllNamed(AppRoutes.HOME); // O tu ruta principal
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
        // --- USUARIO NO AUTENTICADO O DESLOGUEADO ---
        // Limpiar tokens aquí es importante si el logout no lo hizo por alguna razón
        // o si el estado cambia a no autenticado por otra vía.
        final lastKnownToken = NotificationService.instance.currentDeviceToken;
        if (lastKnownToken != null && currentUser.value != null) {
          // Si había un usuario y un token
          // No podemos estar seguros del UID aquí si currentUser.value ya es null
          // La limpieza de tokens es más segura en el método logout() explícito.
        }

        NotificationService.instance.setNavigatingFromNotification(false);

        currentUser.value = null;
        isAuthenticated.value = false;
        loginError.value = '';
        registerError.value = '';
        clearLoginFields(); // Limpiar campos cuando se desautentica
        clearRegisterFields();

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
    // ... (sin cambios significativos en la lógica interna, la navegación la maneja el listener)
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
      // El listener _listenToAuthStateChanges se encargará de la navegación si el login es exitoso
      if (user == null && _authProvider.currentUser == null) {
        // Si el provider retorna null y no hay usuario en firebase (fallo)
        loginError.value =
            "Credenciales incorrectas o error desconocido."; // Actualiza el error local
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
    // ... (sin cambios significativos en la lógica interna, la navegación la maneja el listener)
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
    // ... (sin cambios)
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
          // Navegación condicional
          if (Get.currentRoute != AppRoutes.HOME &&
              Get.currentRoute.isNotEmpty) {
            Get.offAllNamed(AppRoutes.HOME);
          } else if (Get.currentRoute.isEmpty) {
            Get.offAllNamed(AppRoutes.HOME);
          }
        } else {
          await logout(); // Si está verificado pero no hay datos, desloguear
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
    // --- INICIO DE MODIFICACIÓN ---
    try {
      // Primero remueve el token actual del dispositivo de la lista del usuario en Firestore
      final currentToken = NotificationService
          .instance
          .currentDeviceToken; // Asume que NotificationService es un singleton
      if (currentToken != null && isAuthenticated.value) {
        // Solo si está autenticado y hay token
        await removeUserDeviceToken(currentToken);
      }
      // --- FIN DE MODIFICACIÓN ---

      await _authProvider
          .logout(); // Esto debería disparar _listenToAuthStateChanges
      // clearLoginFields(); // Ya no es necesario aquí si _listenToAuthStateChanges lo hace
      // clearRegisterFields(); // Ya no es necesario aquí si _listenToAuthStateChanges lo hace
      // No es necesario llamar a Get.offAllNamed(AppRoutes.LOGIN) aquí,
      // _listenToAuthStateChanges se encargará de la redirección.
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
    // ... (sin cambios)
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

  // En AuthController
  Future<void> addUserNotification(
    String userId,
    AppNotificationModel notification,
  ) async {
    // final userId = _authProvider.currentUser?.uid; // Ya no lo obtenemos aquí
    if (userId.isEmpty) {
      debugPrint(
        "AuthController: User ID vacío, no se puede guardar AppNotification.",
      );
      return;
    }
    try {
      await _firestore
          .collection('users')
          .doc(userId) // Usar el userId proporcionado
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

  // --- Métodos de UI ---
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

  // --- Limpieza ---
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
    // ... (sin cambios)
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
