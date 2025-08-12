import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:focus_flow/data/models/project_model.dart';
import 'package:focus_flow/modules/projects/project_controller.dart';
import 'package:focus_flow/modules/projects/widgets/code_view.dart';
import 'package:focus_flow/modules/projects/widgets/detail_view_switcher.dart';
import 'package:focus_flow/modules/projects/widgets/members_card.dart';
import 'package:focus_flow/modules/projects/widgets/recent_activity.dart';
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
        return RecentActivityFeedTv(
          controller: controller,
        ); //_buildRecentActivityFeedTv(context, controller);
      case 2:
        return MemberStatusGridTv(controller: controller);
      case 3:
        return AccessCodeViewTv(controller: controller);
      default:
        return const Center(
          child: Text(
            'Vista no disponible',
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

      final double maxYValue =
          (controller.projectTaskStats
                  .map((e) => e['totalTasks'] as int)
                  .reduce((a, b) => a > b ? a : b)
                  .toDouble() *
              1.2) +
          1;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Resumen de Tareas por Proyecto',
              style: Get.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxYValue,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) =>
                          Colors.blueGrey.withValues(alpha: 0.8),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final stat =
                            controller.projectTaskStats[group.x.toInt()];
                        final project = stat['project'] as ProjectModel;
                        final totalTasks = stat['totalTasks'] as int;
                        final pendingTasks = stat['pendingTasks'] as int;
                        final completedTasks = totalTasks - pendingTasks;

                        return BarTooltipItem(
                          '${project.name}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'Total: $totalTasks\n',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            TextSpan(
                              text: 'Pendientes: $pendingTasks\n',
                              style: TextStyle(
                                color: project.projectColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            TextSpan(
                              text: 'Completadas: $completedTasks',
                              style: TextStyle(
                                color: project.projectColor.withValues(
                                  alpha: 0.5,
                                ),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
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
                          final stat =
                              controller.projectTaskStats[value.toInt()];
                          final project = stat['project'] as ProjectModel;
                          // --- CAMBIO CLAVE AQUÍ ---
                          return SideTitleWidget(
                            meta: meta, // Se usa axisSide en lugar de meta
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
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          if (value == 0 || value == meta.max) {
                            return const SizedBox.shrink();
                          }
                          if (value % (maxYValue / 5).ceil() != 0 &&
                              value != meta.max) {
                            return const SizedBox.shrink();
                          }

                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  barGroups: List.generate(controller.projectTaskStats.length, (
                    index,
                  ) {
                    final stat = controller.projectTaskStats[index];
                    final project = stat['project'] as ProjectModel;
                    final totalTasks = (stat['totalTasks'] as int).toDouble();
                    final pendingTasks = (stat['pendingTasks'] as int)
                        .toDouble();
                    final completedTasks = totalTasks - pendingTasks;

                    // Aseguramos que el color de completado sea visible y diferente
                    final pendingColor = project.projectColor;
                    final completedColor = project.projectColor.withValues(
                      alpha: 0.4,
                    );

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: totalTasks,
                          width: 25,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(6),
                          ),
                          color: Colors.transparent,
                          // gradient: LinearGradient(
                          //   colors: [completedColor, pendingColor],
                          // ),
                          rodStackItems: [
                            // Tareas Completadas (base de la barra)
                            BarChartRodStackItem(
                              0,
                              completedTasks,
                              completedColor,
                            ),
                            // Tareas Pendientes (encima de las completadas)
                            BarChartRodStackItem(
                              completedTasks,
                              totalTasks,
                              pendingColor,
                            ),
                          ],
                        ),
                      ],
                    );
                  }),
                ),
                duration: const Duration(milliseconds: 400),
              ),
            ),
            const SizedBox(height: 20),
            _buildLegend(),
          ],
        ),
      );
    });
  }

  // He invertido el orden en la leyenda para que coincida con la barra (Pendientes arriba)
  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(
          controller.selectedProjectForTv.value!.projectColor,
          'Tareas Pendientes',
        ), // Color genérico para la leyenda
        const SizedBox(width: 20),
        _buildLegendItem(
          controller.selectedProjectForTv.value!.projectColor.withValues(
            alpha: 0.4,
          ),
          'Tareas Completadas',
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }
}
