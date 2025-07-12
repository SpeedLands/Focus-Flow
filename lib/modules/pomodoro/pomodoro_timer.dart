import 'package:flutter/material.dart';
import 'package:focus_flow/modules/pomodoro/pomodoro_controller.dart';
import 'package:focus_flow/routes/app_routes.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:simple_animations/simple_animations.dart';

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

  Widget _buildTvPomodoroScreen(BuildContext context) {
    // Comprobaciones iniciales, igual que en la versión móvil
    if (controller.selectedConfig.value == null) {
      // Usamos un post frame callback para no causar errores durante el build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (controller.configs.isNotEmpty) {
          controller.selectConfigForTimer(controller.configs.first);
        } else {
          Get.back<Object>();
          Get.snackbar('Error', 'No hay configuraciones Pomodoro disponibles.');
        }
      });
      // Mientras tanto, mostramos un loader
      return const Scaffold(
        backgroundColor: Color(0xFF101D25),
        body: Center(child: GFLoader(type: GFLoaderType.circle)),
      );
    }

    // El cuerpo principal de nuestra nueva UI de TV
    return Obx(() {
      final state = controller.timerState.value;
      final isWork =
          state == PomodoroTimerState.work ||
          (state == PomodoroTimerState.paused &&
              controller.stateBeforePause == PomodoroTimerState.work);
      return Scaffold(
        body: Stack(
          children: [
            AnimatedBackground(isWork: isWork),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  children: [
                    _buildHeaderTV(),
                    const Spacer(),
                    _buildProgressRingTV(), // Ya lo teníamos
                    const Spacer(),
                    _buildControlsAndRoundsTV(), // Ya lo teníamos
                  ],
                ),
              ),
            ),

            // Elemento 8: Indicador de Próxima Etapa
            Positioned(
              top: 120,
              right: 40,
              child: _buildNextStageIndicatorTV(),
            ),
          ],
        ),
      );
    });
  }

  // --- WIDGETS AUXILIARES PARA LA VISTA DE TV ---

  Widget _buildHeaderTV() {
    return Obx(() {
      final config = controller.selectedConfig.value;
      if (config == null) return const SizedBox.shrink();

      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _infoChip(
                'Trabajo: ${config.workTime ~/ 60}m',
                Icons.work_outline,
              ),
              _infoChip(
                'Descanso: ${config.shortBreak ~/ 60}m',
                Icons.free_breakfast_outlined,
              ),
              if (config.longBreak != null)
                _infoChip(
                  'Largo: ${config.longBreak! ~/ 60}m',
                  Icons.king_bed_outlined,
                ),
            ],
          ),
          if (config.goal != null && config.goal!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                'Meta: ${config.goal}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _infoChip(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(color: Colors.white54, fontSize: 18),
          ),
        ],
      ),
    );
  }

  // Elemento 2: Aro de Progreso Gigante
  Widget _buildProgressRingTV() {
    return Obx(() {
      final state = controller.timerState.value;
      final isWork =
          state == PomodoroTimerState.work ||
          (state == PomodoroTimerState.paused &&
              controller.stateBeforePause == PomodoroTimerState.work);
      final color = isWork ? Colors.tealAccent : Colors.orangeAccent;

      return SizedBox(
        width: 350,
        height: 350,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 20,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                color.withValues(alpha: 0.2),
              ),
            ),
            // Círculo de progreso
            CircularProgressIndicator(
              value: controller.progressPercentage,
              strokeWidth: 20,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    controller.formattedTime,
                    style: const TextStyle(
                      fontSize: 90,
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 8),
                  // --- TRANSICIÓN ANIMADA PARA EL TEXTO DE ESTADO ---
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: animation, child: child),
                      );
                    },
                    child: Text(
                      // Usamos un Key para que AnimatedSwitcher sepa que el widget cambió
                      key: ValueKey<String>(controller.currentTimerStateLabel),
                      controller.currentTimerStateLabel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // Elemento 3: Controles y Visualizador de Rondas
  Widget _buildControlsAndRoundsTV() {
    return Column(
      children: [
        // Elemento 4: Visualizador de Rondas
        Obx(() {
          final config = controller.selectedConfig.value;
          if (config == null) return const SizedBox.shrink();
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(config.rounds, (index) {
              final isCompleted = index < controller.currentRound.value - 1;
              final isCurrent =
                  index == controller.currentRound.value - 1 &&
                  controller.timerState.value != PomodoroTimerState.idle;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(
                  isCompleted
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isCurrent ? Colors.tealAccent : Colors.white24,
                  size: 30,
                ),
              );
            }),
          );
        }),
        const SizedBox(height: 40),
        // Botones de control
        Obx(
          () => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _controlButtonTV(
                icon: Icons.replay,
                label: 'Reiniciar',
                onPressed:
                    controller.timerState.value != PomodoroTimerState.idle &&
                        controller.timerState.value !=
                            PomodoroTimerState.finished
                    ? controller.resetTimer
                    : null,
              ),
              const SizedBox(width: 40),
              if (controller.canStart || controller.canResume)
                _controlButtonTV(
                  icon: Icons.play_arrow,
                  label:
                      controller.timerState.value == PomodoroTimerState.paused
                      ? 'Reanudar'
                      : 'Iniciar',
                  onPressed: controller.startPauseTimer,
                  isPrimary: true,
                ),
              if (controller.canPause)
                _controlButtonTV(
                  icon: Icons.pause,
                  label: 'Pausar',
                  onPressed: controller.startPauseTimer,
                  isPrimary: true,
                ),
              const SizedBox(width: 40),
              _controlButtonTV(
                icon: Icons.skip_next,
                label: 'Saltar',
                onPressed:
                    controller.timerState.value != PomodoroTimerState.idle &&
                        controller.timerState.value !=
                            PomodoroTimerState.finished
                    ? controller.skipToNextState
                    : null,
              ),
              const SizedBox(width: 40),
              _controlButtonTV(
                icon: Icons.arrow_back,
                label: 'Regresar',
                onPressed: () {
                  Get.toNamed<Object>(AppRoutes.POMODORO_LIST);
                },
                isPrimary: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNextStageIndicatorTV() {
    return Obx(() {
      final nextStateLabel =
          controller.nextTimerStateLabel; // Necesitas crear este getter
      if (nextStateLabel.isEmpty) return const SizedBox.shrink();

      return Opacity(
        opacity: 0.7,
        child: Chip(
          avatar: const Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: Colors.white70,
          ),
          label: Text(
            'Siguiente: $nextStateLabel',
            style: const TextStyle(color: Colors.white70),
          ),
          backgroundColor: const Color(0xFF1a2436),
        ),
      );
    });
  }

  Widget _controlButtonTV({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
    bool isPrimary = false,
  }) {
    return GFButton(
      onPressed: onPressed,
      text: label,
      icon: Icon(icon, color: onPressed != null ? Colors.white : Colors.grey),
      size: GFSize.LARGE,
      shape: GFButtonShape.pills,
      color: isPrimary ? GFColors.SUCCESS : GFColors.TRANSPARENT,
      type: isPrimary ? GFButtonType.solid : GFButtonType.outline,
      textColor: onPressed != null ? Colors.white : Colors.grey,
      focusColor: GFColors.PRIMARY.withValues(alpha: 0.4),
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

class AnimatedBackground extends StatelessWidget {
  final bool isWork;
  const AnimatedBackground({super.key, required this.isWork});

  @override
  Widget build(BuildContext context) {
    // Usamos MirrorAnimation para que la animación vaya y vuelva suavemente
    return MirrorAnimationBuilder<Color?>(
      tween: isWork
          ? ColorTween(
              begin: const Color(0xFF0D47A1),
              end: const Color(0xFF1565C0),
            ) // Tonos azules para trabajo
          : ColorTween(
              begin: const Color(0xFF1B5E20),
              end: const Color(0xFF2E7D32),
            ), // Tonos verdes para descanso
      duration: const Duration(seconds: 10),
      builder: (context, value, child) {
        return Container(color: value as Color);
      },
    );
  }
}
