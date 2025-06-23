import 'package:flutter/material.dart';
import 'package:focus_flow/data/models/pomodoro_config.dart';
import 'package:focus_flow/modules/pomodoro/pomodoro_controller.dart';
import 'package:focus_flow/routes/app_routes.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';

class PomodoroConfigListView extends GetView<PomodoroController> {
  const PomodoroConfigListView({super.key});

  Widget _buildWatchPomodoroScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Obx(() {
          if (controller.isLoadingConfigs.value) {
            return const GFLoader(
              type: GFLoaderType.circle,
              loaderColorOne: Colors.white,
              loaderColorTwo: Colors.grey,
              loaderColorThree: Colors.white70,
            );
          }
          if (controller.configs.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'No hay configuraciones',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.home_outlined, size: 18),
                    label: const Text('Ir a Home'),
                    onPressed: () {
                      Get.offAllNamed(AppRoutes.HOME);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 25.0, bottom: 8.0),
                child: Text(
                  "Selecciona Config",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              ...controller.configs.map((config) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  color: Colors.grey[850],
                  child: InkWell(
                    onTap: () {
                      controller.selectConfigForTimer(config);
                      Get.toNamed(AppRoutes.POMODORO_TIMER);
                    },
                    borderRadius: BorderRadius.circular(20.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Text(
                        config.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              }),
              Padding(
                padding: const EdgeInsets.only(
                  top: 5.0,
                  left: 20,
                  right: 20,
                  bottom: 15.0,
                ),
                child: ActionChip(
                  avatar: const Icon(
                    Icons.home_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'Ir a Home',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  backgroundColor: Colors.teal[700],
                  onPressed: () {
                    Get.offAllNamed(AppRoutes.HOME);
                  },
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTvPomodoroScreen(BuildContext context) {
    return Scaffold(
      appBar: GFAppBar(
        title: const Text('Configuraciones Pomodoro (TV)'),
        backgroundColor: GFColors.PRIMARY,
        leading: GFIconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Get.offAllNamed(AppRoutes.HOME),
        ),
      ),
      body: Center(
        child: Text(
          "Interfaz para TV aún no implementada. \n"
          "Considera una GridView o una disposición más amplia.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24),
        ),
      ),
      floatingActionButton: GFIconButton(
        onPressed: () {
          controller.prepareFormForNewConfig();
          Get.toNamed(AppRoutes.POMODORO_FORM);
        },
        tooltip: 'Añadir Configuración',
        icon: const Icon(Icons.add),
        type: GFButtonType.solid,
        shape: GFIconButtonShape.circle,
      ),
    );
  }

  Widget _buildMobilePomodoroScreen(BuildContext context) {
    return Scaffold(
      appBar: GFAppBar(
        title: const Text('Configuraciones Pomodoro'),
        backgroundColor: GFColors.PRIMARY,
        leading: GFIconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Get.offAllNamed(AppRoutes.HOME),
        ),
      ),
      body: Obx(() {
        if (controller.isLoadingConfigs.value) {
          return const Center(child: GFLoader(type: GFLoaderType.circle));
        }
        if (controller.configs.isEmpty) {
          return const Center(
            child: Text(
              'No hay configuraciones. ¡Añade una!',
              style: TextStyle(fontSize: 18),
            ),
          );
        }
        return ListView.builder(
          itemCount: controller.configs.length,
          itemBuilder: (context, index) {
            final PomodoroConfig config = controller.configs[index];
            return GFCard(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: GFListTile(
                focusColor: GFColors.FOCUS,
                title: Text(
                  config.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subTitle: Text(
                  'Trabajo: ${config.workTime ~/ 60}m, Descanso: ${config.shortBreak ~/ 60}m Rondas: ${config.rounds}',
                ),
                onTap: () {
                  controller.selectConfigForTimer(config);
                  Get.toNamed(AppRoutes.POMODORO_TIMER);
                },
                icon: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'Más opciones',
                  onSelected: (value) {
                    if (value == 'start') {
                      controller.selectConfigForTimer(config);
                      Get.toNamed(AppRoutes.POMODORO_TIMER);
                    } else if (value == 'edit') {
                      controller.prepareFormForEdit(config);
                      Get.toNamed(AppRoutes.POMODORO_FORM);
                    } else if (value == 'delete') {
                      Get.defaultDialog(
                        title: "Confirmar Eliminación",
                        middleText:
                            "¿Estás seguro de que quieres eliminar la configuración '${config.name}'?",
                        textConfirm: "Eliminar",
                        textCancel: "Cancelar",
                        confirmTextColor: Colors.white,
                        onConfirm: () {
                          controller.deleteConfig(config.id);
                          Get.back();
                        },
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'start',
                          child: ListTile(
                            leading: Icon(Icons.play_circle_fill_outlined),
                            title: Text('Iniciar Pomodoro'),
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Editar'),
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            title: Text(
                              'Eliminar',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: GFIconButton(
        onPressed: () {
          controller.prepareFormForNewConfig();
          Get.toNamed(AppRoutes.POMODORO_FORM);
        },
        tooltip: 'Añadir Configuración',
        icon: const Icon(Icons.add),
        type: GFButtonType.solid,
        shape: GFIconButtonShape.circle,
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
