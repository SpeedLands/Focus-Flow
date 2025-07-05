import 'package:flutter/material.dart';
import 'package:focus_flow/modules/projects/project_controller.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';

class EmptyState extends StatelessWidget {
  final ProjectController controller;
  final bool isTV;

  const EmptyState({super.key, required this.isTV, required this.controller});

  @override
  Widget build(BuildContext context) {
    final textColor = isTV ? Colors.white70 : Colors.grey[700];
    final titleColor = isTV ? Colors.white : Get.textTheme.headlineSmall?.color;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_off_outlined,
              color: isTV ? Colors.white54 : Colors.grey,
              size: isTV ? 80 : 60,
            ),
            const SizedBox(height: 20),
            Text(
              "No Hay Proyectos",
              style: Get.textTheme.headlineSmall?.copyWith(color: titleColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "Crea tu primer proyecto para empezar a organizar tus tareas.",
              style: Get.textTheme.bodyLarge?.copyWith(color: textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            GFButton(
              onPressed: controller.navigateToAddProject,
              text: "Crear Nuevo Proyecto",
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              type: isTV ? GFButtonType.outline2x : GFButtonType.solid,
              textColor: isTV ? Colors.white : null,
              color: isTV ? Colors.white : GFColors.PRIMARY,
              buttonBoxShadow: isTV,
              size: isTV ? GFSize.LARGE : GFSize.MEDIUM,
            ),
          ],
        ),
      ),
    );
  }
}
