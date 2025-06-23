import 'package:focus_flow/data/providers/pomodoro_config_provider.dart';
import 'package:focus_flow/modules/pomodoro/pomodoro_controller.dart';
import 'package:get/get.dart';

class PomodoroBinidng extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PomodoroController>(() => PomodoroController());
    Get.lazyPut<PomodoroProvider>(() => PomodoroProvider(Get.find()));
  }
}
