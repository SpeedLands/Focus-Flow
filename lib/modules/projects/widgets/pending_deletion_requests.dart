import 'package:flutter/material.dart';
import 'package:focus_flow/modules/projects/project_controller.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';

class PendingDeletionRequests extends StatelessWidget {
  final ProjectController controller;
  const PendingDeletionRequests({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingDeletionRequests.value &&
          controller.pendingProjectDeletionRequests.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(8.0),
          child: Center(
            child: GFLoader(type: GFLoaderType.square, size: GFSize.LARGE),
          ),
        );
      }

      if (controller.pendingProjectDeletionRequests.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.all(8.0),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: GFColors.DANGER,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
              child: Text(
                "Solicitudes de Eliminación Pendientes",
                style: TextStyle(
                  color: GFColors.DARK,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.pendingProjectDeletionRequests.length,
              itemBuilder: (context, index) {
                final request =
                    controller.pendingProjectDeletionRequests[index];
                final requestData = request.data ?? {};
                final projectName =
                    requestData['projectName'] as String? ??
                    'Proyecto desconocido';
                final requesterName =
                    requestData['requesterName'] as String? ??
                    'Usuario Desconodido';

                return GFCard(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  title: GFListTile(
                    icon: Icon(
                      Icons.warning_amber_rounded,
                      color: GFColors.DANGER,
                    ),
                    title: Text(
                      "Eliminar: '$projectName'",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subTitle: Text(
                      "Solicitado por: $requesterName\nEmail: ${requestData['requesterEmail'] ?? 'N/A'}",
                    ),
                    firstButtonTitle: 'Aprobar Eliminacion',
                    firstButtonTextStyle: TextStyle(),
                    secondButtonTitle: 'Rechazar Eliminacion',
                    secondButtonTextStyle: TextStyle(),
                    onFirstButtonTap: () =>
                        controller.approveProjectDeletionRequest(request),
                    onSecondButtonTap: () =>
                        controller.rejectProjectDeletionRequest(request),
                  ),
                );
              },
            ),
          ],
        ),
      );
    });
  }
}
