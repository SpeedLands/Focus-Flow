import 'package:flutter/material.dart';
import 'package:focus_flow/modules/projects/project_controller.dart';
import 'package:focus_flow/modules/projects/widgets/carousel.dart';
import 'package:focus_flow/modules/projects/widgets/details.dart';
import 'package:focus_flow/modules/projects/widgets/empty_state.dart';
import 'package:focus_flow/modules/projects/widgets/error_state.dart';
import 'package:focus_flow/routes/app_routes.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';

class TvProjectsView extends StatelessWidget {
  final ProjectController controller;

  const TvProjectsView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101827),
      appBar: GFAppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF1a2436),
        title: const GFTypography(
          text: 'Panel de Proyectos',
          type: GFTypographyType.typo3,
          textColor: GFColors.WHITE,
          showDivider: false,
        ),
        leading: GFIconButton(
          icon: const Icon(Icons.arrow_back_ios, color: GFColors.WHITE),
          onPressed: () {
            Get.toNamed<Object>(AppRoutes.HOME);
          },
          color: const Color(0xFF1a2436),
          hoverColor: GFColors.FOCUS,
        ),
        actions: [
          GFIconButton(
            icon: const Icon(Icons.group_add_outlined, color: Colors.white),
            tooltip: 'Unirse con Código',
            onPressed: () => controller.showJoinWithCodeDialog(context),
            hoverColor: GFColors.FOCUS,
            focusColor: GFColors.SUCCESS,
            color: const Color(0xFF1a2436),
          ),
          GFIconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refrescar Datos',
            onPressed: () => controller.reloadProjects(),
            hoverColor: GFColors.FOCUS,
            focusColor: GFColors.SUCCESS,
            color: const Color(0xFF1a2436),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingProjects.value && controller.projects.isEmpty) {
          return const Center(child: GFLoader(type: GFLoaderType.circle));
        }
        if (controller.projectListError.value.isNotEmpty &&
            controller.projects.isEmpty) {
          return ErrorState(isTV: true, controller: controller);
        }
        if (controller.projects.isEmpty) {
          return EmptyState(isTV: true, controller: controller);
        }

        return Row(
          children: [
            Expanded(flex: 1, child: Carousel(controller: controller)),
            Expanded(flex: 2, child: Details(controller: controller)),
          ],
        );
      }),
    );
  }
}
