import 'package:focus_flow/data/providers/notification_provider.dart';
import 'package:focus_flow/modules/notifications/notifications_controller.dart';
import 'package:get/get.dart';

class NotificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotificationController>(() {
      return NotificationController();
    });
    Get.lazyPut<NotificationProvider>(
      () => NotificationProvider(Get.find(), Get.find(), Get.find()),
    );
  }
}
