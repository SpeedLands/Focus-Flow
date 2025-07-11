import 'package:flutter/material.dart';
import 'package:focus_flow/modules/projects/project_controller.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';

class ErrorState extends StatelessWidget {
  final bool isTV;
  final ProjectController controller;
  const ErrorState({super.key, required this.isTV, required this.controller});

  @override
  Widget build(BuildContext context) {
    final textColor = isTV ? Colors.white70 : Get.textTheme.bodyLarge?.color;
    final titleColor = isTV ? Colors.white : Get.textTheme.headlineSmall?.color;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: isTV ? 80 : 50,
            ),
            const SizedBox(height: 15),
            Text(
              'Error al Cargar',
              style: Get.textTheme.headlineSmall?.copyWith(color: titleColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              controller.projectListError.value,
              style: Get.textTheme.bodyLarge?.copyWith(color: textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            GFButton(
              onPressed: controller.reloadProjects,
              text: 'Reintentar',
              icon: const Icon(Icons.refresh, color: Colors.white),
              type: isTV ? GFButtonType.outline2x : GFButtonType.solid,
              textColor: isTV ? Colors.white : null,
              color: isTV ? Colors.white : GFColors.PRIMARY,
              buttonBoxShadow: isTV,
            ),
          ],
        ),
      ),
    );
  }
}
