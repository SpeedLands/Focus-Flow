import 'dart:async';
import 'package:flutter/material.dart';
import 'package:focus_flow/data/providers/notification_provider.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:focus_flow/data/models/user_model.dart';
import 'package:focus_flow/data/providers/auth_app_provider.dart';
import 'package:focus_flow/routes/app_routes.dart';

class AuthController extends GetxController {
  final _authProvider = Get.find<AuthProviderApp>();
  final _notificationProvider = Get.find<NotificationProvider>();

  // Controladores del Login
  final loginEmailController = TextEditingController();
  final loginPasswordController = TextEditingController();
  final isLoginLoading = false.obs;
  final loginError = ''.obs;
  final loginPasswordVisible = false.obs;

  // Controladores del Registro
  final registerNameController = TextEditingController();
  final registerEmailController = TextEditingController();
  final registerPasswordController = TextEditingController();
  final registerConfirmPasswordController = TextEditingController();
  final isRegisterLoading = false.obs;
  final registerError = ''.obs;
  final registerPasswordVisible = false.obs;
  final registerConfirmPasswordVisible = false.obs;

  // Controladores del Perfil
  final editNameController = TextEditingController();
  final isProfileUpdating = false.obs;

  // Estado del Usuario
  final currentUser = Rx<UserData?>(null);
  final isAuthenticated = false.obs;
  StreamSubscription<User?>? _authStateSubscription;

  final registerFormKey = GlobalKey<FormState>();
  final loginFormKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    _authStateSubscription?.cancel();
    _authStateSubscription = _authProvider.authStateChanges.listen(_handleAuthState);
  }

  void _handleAuthState(User? firebaseUser) async {
    if (firebaseUser != null) {
      try {
        final userData = await _authProvider.getUserData(firebaseUser.uid);
        if (userData != null) {
          currentUser.value = userData;
          isAuthenticated.value = true;
          editNameController.text = userData.name ?? '';
          await _notificationProvider.saveCurrentDeviceToken(userData.uid);

          final authRoutes = [AppRoutes.LOGIN, AppRoutes.REGISTER];
          if (authRoutes.contains(Get.currentRoute) || Get.currentRoute.isEmpty) {
            Get.offAllNamed(AppRoutes.HOME);
          }
        } else {
          debugPrint("Usuario autenticado sin datos en Firestore.");
          await logout();
        }
      } catch (e) {
        debugPrint("Error al obtener datos de usuario: $e");
        await logout();
      }
    } else {
      _clearSession();
      if (![AppRoutes.LOGIN, AppRoutes.REGISTER].contains(Get.currentRoute)) {
        Get.offAllNamed(AppRoutes.LOGIN);
      }
    }
  }

  Future<void> loginWithFormValidation() async {
    if (loginFormKey.currentState?.validate() ?? false) await login();
  }

  Future<void> registerWithFormValidation() async {
    if (registerFormKey.currentState?.validate() ?? false) await register();
  }

  Future<void> login() async {
    if (loginEmailController.text.isEmpty || loginPasswordController.text.isEmpty) {
      _showError("Campos incompletos", "Por favor, completa todos los campos.", isLogin: true);
      return;
    }

    isLoginLoading.value = true;
    loginError.value = '';
    try {
      final user = await _authProvider.login(
        loginEmailController.text.trim(),
        loginPasswordController.text.trim(),
      );
      if (user == null && _authProvider.currentUser == null) {
        _showError("Error de Inicio de Sesión", "Credenciales incorrectas o error desconocido.", isLogin: true);
      }
    } on FirebaseAuthException catch (e) {
      _showError("Error de Inicio de Sesión", _mapFirebaseAuthExceptionMessage(e), isLogin: true);
    } catch (e) {
      _showError("Error Inesperado", e.toString(), isLogin: true);
    } finally {
      isLoginLoading.value = false;
    }
  }

  Future<void> register() async {
    if ([registerNameController, registerEmailController, registerPasswordController, registerConfirmPasswordController].any((c) => c.text.isEmpty)) {
      _showError("Campos incompletos", "Completa todos los campos de registro.", isLogin: false);
      return;
    }
    if (registerPasswordController.text != registerConfirmPasswordController.text) {
      _showError("Error de Contraseña", "Las contraseñas no coinciden.", isLogin: false);
      return;
    }

    isRegisterLoading.value = true;
    registerError.value = '';
    try {
      final user = await _authProvider.register(
        registerEmailController.text.trim(),
        registerPasswordController.text.trim(),
        UserData(uid: '', email: registerEmailController.text.trim(), name: registerNameController.text.trim()),
      );
      if (user != null) {
        Get.snackbar("Registro Exitoso", "Correo de verificación enviado a ${user.email}.", snackPosition: SnackPosition.BOTTOM);
        clearRegisterFields();
      } else {
        _showError("Error de Registro", "No se pudo completar el registro.", isLogin: false);
      }
    } on FirebaseAuthException catch (e) {
      _showError("Error de Registro", _mapFirebaseAuthExceptionMessage(e), isLogin: false);
    } catch (e) {
      _showError("Error", e.toString(), isLogin: false);
    } finally {
      isRegisterLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      final token = await _notificationProvider.getCurrentDeviceToken();
      if (token != null && isAuthenticated.value) {
        await _notificationProvider.removeCurrentDeviceToken(token);
      }
      await _authProvider.logout();
    } catch (e) {
      Get.snackbar("Error al cerrar sesión", e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> resetPassword(String email) async {
    if (email.isEmpty || !GetUtils.isEmail(email)) {
      _showError("Error", "Por favor, introduce un correo electrónico válido.", isLogin: true);
      return;
    }

    isLoginLoading.value = true;
    try {
      await _authProvider.resetPassword(email);
      Get.snackbar("Correo Enviado", "Revisa tu correo para restablecer tu contraseña.", snackPosition: SnackPosition.BOTTOM);
    } on FirebaseAuthException catch (e) {
      _showError("Error", _mapFirebaseAuthExceptionMessage(e), isLogin: true);
    } catch (e) {
      _showError("Error", e.toString(), isLogin: true);
    } finally {
      isLoginLoading.value = false;
    }
  }

  Future<void> updateUserName(String newName) async {
    if (newName.trim().isEmpty || currentUser.value == null) {
      _showError("Error", "Nombre vacío o usuario no autenticado.", isLogin: false);
      return;
    }
    await _authProvider.updateUserName(newName);
  }

  void _showError(String title, String message, {required bool isLogin}) {
    (isLogin ? loginError : registerError).value = message;
    Get.snackbar(title, message, snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
  }

  void _clearSession() {
    currentUser.value = null;
    isAuthenticated.value = false;
    loginError.value = '';
    registerError.value = '';
    clearLoginFields();
    clearRegisterFields();
    editNameController.clear();
  }

  void toggleLoginPasswordVisibility() => loginPasswordVisible.toggle();
  void toggleRegisterPasswordVisibility() => registerPasswordVisible.toggle();
  void toggleRegisterConfirmPasswordVisibility() => registerConfirmPasswordVisible.toggle();

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
      case 'user-not-found': return 'No se encontró un usuario con ese correo electrónico.';
      case 'wrong-password': return 'Contraseña incorrecta.';
      case 'email-already-in-use': return 'Este correo electrónico ya está en uso.';
      case 'weak-password': return 'La contraseña es demasiado débil.';
      case 'invalid-email': return 'El formato del correo electrónico no es válido.';
      case 'operation-not-allowed': return 'Operación no permitida.';
      case 'too-many-requests': return 'Demasiados intentos. Intenta más tarde.';
      default: return 'Error: ${e.message} (código: ${e.code})';
    }
  }
}