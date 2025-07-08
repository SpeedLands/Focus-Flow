import 'package:flutter/material.dart';
import 'package:focus_flow/modules/pomodoro/pomodoro_controller.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';

class PomodoroTimerScreen extends GetView<PomodoroController> {
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
              Get.back();
              Get.snackbar(
                'Error',
                'No hay configuraciones Pomodoro disponibles.',
              );
            });
            return const Text("Sin configuración.");
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

  // pomodoro_timer_screen.dart

  Widget _buildTvPomodoroScreen(BuildContext context) {
    // Asegurarse de que hay una configuración seleccionada, igual que en mobile.
    if (controller.selectedConfig.value == null) {
      if (controller.configs.isNotEmpty) {
        controller.selectConfigForTimer(controller.configs.first);
      } else {
        // Este caso es improbable si se llega desde una lista, pero es un buen fallback.
        return const Scaffold(
          backgroundColor: Color(0xFF101D25),
          body: Center(
            child: Text(
              "No hay configuraciones de Pomodoro disponibles.",
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: const Color(
        0xFF101D25,
      ), // Un color de fondo oscuro para TV
      body: Obx(
        () => Stack(
          children: [
            // Contenido principal centrado
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. ARO DE PROGRESO CIRCULAR
                  _buildCircularTimerTV(),
                  const SizedBox(height: 40),
                  // 2. INDICADOR DE RONDAS
                  _buildRoundsIndicatorTV(),
                  const SizedBox(height: 50),
                  // Botones de control
                  _buildControlButtonsTV(),
                ],
              ),
            ),
            // 3. TARJETA DE INFORMACIÓN ESTÁTICA
            // _buildInfoCardTV(),
            // // 4. BARRA DE CICLO
            _buildCycleBarTV(),
          ],
        ),
      ),
    );
  }

  // ---- WIDGETS AUXILIARES PARA LA VISTA DE TV ----

  // 1. WIDGET PARA EL TEMPORIZADOR CIRCULAR
  Widget _buildCircularTimerTV() {
    final color = _getTimerColor(controller.timerState.value);

    return SizedBox(
      width: 350,
      height: 350,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Aro de fondo (el "track")
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: 20,
            backgroundColor: Colors.blueGrey[800],
            color: color,
          ),
          // Aro de progreso principal
          CircularProgressIndicator(
            value: controller.progressPercentage,
            strokeWidth: 20,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            backgroundColor:
                Colors.transparent, // Transparente para ver el fondo
          ),
          // Contenido en el centro (tiempo y estado)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GFTypography(
                  text: controller.formattedTime,
                  type: GFTypographyType.typo1,
                  textColor: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: 8),
                GFTypography(
                  text: controller.currentTimerStateLabel.toUpperCase(),
                  type: GFTypographyType.typo5,
                  textColor: Colors.white70,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. WIDGET PARA EL INDICADOR DE RONDAS
  Widget _buildRoundsIndicatorTV() {
    final config = controller.selectedConfig.value;
    if (config == null) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(config.rounds, (index) {
        final roundNumber = index + 1;
        final isCompleted = roundNumber <= controller.currentRound.value;
        // La ronda que precede al descanso largo
        final isLongBreakNext =
            roundNumber == config.rounds && config.longBreak != null;

        Color color = isCompleted
            ? (isLongBreakNext ? GFColors.WARNING : GFColors.PRIMARY)
            : Colors.blueGrey[700]!;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 40,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
        );
      }),
    );
  }

  // 3. WIDGET PARA LA TARJETA DE INFORMACIÓN ESTÁTICA
  Widget _buildInfoCardTV() {
    final config = controller.selectedConfig.value;
    if (config == null) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.topLeft,
      child: GFCard(
        margin: const EdgeInsets.all(24),
        color: Colors.blueGrey[800]?.withOpacity(0.8),
        padding: const EdgeInsets.all(16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GFListTile(
              color: Colors.transparent,
              padding: EdgeInsets.zero,
              margin: EdgeInsets.zero,
              avatar: GFAvatar(
                backgroundColor: _getTimerColor(
                  controller.timerState.value,
                ).withOpacity(0.5),
                child: const Icon(Icons.timer_outlined, color: Colors.white),
              ),
              title: Text(
                config.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (config.goal != null && config.goal!.isNotEmpty) ...[
              const Divider(color: Colors.white24, height: 20),
              Text(
                "OBJETIVO:",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                config.goal!,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 4. WIDGET PARA LA BARRA DE CICLO
  Widget _buildCycleBarTV() {
    final config = controller.selectedConfig.value;
    if (config == null) return const SizedBox.shrink();

    final bool isWorkActive =
        controller.timerState.value == PomodoroTimerState.work ||
        (controller.timerState.value == PomodoroTimerState.paused &&
            controller.stateBeforePause == PomodoroTimerState.work);
    final bool isBreakActive =
        !isWorkActive &&
        controller.timerState.value != PomodoroTimerState.idle &&
        controller.timerState.value != PomodoroTimerState.finished;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 30),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _cycleSegment(
              "Trabajo",
              "${config.workTime ~/ 60} min",
              isWorkActive,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.arrow_forward, color: Colors.white54, size: 20),
            ),
            _cycleSegment(
              "Descanso",
              "${config.shortBreak ~/ 60} min",
              isBreakActive,
            ),
          ],
        ),
      ),
    );
  }

  Widget _cycleSegment(String label, String duration, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? _getTimerColor(controller.timerState.value).withOpacity(0.9)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            duration,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET PARA LOS BOTONES DE CONTROL
  Widget _buildControlButtonsTV() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Botón de Reiniciar
        GFButton(
          onPressed: controller.resetTimer,
          text: "Reiniciar",
          icon: const Icon(Icons.replay, color: Colors.white),
          type: GFButtonType.outline2x,
          size: GFSize.LARGE,
          focusColor: GFColors.WARNING.withOpacity(0.3),
          hoverColor: GFColors.WARNING.withOpacity(0.2),
          color: GFColors.WARNING,
        ),
        const SizedBox(width: 24),
        // Botón Principal (Iniciar/Pausar/Reanudar)
        if (controller.canStart || controller.canResume)
          GFButton(
            onPressed: controller.startPauseTimer,
            text: controller.timerState.value == PomodoroTimerState.paused
                ? "Reanudar"
                : "Iniciar",
            icon: Icon(
              controller.timerState.value == PomodoroTimerState.paused
                  ? Icons.play_arrow
                  : Icons.play_circle,
              color: Colors.black,
            ),
            size: GFSize.LARGE,
            color: GFColors.SUCCESS,
            focusColor: GFColors.SUCCESS.withOpacity(0.3),
            hoverColor: GFColors.SUCCESS.withOpacity(0.2),
            textColor: Colors.black,
          ),
        if (controller.canPause)
          GFButton(
            onPressed: controller.startPauseTimer,
            text: "Pausar",
            icon: const Icon(Icons.pause, color: Colors.white),
            size: GFSize.LARGE,
            color: GFColors.FOCUS,
            focusColor: GFColors.FOCUS.withOpacity(0.3),
            hoverColor: GFColors.FOCUS.withOpacity(0.2),
          ),
        const SizedBox(width: 24),
        // Botón de Saltar
        GFButton(
          onPressed: controller.skipToNextState,
          text: "Saltar",
          icon: const Icon(Icons.skip_next, color: Colors.white),
          type: GFButtonType.outline2x,
          size: GFSize.LARGE,
          focusColor: GFColors.INFO.withOpacity(0.3),
          hoverColor: GFColors.INFO.withOpacity(0.2),
          color: GFColors.INFO,
        ),
      ],
    );
  }

  // FUNCIÓN AUXILIAR PARA OBTENER EL COLOR SEGÚN EL ESTADO
  Color _getTimerColor(PomodoroTimerState state) {
    PomodoroTimerState stateForColor = state;
    if (state == PomodoroTimerState.paused) {
      stateForColor = controller.stateBeforePause ?? PomodoroTimerState.work;
    }

    switch (stateForColor) {
      case PomodoroTimerState.work:
        return GFColors.DANGER; // Rojo para trabajo
      case PomodoroTimerState.shortBreak:
        return GFColors.SUCCESS; // Verde para descanso corto
      case PomodoroTimerState.longBreak:
        return GFColors.INFO; // Azul para descanso largo
      default:
        return GFColors.SECONDARY; // Un color neutral para otros estados
    }
  }

  Widget _buildMobilePomodoroScreen(BuildContext context) {
    if (controller.selectedConfig.value == null &&
        controller.configs.isNotEmpty) {
      controller.selectConfigForTimer(controller.configs.first);
    } else if (controller.selectedConfig.value == null &&
        controller.configs.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.back();
        Get.snackbar('Error', 'No hay configuraciones Pomodoro disponibles.');
      });
      return const Scaffold(
        body: Center(child: Text("No hay configuración seleccionada.")),
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
              Get.back();
            },
            tooltip: "Configuraciones",
          ),
        ],
      ),
      body: Center(
        child: Obx(() {
          if (controller.selectedConfig.value == null) {
            return const Text(
              "Selecciona una configuración desde la lista para comenzar.",
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
