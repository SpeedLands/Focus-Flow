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

  final registerFormKey = GlobalKey<FormState>();
  final loginFormKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    _listenToAuthStateChanges();
  }

  void _listenToAuthStateChanges() {
    _authStateSubscription?.cancel();
    _authStateSubscription = _authProvider.authStateChanges.listen(
      _handleAuthState,
    );
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
          if (authRoutes.contains(Get.currentRoute) ||
              Get.currentRoute.isEmpty) {
            await Get.offAllNamed<Object>(AppRoutes.HOME);
          }
        } else {
          debugPrint('Usuario autenticado sin datos en Firestore.');
          await logout();
        }
      } catch (e) {
        debugPrint('Error al obtener datos de usuario: $e');
        await logout();
      }
    } else {
      _clearSession();
      if (![AppRoutes.LOGIN, AppRoutes.REGISTER].contains(Get.currentRoute)) {
        await Get.offAllNamed<Object>(AppRoutes.LOGIN);
      }
    }
  }

  Future<void> loginWithFormValidation() async {
    if (loginFormKey.currentState?.validate() ?? false) {
      await login();
    }
  }

  Future<void> registerWithFormValidation() async {
    if (registerFormKey.currentState?.validate() ?? false) {
      await register();
    } else {}
  }

  Future<void> updateUserDeviceToken(String userId) async {
    await _notificationProvider.saveCurrentDeviceToken(userId);
  }

  Future<void> removeUserDeviceToken(String deviceTokenToRemove) async {
    await _notificationProvider.removeCurrentDeviceToken(deviceTokenToRemove);
  }

  Future<void> login() async {
    if (loginEmailController.text.isEmpty ||
        loginPasswordController.text.isEmpty) {
      loginError.value = 'Por favor, completa todos los campos.';
      _showError(
        'Campos incompletos',
        'Por favor, completa todos los campos.',
        isLogin: true,
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
        loginError.value = 'Credenciales incorrectas o error desconocido.';
        _showError(
          'Error de Inicio de Sesión',
          'Credenciales incorrectas o error desconocido.',
          isLogin: true,
        );
      }
    } on FirebaseAuthException catch (e) {
      loginError.value = _mapFirebaseAuthExceptionMessage(e);
      _showError(
        'Error de Inicio de Sesión',
        _mapFirebaseAuthExceptionMessage(e),
        isLogin: true,
      );
    } catch (e) {
      loginError.value = 'Ocurrió un error inesperado: ${e.toString()}';
      _showError('Error Inesperado', e.toString(), isLogin: true);
    } finally {
      isLoginLoading.value = false;
    }
  }

  Future<void> register() async {
    if ([
      registerNameController,
      registerEmailController,
      registerPasswordController,
      registerConfirmPasswordController,
    ].any((c) => c.text.isEmpty)) {
      _showError(
        'Campos incompletos',
        'Completa todos los campos de registro.',
        isLogin: false,
      );
      return;
    }
    if (registerPasswordController.text !=
        registerConfirmPasswordController.text) {
      _showError(
        'Error de Contraseña',
        'Las contraseñas no coinciden.',
        isLogin: false,
      );
      return;
    }
    isRegisterLoading.value = true;
    registerError.value = '';
    final UserData newUserModel = UserData(
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
          'Registro Exitoso',
          'Se ha enviado un correo de verificación a ${user.email}. Por favor, verifica tu cuenta.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
        clearRegisterFields();
      } else {
        registerError.value = 'Error desconocido durante el registro.';
        _showError(
          'Error de Registro',
          'No se pudo completar el registro.',
          isLogin: false,
        );
      }
    } on FirebaseAuthException catch (e) {
      registerError.value = _mapFirebaseAuthExceptionMessage(e);
      _showError(
        'Error de Registro',
        _mapFirebaseAuthExceptionMessage(e),
        isLogin: false,
      );
    } catch (e) {
      registerError.value = 'Ocurrió un error inesperado: ${e.toString()}';
      _showError('Error', e.toString(), isLogin: false);
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
        'Error al cerrar sesión',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> resetPassword(String email) async {
    if (email.isEmpty || !GetUtils.isEmail(email)) {
      _showError(
        'Error',
        'Por favor, introduce un correo electrónico válido.',
        isLogin: true,
      );
      return;
    }
    isLoginLoading.value = true;
    try {
      await _authProvider.resetPassword(email);
      Get.snackbar(
        'Correo Enviado',
        'Si el correo está registrado, recibirás un enlace para restablecer tu contraseña.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on FirebaseAuthException catch (e) {
      _showError('Error', _mapFirebaseAuthExceptionMessage(e), isLogin: true);
    } catch (e) {
      _showError('Error', e.toString(), isLogin: true);
    } finally {
      isLoginLoading.value = false;
    }
  }

  Future<void> updateUserName(String newName) async {
    if (newName.trim().isEmpty || currentUser.value == null) {
      _showError(
        'Error',
        'Nombre vacío o usuario no autenticado.',
        isLogin: false,
      );
      return;
    }
    await _authProvider.updateUserName(newName);
  }

  void _showError(String title, String message, {required bool isLogin}) {
    (isLogin ? loginError : registerError).value = message;
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
    );
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
  void toggleRegisterConfirmPasswordVisibility() =>
      registerConfirmPasswordVisible.toggle();

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
        return 'Operación no permitida.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';
      default:
        return 'Error: ${e.message} (código: ${e.code})';
    }
  }
}
