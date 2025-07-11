import 'package:flutter/material.dart';
import 'package:focus_flow/modules/projects/project_controller.dart';
import 'package:focus_flow/modules/projects/widgets/empty_state.dart';
import 'package:focus_flow/modules/projects/widgets/error_state.dart';
import 'package:focus_flow/modules/projects/widgets/pending_deletion_requests.dart';
import 'package:focus_flow/modules/projects/widgets/pending_invitations.dart';
import 'package:focus_flow/modules/projects/widgets/project_card_mobile.dart';
import 'package:focus_flow/routes/app_routes.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';

class MobileProjectsView extends StatelessWidget {
  final ProjectController controller;

  const MobileProjectsView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GFAppBar(
        backgroundColor: GFColors.PRIMARY,
        title: const GFTypography(
          text: 'Mis Proyectos',
          type: GFTypographyType.typo1,
          textColor: GFColors.WHITE,
          showDivider: false,
        ),
        leading: GFIconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Get.offAllNamed<Object>(AppRoutes.HOME),
        ),
        actions: [
          GFIconButton(
            icon: const Icon(Icons.group_add_outlined),
            tooltip: 'Unirse con Código',
            onPressed: () => controller.showJoinWithCodeDialog(context),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingProjects.value &&
            controller.projects.isEmpty &&
            controller.isLoadingDeletionRequests.value &&
            controller.pendingProjectDeletionRequests.isEmpty &&
            controller.isLoadingInvitations.value &&
            controller.projectInvitations.isEmpty) {
          return const Center(child: GFLoader(type: GFLoaderType.circle));
        }
        if (controller.projectListError.value.isNotEmpty &&
            controller.projects.isEmpty) {
          return ErrorState(isTV: false, controller: controller);
        }
        return Column(
          children: [
            PendingDeletionRequests(controller: controller),
            PendingInvitations(controller),
            Expanded(
              child:
                  controller.projects.isEmpty &&
                      !controller.isLoadingProjects.value
                  ? EmptyState(isTV: false, controller: controller)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 80.0),
                      itemCount: controller.projects.length,
                      itemBuilder: (ctx, index) {
                        final project = controller.projects[index];
                        return ProjectCardMobile(
                          project: project,
                          controller: controller,
                        );
                      },
                    ),
            ),
          ],
        );
      }),
      floatingActionButton: GFIconButton(
        onPressed: controller.navigateToAddProject,
        icon: const Icon(Icons.add),
        tooltip: 'Nuevo Proyecto',
        shape: GFIconButtonShape.pills,
      ),
    );
  }
}
