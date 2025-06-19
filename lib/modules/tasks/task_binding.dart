import 'package:focus_flow/modules/notifications/notifications_controller.dart';
import 'package:focus_flow/modules/tasks/tasks_controller.dart';
import 'package:get/get.dart';

class TaskBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TaskController>(() => TaskController());
    Get.lazyPut<NotificationController>(() => NotificationController());
  }
}
