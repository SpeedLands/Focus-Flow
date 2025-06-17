import 'package:focus_flow/data/services/app_notification_db_service.dart';
import 'package:focus_flow/data/services/notification_service.dart';
import 'package:focus_flow/data/services/task_service.dart';
import 'package:focus_flow/modules/notifications/notifications_controller.dart';
import 'package:focus_flow/modules/tasks/tasks_controller.dart';
import 'package:get/get.dart';

class TaskBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TaskController>(() => TaskController());
    Get.lazyPut<TaskService>(() => TaskService());
    Get.lazyPut<NotificationService>(() => NotificationService.instance);
    Get.lazyPut<NotificationController>(() => NotificationController());
    Get.lazyPut<AppNotificationDbService>(() => AppNotificationDbService());
  }
}
