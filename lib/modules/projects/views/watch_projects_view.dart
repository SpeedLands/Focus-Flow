import 'package:flutter/material.dart';
import 'package:focus_flow/modules/projects/project_controller.dart';
import 'package:focus_flow/routes/app_routes.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';

class WatchProjectsView extends StatelessWidget {
  final ProjectController controller;

  const WatchProjectsView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      size: 18,
                      color: Colors.white,
                    ),
                    onPressed: () => Get.back(),
                  ),
                  const Text(
                    "Proyectos",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Expanded(
                child: Obx(() {
                  if (controller.isLoadingProjects.value &&
                      controller.projects.isEmpty) {
                    return const Center(
                      child: GFLoader(
                        type: GFLoaderType.circle,
                        size: GFSize.SMALL,
                      ),
                    );
                  }
                  if (controller.projectListError.value.isNotEmpty &&
                      controller.projects.isEmpty) {
                    return Center(
                      child: Text(
                        controller.projectListError.value,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  if (controller.projects.isEmpty) {
                    return const Center(
                      child: Text(
                        "No hay proyectos.",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: controller.projects.length,
                    itemBuilder: (context, index) {
                      final project = controller.projects[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        tileColor: Colors.grey[850],
                        leading: CircleAvatar(
                          backgroundColor: project.projectColor.withAlpha(70),
                          child: Icon(
                            controller.getIconDataByName(project.iconName),
                            color: project.projectColor,
                            size: 16,
                          ),
                        ),
                        title: Text(
                          project.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        onTap: () {
                          Get.toNamed(
                            AppRoutes.TASKS_LIST,
                            arguments: {
                              'projectId': project.id,
                              'projectName': project.name,
                            },
                          );
                        },
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
