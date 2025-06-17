// lib/app/modules/auth/auth_binding.dart
import 'package:get/get.dart';
import 'package:focus_flow/modules/auth/auth_controller.dart';
import 'package:focus_flow/data/providers/auth_provider.dart';
import 'package:focus_flow/data/services/auth_service.dart'; // Necesario para instanciar AuthService

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Registrar AuthService primero si AuthProvider depende de él
    Get.lazyPut<AuthService>(() => AuthService(), fenix: true);

    // Registrar AuthProvider, que depende de AuthService
    Get.lazyPut<AuthProvider>(
      () => AuthProvider(Get.find<AuthService>()),
      fenix: true,
    );

    // Registrar AuthController, que depende de AuthProvider
    // Usamos fenix: true para que el controlador se recree si es necesario
    // al navegar hacia atrás y luego adelante a esta pantalla,
    // o si es removido de la memoria por GetX.
    // Para auth, generalmente queremos que persista mientras la app esté activa
    // hasta que el usuario se desloguee. Get.put() o Get.lazyPut() sin fenix
    // podrían ser suficientes si la gestión de su ciclo de vida está
    // bien controlada por el listener de authStateChanges.
    // Por ahora, lazyPut sin fenix debería ser suficiente.
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
  }
}
