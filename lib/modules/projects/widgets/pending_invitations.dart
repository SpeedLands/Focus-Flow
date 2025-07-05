import 'package:flutter/material.dart';
import 'package:focus_flow/modules/projects/project_controller.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';

class PendingInvitations extends StatelessWidget {
  final ProjectController controller;
  const PendingInvitations(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingInvitations.value &&
          controller.projectInvitations.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: GFLoader(type: GFLoaderType.square, size: GFSize.LARGE),
          ),
        );
      }
      if (controller.projectInvitations.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.all(8.0),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: GFColors.SECONDARY,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
              child: Text(
                "Invitaciones Pendientes",
                style: TextStyle(
                  color: GFColors.DARK,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.projectInvitations.length,
              itemBuilder: (context, index) {
                final invitation = controller.projectInvitations[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: GFListTile(
                    icon: Icon(Icons.mail_outline, color: GFColors.INFO),
                    title: Text("Invitación a: ${invitation.projectName}"),
                    subTitle: Text("De: ${invitation.invitedByUserId}"),
                    firstButtonTitle: 'Aceptar',
                    onFirstButtonTap: () =>
                        controller.performAcceptInvitation(invitation.id!),
                    secondButtonTitle: 'Rechazar',
                    onSecondButtonTap: () =>
                        controller.performDeclineInvitation(invitation.id!),
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
