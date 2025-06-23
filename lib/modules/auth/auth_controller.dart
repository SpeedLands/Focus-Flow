import 'dart:async';
import 'package:flutter/material.dart';
import 'package:focus_flow/data/providers/notification_provider.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:focus_flow/data/models/user_model.dart';
import 'package:focus_flow/data/providers/auth_app_provider.dart';
import 'package:focus_flow/routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthProviderApp _authProvider = Get.find<AuthProviderApp>();
  final NotificationProvider _notificationProvider =
      Get.find<NotificationProvider>();

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

  final Rx<UserData?> currentUser = Rx<UserData?>(null);
  final RxBool isAuthenticated = false.obs;
  StreamSubscription<User?>? _authStateSubscription;

  @override
  void onInit() {
    super.onInit();
    _listenToAuthStateChanges();
  }

  Future<void> updateUserDeviceToken(String userId) async {
    await _notificationProvider.saveCurrentDeviceToken(userId);
  }

  Future<void> removeUserDeviceToken(String deviceTokenToRemove) async {
    _notificationProvider.removeCurrentDeviceToken(deviceTokenToRemove);
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
          final userData = await _authProvider.getUserData(firebaseUser.uid);
          if (userData != null) {
            currentUser.value = userData;
            isAuthenticated.value = true;
            editNameController.text = userData.name ?? '';

            await updateUserDeviceToken(currentUser.value!.uid);

            // final bool isNavigatingFromNotification =
            //     _notificationProvider.isNavigatingFromNotification;

            final authRoutes = [AppRoutes.LOGIN, AppRoutes.REGISTER];
            if (authRoutes.contains(Get.currentRoute) ||
                Get.currentRoute.isEmpty) {
              Get.offAllNamed(AppRoutes.HOME);
            } else {
              debugPrint(
                "Usuario autenticado y ya en una ruta válida: ${Get.currentRoute}",
              );
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
    } on FirebaseAuthException catch (e) {
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
    } on FirebaseAuthException catch (e) {
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

  Future<void> logout() async {
    try {
      final currentToken = await _notificationProvider.getCurrentDeviceToken();
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
    } on FirebaseAuthException catch (e) {
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
    _authProvider.updateUserName(newName);
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

  String _mapFirebaseAuthExceptionMessage(FirebaseAuthException e) {
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
