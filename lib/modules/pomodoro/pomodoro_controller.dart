import 'dart:async';
import 'package:flutter/material.dart';
import 'package:focus_flow/data/providers/pomodoro_config_provider.dart';
import 'package:focus_flow/modules/auth/auth_controller.dart';
import 'package:get/get.dart';
import 'package:focus_flow/data/models/pomodoro_config.dart';
import 'package:focus_flow/data/services/notifications_service.dart';

enum PomodoroTimerState { idle, work, shortBreak, longBreak, paused, finished }

class PomodoroController extends GetxController {
  final PomodoroProvider _pomodoroProvider = Get.find<PomodoroProvider>();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<PomodoroConfig> configs = <PomodoroConfig>[].obs;
  final Rx<PomodoroConfig?> selectedConfig = Rx<PomodoroConfig?>(null);
  StreamSubscription<List<PomodoroConfig>>? _configSubscription;
  RxBool isLoadingConfigs = true.obs;
  RxBool isSavingConfig = false.obs;

  final Rx<PomodoroTimerState> timerState = PomodoroTimerState.idle.obs;
  final RxInt remainingTime = 0.obs;
  final RxInt currentRound = 0.obs;
  Timer? _timer;

  final formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController workTimeController;
  late TextEditingController shortBreakController;
  late TextEditingController longBreakController;
  late TextEditingController roundsController;
  late TextEditingController goalController;
  String? editingConfigId;

  PomodoroTimerState? stateBeforePause;

  @override
  void onInit() {
    super.onInit();
    ever(_authController.currentUser, (firebaseUser) {
      if (firebaseUser != null) {
        _listenToConfigs(firebaseUser.uid);
        _initFormControllers();
      } else {}
    });

    final initialUser = _authController.currentUser.value;
    if (initialUser != null) {
      _listenToConfigs(initialUser.uid);
    }
  }

  String get nextTimerStateLabel {
    if (selectedConfig.value == null) return '';

    final config = selectedConfig.value!;
    final currentState = timerState.value == PomodoroTimerState.paused
        ? stateBeforePause ?? timerState.value
        : timerState.value;

    switch (currentState) {
      case PomodoroTimerState.work:
        if (currentRound.value < config.rounds) {
          return 'Descanso Corto';
        }
        return 'Descanso Largo';
      case PomodoroTimerState.shortBreak:
      case PomodoroTimerState.longBreak:
        return 'Trabajo';
      default:
        return '';
    }
  }

  void _initFormControllers({PomodoroConfig? config}) {
    nameController = TextEditingController(text: config?.name ?? '');
    workTimeController = TextEditingController(
      text: config?.workTime.toString() ?? '25',
    );
    shortBreakController = TextEditingController(
      text: config?.shortBreak.toString() ?? '5',
    );
    longBreakController = TextEditingController(
      text: config?.longBreak?.toString() ?? '15',
    );
    roundsController = TextEditingController(
      text: config?.rounds.toString() ?? '4',
    );
    goalController = TextEditingController(text: config?.goal ?? '');
    editingConfigId = config?.id;
  }

  double get progressPercentage {
    // Si el timer no ha empezado o ya terminó, el aro está lleno/vacío (según diseño, aquí 1.0)
    if (selectedConfig.value == null ||
        timerState.value == PomodoroTimerState.idle ||
        timerState.value == PomodoroTimerState.finished) {
      return 1.0;
    }

    int totalTime = selectedConfig.value!.workTime; // Valor por defecto
    final PomodoroTimerState currentState =
        timerState.value == PomodoroTimerState.paused
        ? stateBeforePause ?? PomodoroTimerState.work
        : timerState.value;

    switch (currentState) {
      case PomodoroTimerState.work:
        totalTime = selectedConfig.value!.workTime;
        break;
      case PomodoroTimerState.shortBreak:
        totalTime = selectedConfig.value!.shortBreak;
        break;
      case PomodoroTimerState.longBreak:
        totalTime =
            selectedConfig.value!.longBreak ?? selectedConfig.value!.shortBreak;
        break;
      default:
        return 1.0;
    }

    if (totalTime == 0) return 1.0;

    // Calcula la fracción de tiempo restante
    return remainingTime.value / totalTime;
  }

  void _listenToConfigs(String uid) {
    isLoadingConfigs.value = true;
    _configSubscription = _pomodoroProvider
        .streamConfigs(uid)
        .listen(
          (updatedConfigs) {
            configs.assignAll(updatedConfigs);
            if (selectedConfig.value == null && updatedConfigs.isNotEmpty) {
              selectConfigForTimer(updatedConfigs.first);
            } else if (selectedConfig.value != null &&
                !updatedConfigs.contains(selectedConfig.value)) {
              resetTimer();
              selectedConfig.value = updatedConfigs.isNotEmpty
                  ? updatedConfigs.first
                  : null;
              if (selectedConfig.value != null) {
                _initializeTimerWithConfig(selectedConfig.value!);
              }
            }
            isLoadingConfigs.value = false;
          },
          onError: (Object error) {
            isLoadingConfigs.value = false;
            Get.snackbar(
              'Error',
              'No se pudieron cargar las configuraciones: $error',
            );
          },
        );
  }

  void prepareFormForNewConfig() {
    _initFormControllers();
    editingConfigId = null;
  }

  void prepareFormForEdit(PomodoroConfig config) {
    _initFormControllers(config: config);
  }

  Future<void> saveConfig() async {
    final String uid = _authController.currentUser.value?.uid ?? '';
    if (formKey.currentState?.validate() ?? false) {
      isSavingConfig.value = true;
      try {
        final config = PomodoroConfig(
          id: editingConfigId ?? '',
          name: nameController.text,
          workTime: int.parse(workTimeController.text) * 60,
          shortBreak: int.parse(shortBreakController.text) * 60,
          longBreak: longBreakController.text.isNotEmpty
              ? int.parse(longBreakController.text) * 60
              : null,
          rounds: int.parse(roundsController.text),
          goal: goalController.text.isNotEmpty ? goalController.text : null,
        );

        if (editingConfigId == null) {
          final newId = await _pomodoroProvider.addConfig(config, uid);
          if (newId != null) {
            Get.back<Object>();
            Get.snackbar('Éxito', 'Configuración "${config.name}" añadida.');
          } else {
            Get.snackbar('Error', 'No se pudo añadir la configuración.');
          }
        } else {
          final configToUpdate = PomodoroConfig(
            id: editingConfigId!,
            name: nameController.text,
            workTime: int.parse(workTimeController.text) * 60,
            shortBreak: int.parse(shortBreakController.text) * 60,
            longBreak: longBreakController.text.isNotEmpty
                ? int.parse(longBreakController.text) * 60
                : null,
            rounds: int.parse(roundsController.text),
            goal: goalController.text.isNotEmpty ? goalController.text : null,
          );
          final success = await _pomodoroProvider.updateConfig(
            configToUpdate,
            uid,
          );
          if (success) {
            Get.back<Object>();
            Get.snackbar(
              'Éxito',
              'Configuración "${config.name}" actualizada.',
            );
            if (selectedConfig.value?.id == editingConfigId) {
              selectConfigForTimer(configToUpdate);
            }
          } else {
            Get.snackbar('Error', 'No se pudo actualizar la configuración.');
          }
        }
      } catch (e) {
        Get.snackbar('Error', 'Error al guardar: ${e.toString()}');
      } finally {
        isSavingConfig.value = false;
      }
    }
  }

  Future<void> deleteConfig(String configId) async {
    final String uid = _authController.currentUser.value?.uid ?? '';
    await Get.defaultDialog<void>(
      title: 'Confirmar Eliminación',
      middleText: '¿Estás seguro de que quieres eliminar esta configuración?',
      textConfirm: 'Eliminar',
      textCancel: 'Cancelar',
      confirmTextColor: Colors.white,
      onConfirm: () async {
        Get.back<Object>();
        isSavingConfig.value = true;
        final success = await _pomodoroProvider.deleteConfig(configId, uid);
        isSavingConfig.value = false;
        if (success) {
          Get.snackbar('Éxito', 'Configuración eliminada.');
          if (selectedConfig.value?.id == configId) {
            selectedConfig.value = null;
            resetTimer();
            if (configs.isNotEmpty) {
              selectConfigForTimer(configs.first);
            }
          }
        } else {
          Get.snackbar('Error', 'No se pudo eliminar la configuración.');
        }
      },
    );
  }

  void selectConfigForTimer(PomodoroConfig config) {
    selectedConfig.value = config;
    resetTimer();
  }

  void _initializeTimerWithConfig(PomodoroConfig config) {
    timerState.value = PomodoroTimerState.idle;
    remainingTime.value = config.workTime;
    currentRound.value = 0;
  }

  void startPauseTimer() {
    if (selectedConfig.value == null) {
      Get.snackbar('Atención', 'Selecciona una configuración primero.');
      return;
    }

    if (timerState.value == PomodoroTimerState.paused) {
      if (stateBeforePause != null) {
        timerState.value = stateBeforePause!;
      }
      _startCountdown();
    } else if (_timer?.isActive ?? false) {
      _timer?.cancel();
      stateBeforePause = timerState.value; // Guarda estado actual
      timerState.value = PomodoroTimerState.paused;
    } else {
      if (timerState.value == PomodoroTimerState.idle ||
          timerState.value == PomodoroTimerState.finished) {
        currentRound.value = 1;
        timerState.value = PomodoroTimerState.work;
        remainingTime.value = selectedConfig.value!.workTime;
      }
      _startCountdown();
    }
  }

  void _startCountdown() {
    if (timerState.value == PomodoroTimerState.paused) {
      if (remainingTime.value > 0) {
        timerState.value =
            _getNextRunningState(); // Actualiza a estado correcto
      } else {
        _moveToNextState();
        return;
      }
    }

    if (timerState.value != PomodoroTimerState.idle &&
        timerState.value != PomodoroTimerState.finished) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (remainingTime.value > 0) {
          remainingTime.value--;
        } else {
          _moveToNextState();
        }
      });
    }
  }

  PomodoroTimerState _getNextRunningState() {
    // Restaura el estado correcto después de pausa
    if (remainingTime.value == selectedConfig.value?.workTime) {
      return PomodoroTimerState.work;
    } else if (remainingTime.value == selectedConfig.value?.shortBreak) {
      return PomodoroTimerState.shortBreak;
    } else if (remainingTime.value == selectedConfig.value?.longBreak) {
      return PomodoroTimerState.longBreak;
    }
    return PomodoroTimerState.work; // Fallback
  }

  void resetTimer() {
    _timer?.cancel();
    _timer = null;
    stateBeforePause = null;
    if (selectedConfig.value != null) {
      _initializeTimerWithConfig(selectedConfig.value!);
    } else {
      timerState.value = PomodoroTimerState.idle;
      remainingTime.value = 0;
      currentRound.value = 0;
    }
  }

  void skipToNextState() {
    if (selectedConfig.value == null) return;
    _moveToNextState(forceSkip: true);
  }

  void _moveToNextState({bool forceSkip = false}) {
    _timer?.cancel();
    _timer = null;

    if (selectedConfig.value == null) {
      resetTimer();
      return;
    }

    final config = selectedConfig.value!;

    if (timerState.value == PomodoroTimerState.work ||
        (forceSkip && timerState.value == PomodoroTimerState.shortBreak)) {
      currentRound.value++;
      if (currentRound.value < config.rounds) {
        timerState.value = PomodoroTimerState.shortBreak;
        remainingTime.value = config.shortBreak;
      } else if (config.longBreak != null && config.longBreak! > 0) {
        timerState.value = PomodoroTimerState.longBreak;
        remainingTime.value = config.longBreak!;
      } else {
        currentRound.value = 0;
        timerState.value = PomodoroTimerState.finished;
        Get.snackbar('¡Completado!', '¡Has completado todas las rondas!');
        return;
      }
    } else if (timerState.value == PomodoroTimerState.shortBreak ||
        (forceSkip && timerState.value == PomodoroTimerState.longBreak)) {
      timerState.value = PomodoroTimerState.work;
      remainingTime.value = config.workTime;
    } else if (timerState.value == PomodoroTimerState.longBreak) {
      currentRound.value = 1;
      timerState.value = PomodoroTimerState.work;
      remainingTime.value = config.workTime;
    } else if (timerState.value == PomodoroTimerState.idle ||
        timerState.value == PomodoroTimerState.finished) {
      currentRound.value = 1;
      timerState.value = PomodoroTimerState.work;
      remainingTime.value = config.workTime;
    }

    if (timerState.value != PomodoroTimerState.finished &&
        timerState.value != PomodoroTimerState.idle) {
      _startCountdown();
    }

    if (timerState.value == PomodoroTimerState.work) {
      _scheduleStageEndNotification(
        title: 'Fin del descanso',
        body: '¡Hora de volver a trabajar!',
        duration: Duration(seconds: remainingTime.value),
      );
    } else if (timerState.value == PomodoroTimerState.shortBreak ||
        timerState.value == PomodoroTimerState.longBreak) {
      _scheduleStageEndNotification(
        title: 'Fin del trabajo',
        body: '¡Hora de un descanso!',
        duration: Duration(seconds: remainingTime.value),
      );
    }
  }

  Future<void> _scheduleStageEndNotification({
    required String title,
    required String body,
    required Duration duration,
  }) async {
    final scheduledTime = DateTime.now().add(duration);

    await NotificationsService().scheduleNotification(
      title: '$title - Calendario',
      body: body,
      scheduledTime: scheduledTime,
      channelId: 'high_importance_channel',
      channelName: 'Notificaciones importantes',
      channelDescription: 'Recordatorios de Pomodoro',
      payload: timerState.value.name,
    );

    await NotificationsService().showBasicNotification(
      title: title,
      body: body,
      channelId: 'high_importance_channel',
      channelName: 'Notificaciones importantes',
      channelDescription: 'Recordatorios de Pomodoro',
      payload: timerState.value.name,
    );
  }

  String get formattedTime {
    final minutes = (remainingTime.value / 60).floor().toString().padLeft(
      2,
      '0',
    );
    final seconds = (remainingTime.value % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get currentTimerStateLabel {
    switch (timerState.value) {
      case PomodoroTimerState.work:
        return 'Trabajo';
      case PomodoroTimerState.shortBreak:
        return 'Descanso Corto';
      case PomodoroTimerState.longBreak:
        return 'Descanso Largo';
      case PomodoroTimerState.paused:
        return 'Pausado';
      case PomodoroTimerState.finished:
        return 'Completado';
      case PomodoroTimerState.idle:
        return 'Listo';
    }
  }

  bool get isTimerActive => _timer?.isActive ?? false;
  bool get canStart =>
      selectedConfig.value != null &&
      (timerState.value == PomodoroTimerState.idle ||
          timerState.value == PomodoroTimerState.paused ||
          timerState.value == PomodoroTimerState.finished);
  bool get canPause =>
      isTimerActive && timerState.value != PomodoroTimerState.paused;
  bool get canResume => timerState.value == PomodoroTimerState.paused;

  @override
  void onClose() {
    _timer?.cancel();
    _configSubscription?.cancel();
    nameController.dispose();
    workTimeController.dispose();
    shortBreakController.dispose();
    longBreakController.dispose();
    roundsController.dispose();
    goalController.dispose();
    super.onClose();
  }
}
