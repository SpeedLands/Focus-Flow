import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:focus_flow/data/models/pomodoro_config.dart';
import 'package:focus_flow/data/models/session_stat.dart';
import 'package:focus_flow/data/providers/pomodoro_config_provider.dart';
import 'package:focus_flow/modules/auth/auth_controller.dart';

enum PomodoroTimerState { idle, work, shortBreak, longBreak, paused, finished }

class PomodoroControllerAna extends GetxController {
  // ───────── DI y estado general ─────────
  final PomodoroProvider _pomodoroProvider = Get.find<PomodoroProvider>();
  final AuthController _authController = Get.find<AuthController>();

  // ───────── Datos para el dashboard TV ─────────
  final RxList<SessionStat> sessionStats = <SessionStat>[].obs;

  // ───────── Configuraciones Pomodoro ─────────
  final RxList<PomodoroConfig> configs = <PomodoroConfig>[].obs;
  final Rx<PomodoroConfig?> selectedConfig = Rx<PomodoroConfig?>(null);
  StreamSubscription<List<PomodoroConfig>>? _configSubscription;
  RxBool isLoadingConfigs = true.obs;
  RxBool isSavingConfig = false.obs;

  // ───────── Estado del temporizador ─────────
  final Rx<PomodoroTimerState> timerState = PomodoroTimerState.idle.obs;
  final RxInt remainingTime = 0.obs;
  final RxInt currentRound = 0.obs;
  Timer? _timer;

  // ───────── Formulario ─────────
  final formKey = GlobalKey<FormState>();
  late TextEditingController nameController,
      workTimeController,
      shortBreakController,
      longBreakController,
      roundsController,
      goalController;
  String? editingConfigId;

  PomodoroTimerState? _stateBeforePause;

  // ───────── INIT ─────────
  @override
  void onInit() {
    super.onInit();

    // escuchar autenticación
    ever(_authController.currentUser, (user) {
      if (user != null) {
        _listenToConfigs(user.uid);
        _initFormControllers();
      }
    });

    // primer usuario (si ya estaba logeado)
    final user = _authController.currentUser.value;
    if (user != null) {
      _listenToConfigs(user.uid);
    }

    // datos ficticios para las gráficas
    _loadFakeStats();
  }

  // ───────── Fake stats para las gráficas ─────────
  void _loadFakeStats() {
    final now = DateTime.now();
    sessionStats.value = List.generate(7, (i) {
      final start = now.subtract(Duration(days: 6 - i));
      return SessionStat(
        start: start,
        workedMinutes: 25 + i * 5,
        breakMinutes: 5 + i * 2,
        pomodorosCompleted: 1 + i,
      );
    });
  }

  // ───────── CRUD de configuraciones ─────────
  void _listenToConfigs(String uid) {
    isLoadingConfigs.value = true;
    _configSubscription = _pomodoroProvider
        .streamConfigs(uid)
        .listen(
          (updated) {
            configs.assignAll(updated);
            if (selectedConfig.value == null && updated.isNotEmpty) {
              selectConfigForTimer(updated.first);
            } else if (selectedConfig.value != null &&
                !updated.contains(selectedConfig.value)) {
              resetTimer();
              selectedConfig.value = updated.isNotEmpty ? updated.first : null;
              if (selectedConfig.value != null) {
                _initializeTimerWithConfig(selectedConfig.value!);
              }
            }
            isLoadingConfigs.value = false;
          },
          onError: (Object e) {
            isLoadingConfigs.value = false;
            Get.snackbar('Error', 'No se pudieron cargar configs: $e');
          },
        );
  }

  void _initFormControllers({PomodoroConfig? config}) {
    nameController = TextEditingController(text: config?.name ?? '');
    workTimeController = TextEditingController(
      text: (config?.workTime ?? 1500).toString(),
    );
    shortBreakController = TextEditingController(
      text: (config?.shortBreak ?? 300).toString(),
    );
    longBreakController = TextEditingController(
      text: (config?.longBreak ?? 900).toString(),
    );
    roundsController = TextEditingController(
      text: (config?.rounds ?? 4).toString(),
    );
    goalController = TextEditingController(text: config?.goal ?? '');
    editingConfigId = config?.id;
  }

  void prepareFormForNewConfig() {
    _initFormControllers();
    editingConfigId = null;
  }

  void prepareFormForEdit(PomodoroConfig cfg) {
    _initFormControllers(config: cfg);
  }

  Future<void> saveConfig() async {
    final uid = _authController.currentUser.value?.uid ?? '';
    if (!(formKey.currentState?.validate() ?? false)) return;

    isSavingConfig.value = true;
    try {
      final cfg = PomodoroConfig(
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
        await _pomodoroProvider.addConfig(cfg, uid);
        Get.back<Object>();
        Get.snackbar('Éxito', 'Configuración añadida.');
      } else {
        await _pomodoroProvider.updateConfig(cfg, uid);
        Get.back<Object>();
        Get.snackbar('Éxito', 'Configuración actualizada.');
        if (selectedConfig.value?.id == editingConfigId) {
          selectConfigForTimer(cfg);
        }
      }
    } catch (e) {
      Get.snackbar('Error', '$e');
    } finally {
      isSavingConfig.value = false;
    }
  }

  Future<void> deleteConfig(String id) async {
    final uid = _authController.currentUser.value?.uid ?? '';
    isSavingConfig.value = true;
    final ok = await _pomodoroProvider.deleteConfig(id, uid);
    isSavingConfig.value = false;
    if (ok) {
      if (selectedConfig.value?.id == id) {
        selectedConfig.value = null;
        resetTimer();
      }
      Get.snackbar('Éxito', 'Configuración eliminada');
    } else {
      Get.snackbar('Error', 'No se pudo eliminar');
    }
  }

  // ───────── Temporizador ─────────
  void selectConfigForTimer(PomodoroConfig cfg) {
    selectedConfig.value = cfg;
    resetTimer();
  }

  void _initializeTimerWithConfig(PomodoroConfig cfg) {
    timerState.value = PomodoroTimerState.idle;
    remainingTime.value = cfg.workTime;
    currentRound.value = 0;
  }

  void startPauseTimer() {
    if (selectedConfig.value == null) {
      Get.snackbar('Atención', 'Selecciona una configuración primero');
      return;
    }

    if (timerState.value == PomodoroTimerState.paused) {
      timerState.value = _stateBeforePause ?? PomodoroTimerState.work;
      _startCountdown();
    } else if (_timer?.isActive ?? false) {
      _timer?.cancel();
      _stateBeforePause = timerState.value;
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
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remainingTime.value > 0) {
        remainingTime.value--;
      } else {
        _moveToNextState();
      }
    });
  }

  void resetTimer() {
    _timer?.cancel();
    _stateBeforePause = null;
    if (selectedConfig.value != null) {
      _initializeTimerWithConfig(selectedConfig.value!);
    } else {
      timerState.value = PomodoroTimerState.idle;
      remainingTime.value = 0;
      currentRound.value = 0;
    }
  }

  void skipToNextState() => _moveToNextState(forceSkip: true);

  void _moveToNextState({bool forceSkip = false}) {
    _timer?.cancel();

    final cfg = selectedConfig.value!;
    if (timerState.value == PomodoroTimerState.work ||
        (forceSkip && timerState.value == PomodoroTimerState.shortBreak)) {
      currentRound.value++;
      if (currentRound.value < cfg.rounds) {
        timerState.value = PomodoroTimerState.shortBreak;
        remainingTime.value = cfg.shortBreak;
      } else if (cfg.longBreak != null && cfg.longBreak! > 0) {
        timerState.value = PomodoroTimerState.longBreak;
        remainingTime.value = cfg.longBreak!;
      } else {
        currentRound.value = 0;
        timerState.value = PomodoroTimerState.finished;
        return;
      }
    } else {
      timerState.value = PomodoroTimerState.work;
      remainingTime.value = cfg.workTime;
    }
    _startCountdown();
  }

  // ───────── Getters auxiliares ─────────
  String get formattedTime {
    final m = (remainingTime.value / 60).floor().toString().padLeft(2, '0');
    final s = (remainingTime.value % 60).toString().padLeft(2, '0');
    return '$m:$s';
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

  // ───────── CLEANUP ─────────
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
