import 'package:focus_flow/data/providers/notification_provider.dart';
import 'package:focus_flow/data/services/firestore_service.dart';
import 'package:focus_flow/data/services/http_service.dart';
import 'package:focus_flow/data/services/messaging_service.dart';
import 'package:get/get.dart';
import 'package:focus_flow/modules/auth/auth_controller.dart';
import 'package:focus_flow/data/providers/auth_app_provider.dart';
import 'package:focus_flow/data/services/auth_service.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthService>(() => AuthService(), fenix: true);
    Get.lazyPut<FirestoreService>(() => FirestoreService(), fenix: true);
    Get.lazyPut<NotificationProvider>(
      () => NotificationProvider(Get.find(), Get.find(), Get.find()),
      fenix: true,
    );
    Get.lazyPut<HttpService>(() => HttpService(), fenix: true);
    Get.lazyPut<MessagingService>(() => MessagingService(), fenix: true);

    Get.lazyPut<AuthProviderApp>(
      () => AuthProviderApp(
        Get.find<AuthService>(),
        Get.find<FirestoreService>(),
        Get.find<NotificationProvider>(),
      ),
      fenix: true,
    );

    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
  }
}
