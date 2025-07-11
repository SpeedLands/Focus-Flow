import 'package:flutter/material.dart';
import 'package:focus_flow/modules/pomodoro/pomodoro_ana/pomodoro_controller.dart';
import 'package:focus_flow/modules/pomodoro/pomodoro_ana/pomodoro_tv_dashboard.dart'; // IMPORTANTE
import 'package:get/get.dart';

class PomodoroTimerScreen extends GetView<PomodoroControllerAna> {
  const PomodoroTimerScreen({super.key});

  Widget _buildWatchPomodoroScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Obx(() {
          final config = controller.selectedConfig.value;
          if (config == null && controller.configs.isNotEmpty) {
            controller.selectConfigForTimer(controller.configs.first);
          } else if (config == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Get.back<Object>();
              Get.snackbar(
                'Error',
                'No hay configuraciones Pomodoro disponibles.',
              );
            });
            return const Text('Sin configuración.');
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                controller.formattedTime,
                style: const TextStyle(
                  fontSize: 36,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Ronda ${controller.currentRound.value} de ${controller.selectedConfig.value?.rounds ?? 0}',
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                controller.currentTimerStateLabel,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (controller.canStart || controller.canResume)
                    IconButton(
                      icon: Icon(
                        controller.timerState.value == PomodoroTimerState.paused
                            ? Icons.play_arrow
                            : Icons.play_circle_fill,
                        color: Colors.greenAccent,
                      ),
                      onPressed: controller.startPauseTimer,
                    ),
                  if (controller.canPause)
                    IconButton(
                      icon: const Icon(Icons.pause, color: Colors.orange),
                      onPressed: controller.startPauseTimer,
                    ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTvPomodoroScreen(BuildContext context) {
    return Obx(() {
      final stats = controller.sessionStats;

      if (stats.isEmpty) {
        return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Text(
              'No hay datos para mostrar gráficas.',
              style: TextStyle(fontSize: 24, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }

      return PomodoroTvDashboard(stats: stats);
    });
  }

  Widget _buildMobilePomodoroScreen(BuildContext context) {
    if (controller.selectedConfig.value == null &&
        controller.configs.isNotEmpty) {
      controller.selectConfigForTimer(controller.configs.first);
    } else if (controller.selectedConfig.value == null &&
        controller.configs.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.back<Object>();
        Get.snackbar('Error', 'No hay configuraciones Pomodoro disponibles.');
      });
      return const Scaffold(
        body: Center(child: Text('No hay configuración seleccionada.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(controller.selectedConfig.value?.name ?? 'Pomodoro Timer'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Get.back<Object>();
            },
            tooltip: 'Configuraciones',
          ),
        ],
      ),
      body: Center(
        child: Obx(() {
          if (controller.selectedConfig.value == null) {
            return const Text(
              'Selecciona una configuración desde la lista para comenzar.',
            );
          }
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                controller.currentTimerStateLabel,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              Text(
                controller.formattedTime,
                style: Theme.of(
                  context,
                ).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              Text(
                'Ronda: ${controller.currentRound.value} / ${controller.selectedConfig.value!.rounds}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (controller.selectedConfig.value?.goal?.isNotEmpty ?? false)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Meta: ${controller.selectedConfig.value!.goal}',
                    style: Theme.of(context).textTheme.titleSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (controller.canStart || controller.canResume)
                    ElevatedButton.icon(
                      icon: Icon(
                        controller.timerState.value == PomodoroTimerState.paused
                            ? Icons.play_arrow
                            : Icons.play_circle_fill,
                      ),
                      label: Text(
                        controller.timerState.value == PomodoroTimerState.paused
                            ? 'Reanudar'
                            : 'Iniciar',
                      ),
                      onPressed: controller.startPauseTimer,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                      ),
                    ),
                  if (controller.canPause)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.pause),
                      label: const Text('Pausar'),
                      onPressed: controller.startPauseTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.replay),
                    label: const Text('Reiniciar Ronda'),
                    onPressed:
                        controller.timerState.value !=
                                PomodoroTimerState.idle &&
                            controller.timerState.value !=
                                PomodoroTimerState.finished
                        ? controller.resetTimer
                        : null,
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.skip_next),
                    label: const Text('Saltar'),
                    onPressed:
                        controller.timerState.value !=
                                PomodoroTimerState.idle &&
                            controller.timerState.value !=
                                PomodoroTimerState.finished
                        ? controller.skipToNextState
                        : null,
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = Get.width;
    final isTV = screenWidth > 800 && Get.height > 500;
    final isWatch = screenWidth < 300;

    if (isWatch) {
      return _buildWatchPomodoroScreen(context);
    } else if (isTV) {
      return _buildTvPomodoroScreen(context);
    } else {
      return _buildMobilePomodoroScreen(context);
    }
  }
}
