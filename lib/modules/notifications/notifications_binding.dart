import 'package:focus_flow/data/services/app_notification_db_service.dart';
import 'package:focus_flow/modules/notifications/notifications_controller.dart';
import 'package:get/get.dart';

class NotificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AppNotificationDbService>(() => AppNotificationDbService());
    Get.lazyPut<NotificationController>(() {
      return NotificationController();
    });
  }
}
