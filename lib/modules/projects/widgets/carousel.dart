import 'package:flutter/material.dart';
import 'package:focus_flow/modules/projects/project_controller.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';

class Carousel extends StatelessWidget {
  final ProjectController controller;

  const Carousel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1a2436),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 20),
        itemCount: controller.projects.length,
        itemBuilder: (ctx, index) {
          final project = controller.projects[index];
          return Obx(() {
            final isSelected =
                controller.selectedProjectForTv.value?.id == project.id;
            return Material(
              color: isSelected
                  ? project.projectColor.withValues(alpha: 0.3)
                  : Colors.transparent,
              child: InkWell(
                onTap: () => controller.selectProjectForTv(project),
                focusColor: project.projectColor.withValues(alpha: 0.4),
                hoverColor: project.projectColor.withValues(alpha: 0.2),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: isSelected
                            ? project.projectColor
                            : Colors.transparent,
                        width: 4,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      GFAvatar(
                        backgroundColor: project.projectColor.withValues(
                          alpha: 0.5,
                        ),
                        child: Icon(
                          controller.getIconDataByName(project.iconName),
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          project.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }
}
