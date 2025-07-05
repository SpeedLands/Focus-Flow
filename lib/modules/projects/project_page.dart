import 'package:flutter/material.dart';
import 'package:focus_flow/modules/projects/views/mobile_projects_view.dart';
import 'package:focus_flow/modules/projects/views/tv_projects_view.dart';
import 'package:focus_flow/modules/projects/views/watch_projects_view.dart';
import 'package:get/get.dart';
import 'package:focus_flow/modules/projects/project_controller.dart';

class ProjectsScreen extends GetView<ProjectController> {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = Get.width;
    final isTV = screenWidth > 800 && Get.height > 500;
    final isWatch = screenWidth < 300;

    if (isWatch) {
      return WatchProjectsView(controller: controller);
    } else if (isTV) {
      return TvProjectsView(controller: controller);
    } else {
      return MobileProjectsView(controller: controller);
    }
  }
}
