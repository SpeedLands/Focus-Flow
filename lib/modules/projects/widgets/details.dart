import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:focus_flow/data/models/project_model.dart';
import 'package:focus_flow/modules/projects/project_controller.dart';
import 'package:focus_flow/modules/projects/widgets/detail_view_switcher.dart';
import 'package:focus_flow/routes/app_routes.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';

class Details extends StatelessWidget {
  final ProjectController controller;

  const Details({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final project = controller.selectedProjectForTv.value;
      if (project == null || controller.isLoadingTvDetails.value) {
        return const Center(child: GFLoader(type: GFLoaderType.circle));
      }

      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            DetailViewSwitcher(
              initialIndex: controller.selectedTvDetailViewIndex.value,
              onTap: controller.changeTvDetailView,
              activeColor: controller.selectedProjectForTv.value!.projectColor,
            ),
            const SizedBox(height: 24),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildCurrentDetailView(context),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCurrentDetailView(BuildContext context) {
    final index = controller.selectedTvDetailViewIndex.value;
    switch (index) {
      case 0:
        return _buildTaskStatusBarChartTv(context);
      case 1:
        return _buildRecentActivityFeedTv(context, controller);
      case 2:
        return _buildMemberStatusTv(context);
      case 3:
        return _buildAccessCodeViewTv(context);
      default:
        return const Center(
          child: Text(
            "Vista no disponible",
            style: TextStyle(color: Colors.white),
          ),
        );
    }
  }

  Widget _buildTaskStatusBarChartTv(BuildContext context) {
    return Obx(() {
      if (controller.projectTaskStats.isEmpty) {
        return const Center(child: GFLoader(type: GFLoaderType.ios));
      }
      return BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY:
              (controller.projectTaskStats
                      .map((e) => e['pendingTasks'] as int)
                      .reduce((a, b) => a > b ? a : b)
                      .toDouble() *
                  1.2) +
              1,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final stat = controller.projectTaskStats[value.toInt()];
                  final project = stat['project'] as ProjectModel;
                  return SideTitleWidget(
                    meta: meta,
                    space: 8.0,
                    child: Text(
                      project.name,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
                reservedSize: 40,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(controller.projectTaskStats.length, (index) {
            final stat = controller.projectTaskStats[index];
            final project = stat['project'] as ProjectModel;
            final pendingTasks = (stat['pendingTasks'] as int).toDouble();
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: pendingTasks,
                  color: project.projectColor,
                  width: 22,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            );
          }),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
        ),
        duration: const Duration(milliseconds: 300),
      );
    });
  }

  Widget _buildRecentActivityFeedTv(
    BuildContext context,
    ProjectController controller,
  ) {
    final project = controller.selectedProjectForTv.value;
    return Obx(() {
      if (controller.recentActivity.isEmpty) {
        return Center(
          child: Column(
            children: [
              Text(
                "No hay actividad reciente en este proyecto",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              GFButton(
                hoverColor: GFColors.INFO,
                size: GFSize.LARGE,
                shape: GFButtonShape.pills,
                text: 'Ver todas las Tareas',
                onPressed: () {
                  controller.setCurrentProjectRole(project!);
                  Get.toNamed(
                    AppRoutes.TASKS_LIST,
                    arguments: {
                      'projectId': project.id,
                      'projectName': project.name,
                    },
                  );
                },
              ),
            ],
          ),
        );
      }
      return Column(
        children: [
          GFButton(
            hoverColor: GFColors.INFO,
            size: GFSize.LARGE,
            shape: GFButtonShape.pills,
            text: 'Ver todas las Tareas',
            onPressed: () {
              controller.setCurrentProjectRole(project!);
              Get.toNamed(
                AppRoutes.TASKS_LIST,
                arguments: {
                  'projectId': project.id,
                  'projectName': project.name,
                },
              );
            },
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: controller.recentActivity.length,
              itemBuilder: (ctx, index) {
                final activity = controller.recentActivity[index];
                return GFListTile(
                  color: Colors.white.withValues(alpha: 0.05),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  title: Text(
                    activity['text'],
                    style: const TextStyle(color: Colors.white),
                  ),
                  subTitle: Text(
                    "Por: ${activity['user']} - ${activity['time'].toDate()}",
                    style: const TextStyle(color: Colors.white60),
                  ),
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: GFColors.SUCCESS,
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildMemberStatusTv(BuildContext context) {
    final project = controller.selectedProjectForTv.value!;
    final members = project.userRoles
        .map((role) => role.split(':').first)
        .toSet()
        .toList();

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        childAspectRatio: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: members.length,
      itemBuilder: (ctx, index) {
        final userId = members[index];
        final bool isAdmin = project.adminUserId == userId;
        return GFCard(
          color: Colors.white.withValues(alpha: 0.1),
          content: ListTile(
            leading: GFAvatar(
              child: Text(userId.substring(0, 2).toUpperCase()),
            ),
            title: Text(
              isAdmin ? "Admin" : "Miembro",
              style: TextStyle(
                color: isAdmin ? GFColors.PRIMARY : Colors.white,
              ),
            ),
            subtitle: Text(
              userId,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccessCodeViewTv(BuildContext context) {
    final project = controller.selectedProjectForTv.value!;
    final bool isAdmin = controller.isCurrentUserAdmin(project);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Código de Acceso al Proyecto",
            style: TextStyle(color: Colors.white70, fontSize: 24),
          ),
          const SizedBox(height: 20),
          if (isAdmin)
            Obx(
              () => SelectableText(
                controller.generatedAccessCode.value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 80,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
              ),
            ),
          if (!isAdmin)
            const Text(
              "Solo los administradores pueden ver y generar el código.",
              style: TextStyle(color: GFColors.WARNING, fontSize: 18),
            ),
          const SizedBox(height: 30),
          if (isAdmin)
            GFButton(
              onPressed: () =>
                  controller.performGenerateAccessCode(project.id!),
              text: "Generar / Ver Código",
              icon: const Icon(Icons.refresh, color: Colors.white),
              size: GFSize.LARGE,
              type: GFButtonType.outline2x,
              color: Colors.white,
              hoverColor: project.projectColor.withValues(alpha: 0.3),
              focusColor: project.projectColor,
            ),
        ],
      ),
    );
  }
}
