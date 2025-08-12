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
                      Get.offAllNamed<Object>(AppRoutes.HOME);
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
                  'Selecciona Config',
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
                      Get.toNamed<Object>(AppRoutes.POMODORO_TIMER);
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
                    Get.offAllNamed<Object>(AppRoutes.HOME);
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

  Widget _buildMobilePomodoroScreen(BuildContext context) {
    return Scaffold(
      appBar: GFAppBar(
        title: const Text('Configuraciones Pomodoro'),
        backgroundColor: GFColors.PRIMARY,
        leading: GFIconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Get.offAllNamed<Object>(AppRoutes.HOME),
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
                  Get.toNamed<Object>(AppRoutes.POMODORO_TIMER);
                },
                icon: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'Más opciones',
                  onSelected: (value) {
                    if (value == 'start') {
                      controller.selectConfigForTimer(config);
                      Get.toNamed<Object>(AppRoutes.POMODORO_TIMER);
                    } else if (value == 'edit') {
                      controller.prepareFormForEdit(config);
                      Get.toNamed<Object>(AppRoutes.POMODORO_FORM);
                    } else if (value == 'delete') {
                      Get.defaultDialog<void>(
                        title: 'Confirmar Eliminación',
                        middleText:
                            "¿Estás seguro de que quieres eliminar la configuración '${config.name}'?",
                        textConfirm: 'Eliminar',
                        textCancel: 'Cancelar',
                        confirmTextColor: Colors.white,
                        onConfirm: () {
                          controller.deleteConfig(config.id);
                          Get.back<Object>();
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
          Get.toNamed<Object>(AppRoutes.POMODORO_FORM);
        },
        tooltip: 'Añadir Configuración',
        icon: const Icon(Icons.add),
        type: GFButtonType.solid,
        shape: GFIconButtonShape.circle,
      ),
    );
  }

  // --- VERSIÓN DE TV USANDO GETWIDGET ---

  Widget _buildTvPomodoroScreen(BuildContext context) {
    final FocusNode firstItemFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (firstItemFocusNode.context != null) {
        firstItemFocusNode.requestFocus();
      }
    });

    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: GFAppBar(
        backgroundColor: Colors.blueGrey[800],
        automaticallyImplyLeading: false,
        title: const Text('Configuraciones Pomodoro'),
        leading: GFIconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.offAllNamed<Object>(AppRoutes.HOME),
          type: GFButtonType.transparent,
        ),
      ),
      body: WillPopScope(
        onWillPop: () async {
          firstItemFocusNode.dispose();
          return true;
        },
        child: Obx(() {
          if (controller.isLoadingConfigs.value) {
            return const Center(
              child: GFLoader(
                type: GFLoaderType.circle,
                loaderColorOne: Colors.white,
              ),
            );
          }
          if (controller.configs.isEmpty) {
            // Reutilizamos el helper de botón para el estado vacío
            return _buildTvEmptyStateWithGetWidget();
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
            itemCount: controller.configs.length,
            itemBuilder: (context, index) {
              final PomodoroConfig config = controller.configs[index];
              return _buildTvConfigCardWithGetWidget(
                config: config,
                focusNode: index == 0 ? firstItemFocusNode : null,
              );
            },
          );
        }),
      ),
    );
  }

  // Tarjeta de configuración usando GFCard y GFButton
  Widget _buildTvConfigCardWithGetWidget({
    required PomodoroConfig config,
    FocusNode? focusNode,
  }) {
    // TRUCO: Envolvemos el GFCard en un widget Focus para poder asignarle el focusNode.
    return Focus(
      focusNode: focusNode,
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          return GFCard(
            margin: const EdgeInsets.only(bottom: 25),
            padding: const EdgeInsets.all(
              2,
            ), // Padding para que el borde se vea bien
            color: isFocused ? GFColors.PRIMARY : Colors.blueGrey[800],
            content: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GFTypography(
                    text: config.name,
                    type: GFTypographyType.typo4,
                    textColor: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Trabajo: ${config.workTime ~/ 60} min | Descanso: ${config.shortBreak ~/ 60} min | Rondas: ${config.rounds}',
                    style: Get.textTheme.titleMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            buttonBar: GFButtonBar(
              padding: const EdgeInsets.only(bottom: 10, right: 10),
              children: [
                GFButton(
                  onPressed: () {
                    controller.selectConfigForTimer(config);
                    Get.toNamed<Object>(AppRoutes.POMODORO_TIMER);
                  },
                  text: 'Iniciar',
                  icon: const Icon(
                    Icons.play_circle_outline,
                    color: Colors.white,
                  ),
                  color: GFColors.SUCCESS,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Estado vacío usando GFButton
  Widget _buildTvEmptyStateWithGetWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'No hay configuraciones guardadas',
            style: Get.textTheme.headlineMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 30),
          GFButton(
            onPressed: () {
              controller.prepareFormForNewConfig();
              Get.toNamed<Object>(AppRoutes.POMODORO_FORM);
            },
            text: 'Añadir la primera',
            icon: const Icon(Icons.add, color: Colors.white),
            color: GFColors.SUCCESS,
            size: GFSize.LARGE,
          ),
        ],
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
