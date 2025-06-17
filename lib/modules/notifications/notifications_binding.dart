import 'package:focus_flow/data/services/app_notification_db_service.dart';
import 'package:focus_flow/modules/notifications/notifications_controller.dart';
import 'package:get/get.dart';

class NotificationBinding extends Bindings {
  @override
  void dependencies() {
    print("[GETX_BINDING] NotificationBinding - dependencies() CALLED");
    Get.lazyPut<AppNotificationDbService>(
      () => AppNotificationDbService(),
    ); // Si usas este servicio
    Get.lazyPut<NotificationController>(() {
      print(
        "[GETX_BINDING] NotificationBinding - CREATING NotificationController",
      ); // DEBUG
      return NotificationController();
    });
  }
}
