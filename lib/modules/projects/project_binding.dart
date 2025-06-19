import 'package:focus_flow/data/providers/project_invitation_provider.dart';
import 'package:focus_flow/data/providers/project_provider.dart';
import 'package:focus_flow/data/providers/task_provider.dart';
import 'package:get/get.dart';
import 'package:focus_flow/modules/projects/project_controller.dart';

class ProjectBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProjectController>(() => ProjectController());
    Get.lazyPut<ProjectProvider>(() => ProjectProvider(Get.find(), Get.find()));
    Get.lazyPut<ProjectInvitationProvider>(
      () => ProjectInvitationProvider(Get.find(), Get.find(), Get.find()),
    );
    Get.lazyPut<TaskProvider>(() => TaskProvider(Get.find(), Get.find()));
  }
}
