// lib/app/modules/projects/project_binding.dart
import 'package:focus_flow/data/services/notification_service.dart';
import 'package:focus_flow/data/services/task_service.dart';
import 'package:get/get.dart';
import 'package:focus_flow/data/services/project_service.dart';
import 'package:focus_flow/modules/projects/project_controller.dart';

class ProjectBinding extends Bindings {
  @override
  void dependencies() {
    // ProjectService maneja la lógica de datos con Firestore
    Get.lazyPut<ProjectService>(() => ProjectService());

    // ProjectController maneja el estado y la lógica de UI para proyectos
    Get.lazyPut<ProjectController>(() => ProjectController());

    Get.lazyPut<TaskService>(() => TaskService());

    Get.lazyPut<NotificationService>(() => NotificationService.instance);
  }
}
