import 'package:get/get.dart';
import 'package:focus_flow/modules/auth/auth_controller.dart';
import 'package:focus_flow/data/providers/auth_provider.dart';
import 'package:focus_flow/data/services/auth_service.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthService>(() => AuthService(), fenix: true);

    Get.lazyPut<AuthProvider>(
      () => AuthProvider(Get.find<AuthService>()),
      fenix: true,
    );

    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
  }
}
