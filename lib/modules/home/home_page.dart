// lib/app/modules/home/views/home_screen.dart
import 'package:flutter/material.dart';
import 'package:focus_flow/modules/notifications/notifications_icon_badage.dart';
import 'package:focus_flow/routes/app_routes.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:focus_flow/modules/home/home_controller.dart';
// No necesitamos AuthController directamente aquí si HomeController ya expone lo necesario.

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  // En HomeScreen.dart build()
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Envolver en Obx para reaccionar a cambios de deviceType si fuera dinámico
      final currentDeviceType = controller.deviceType.value;

      switch (currentDeviceType) {
        case DeviceType.watch:
          return _buildWatchHomeScreen(context);
        case DeviceType.tv:
          return _buildTvHomeScreen(context);
        case DeviceType.tablet:
          return _buildTabletHomeScreen(
            context,
          ); // Podrías tener uno específico para tablet
        case DeviceType.mobile:
          return _buildMobileHomeScreen(context);
      }
    });
  }

  Widget _buildWatchHomeScreen(BuildContext context) {
    final titleStyle = Get.textTheme.titleMedium?.copyWith(color: Colors.white);
    Get.textTheme.bodySmall?.copyWith(color: Colors.grey[400]);

    // Podrías tener un PageView para diferentes "pantallas" en el watch
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0), // Un poco más de padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // Para que los botones se expandan
            children: [
              Obx(
                () => Text(
                  controller.greeting
                      .split(',')
                      .first, // Solo "Hola" o "Buenas tardes"
                  style: titleStyle?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Obx(
                () => Text(
                  controller.userData.value?.name?.split(' ').first ??
                      "", // Solo el primer nombre
                  style: titleStyle,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 25),

              // _buildWatchAction(
              //   context: context,
              //   text: "Tareas Hoy",
              //   icon: Icons.checklist_rtl_outlined,
              //   color: GFColors.PRIMARY,
              //   onTap: () {
              //     // Get.toNamed(AppRoutes.WATCH_TODAY_TASKS); // Navegar a pantalla específica de watch
              //     Get.snackbar("Watch", "Tareas del día (próximamente)");
              //   },
              // ),
              const SizedBox(height: 12),
              _buildWatchAction(
                context: context,
                text: "Iniciar Pomodoro",
                icon: Icons.timer_outlined,
                color: GFColors.WARNING,
                onTap: () {
                  // Get.toNamed(AppRoutes.WATCH_POMODORO);
                  Get.snackbar("Watch", "Pomodoro (próximamente)");
                },
              ),
              const SizedBox(height: 12),
              _buildWatchAction(
                context: context,
                text: "Salir",
                icon: Icons.exit_to_app,
                color: GFColors.DANGER,
                onTap: () => _showLogoutDialog(context), // Reutilizar diálogo
                isDestructive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWatchAction({
    required BuildContext context,
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GFButton(
      onPressed: onTap,
      text: text,
      icon: Icon(
        icon,
        color: isDestructive ? Colors.white : Colors.black,
        size: 20,
      ),
      fullWidthButton: true,
      type: GFButtonType.solid,
      shape: GFButtonShape.pills, // Botones redondeados se ven bien en watch
      color: isDestructive
          ? color
          : color.withValues(alpha: 0.2), // Color de fondo diferente
      textColor: isDestructive ? Colors.white : color,
      size: GFSize.LARGE, // Botones más grandes para facilitar el toque
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      padding: const EdgeInsets.symmetric(vertical: 12),
    );
  }

  Widget _buildTvHomeScreen(BuildContext context) {
    final titleStyle = Get.textTheme.displaySmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    );
    final bodyStyle = Get.textTheme.titleLarge?.copyWith(color: Colors.white70);
    final padding = const EdgeInsets.symmetric(
      horizontal: 60.0,
      vertical: 40.0,
    );

    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      // AppBar en TV a veces se omite o es diferente (ej. solo un logo o título grande)
      // appBar: AppBar(...) // Podrías quitarlo o simplificarlo
      body: SingleChildScrollView(
        // O un layout que no necesite scroll vertical excesivo
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Obx(() => Text(controller.greeting, style: titleStyle)),
            const SizedBox(height: 10),
            Text("Bienvenido a FocusFlow. Organiza tu día.", style: bodyStyle),
            const SizedBox(height: 50),

            // Usar un GridView para las secciones principales podría ser bueno en TV
            GridView.count(
              crossAxisCount: 2, // O 3, dependiendo del contenido
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 30,
              crossAxisSpacing: 30,
              childAspectRatio:
                  1.8, // Ajustar para que las tarjetas no sean muy altas
              children: [
                _buildFeatureCardTV(
                  title: "Mis Proyectos",
                  icon: Icons.folder_special_outlined,
                  color: GFColors.PRIMARY,
                  onTap: () => Get.toNamed(AppRoutes.PROJECTS_LIST),
                ),
                _buildFeatureCardTV(
                  title: "Temporizador Pomodoro",
                  icon: Icons.timer_outlined,
                  color: GFColors.WARNING,
                  onTap: () => Get.snackbar("TV", "Pomodoro (Próximamente)"),
                ),
                // _buildFeatureCardTV(
                //   title: "Vista 'Hoy'", // Ejemplo
                //   icon: Icons.calendar_today_outlined,
                //   color: GFColors.SUCCESS,
                //   onTap: () =>
                //       Get.snackbar("TV", "Tareas de Hoy (Próximamente)"),
                // ),
                _buildFeatureCardTV(
                  title: "Cerrar Sesión",
                  icon: Icons.logout,
                  color: GFColors.DANGER,
                  onTap: () => _showLogoutDialog(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Tarjeta específica para TV, más grande y con mejor manejo de foco
  Widget _buildFeatureCardTV({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      // Necesario para InkWell y el efecto de ripple
      color: Colors.blueGrey[800],
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        focusColor: color.withValues(alpha: 0.3), // Color cuando tiene foco
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GFAvatar(
                backgroundColor: color.withValues(alpha: 0.2),
                size: GFSize.LARGE,
                child: Icon(icon, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 15),
              Text(
                title,
                style: Get.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper para el diálogo de logout (para no duplicar)
  void _showLogoutDialog(BuildContext context) {
    Get.defaultDialog(
      title: "Cerrar Sesión",
      titleStyle: TextStyle(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black,
      ),
      middleText: "¿Estás seguro de que quieres cerrar sesión?",
      middleTextStyle: TextStyle(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white70
            : Colors.black87,
      ),
      textConfirm: "Sí, cerrar",
      textCancel: "Cancelar",
      confirmTextColor: Colors.white,
      cancelTextColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.white70
          : Colors.black,
      buttonColor: GFColors.DANGER,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.blueGrey[700]
          : Colors.white,
      onConfirm: controller.logout,
    );
  }

  Widget _buildTabletHomeScreen(BuildContext context) {
    // Similar al móvil pero con más espaciado o quizás un layout de dos columnas
    // si la app se presta para ello (ej. lista de proyectos a la izq, detalles a la der).
    // Por ahora, lo haremos similar al móvil pero con ajustes.

    final titleStyle = Get.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.bold,
    );
    final bodyStyle = Get.textTheme.bodyLarge;
    final padding = const EdgeInsets.all(30.0); // Más padding

    return Scaffold(
      appBar: AppBar(
        title: const Text("FocusFlow Home (Tablet)"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: padding,
        child: Row(
          // Ejemplo de posible layout de dos columnas
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              // Columna izquierda para contenido principal
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Obx(() => Text(controller.greeting, style: titleStyle)),
                  const SizedBox(height: 20),
                  Text(
                    "Gestiona tus proyectos y tareas eficientemente.",
                    style: bodyStyle,
                  ),
                  const SizedBox(height: 30),
                  _buildFeatureSection(
                    // Reutilizar el del móvil o crear uno adaptado
                    title: "Mis Proyectos",
                    icon: Icons.folder_special_outlined,
                    color: GFColors.PRIMARY,
                    onTap: () => Get.toNamed(AppRoutes.PROJECTS_LIST),
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureSection(
                    title: "Temporizador Pomodoro",
                    icon: Icons.timer_outlined,
                    color: GFColors.WARNING,
                    onTap: () =>
                        Get.snackbar("Tablet", "Pomodoro (Próximamente)"),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20), // Espacio entre columnas
            Expanded(
              // Columna derecha para info adicional o accesos rápidos
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text("Resumen Rápido", style: Get.textTheme.titleMedium),
                    const Divider(),
                    // Aquí podrías mostrar "Próximas 3 tareas" o "Proyectos activos"
                    const ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text("Info adicional aquí..."),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileHomeScreen(BuildContext context) {
    // Estilos y padding para móvil (puedes ajustar o tomar de Get.theme directamente)
    final titleStyle = Get.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.bold,
    );
    final bodyStyle = Get.textTheme.bodyLarge;
    final padding = const EdgeInsets.all(20.0);

    return Scaffold(
      // backgroundColor: Get.theme.scaffoldBackgroundColor, // Ya lo toma por defecto
      appBar: AppBar(
        title: const Text("FocusFlow Home"),
        // backgroundColor: Get.theme.appBarTheme.backgroundColor, // Ya lo toma por defecto
        elevation: 2.0,
        actions: [
          NotificationIconBadge(),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Cerrar Sesión",
            onPressed: () => _showLogoutDialog(context), // Reutilizar diálogo
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Obx(() => Text(controller.greeting, style: titleStyle)),
            const SizedBox(height: 10), // Un poco menos de espacio que en TV
            Text(
              "Organiza tus proyectos y maximiza tu productividad.",
              style: bodyStyle,
            ),
            const SizedBox(height: 30),

            // Usamos el _buildFeatureSection que ya tenías,
            // asegurándonos de que el flag 'isTV' sea false.
            _buildFeatureSection(
              title: "Mis Proyectos",
              icon: Icons.folder_special_outlined,
              color: GFColors.PRIMARY,
              onTap: () {
                Get.toNamed(AppRoutes.PROJECTS_LIST);
              },
              isTV: false, // Específicamente para móvil/tablet
            ),
            const SizedBox(height: 15), // Menos espacio vertical
            _buildFeatureSection(
              title: "Temporizador Pomodoro",
              icon: Icons.timer_outlined,
              color: GFColors.WARNING,
              onTap: () {
                Get.snackbar(
                  "Próximamente",
                  "El temporizador Pomodoro estará aquí.",
                  snackPosition: SnackPosition.BOTTOM,
                );
                // Get.toNamed(AppRoutes.POMODORO_SCREEN); // Cuando lo implementes
              },
              isTV: false,
            ),
            const SizedBox(height: 15),
            // _buildFeatureSection(
            //   title: "Tareas de Hoy",
            //   icon: Icons.today_outlined,
            //   color: GFColors.SUCCESS,
            //   onTap: () {
            //     // Deberías tener una pantalla o lógica para mostrar las tareas de hoy
            //     // Esto podría implicar llamar a un método en TaskController
            //     // taskController.loadTasksForToday();
            //     // Get.toNamed(AppRoutes.TODAY_TASKS);
            //     Get.snackbar(
            //       "Próximamente",
            //       "Aquí verás tus tareas para hoy.",
            //       snackPosition: SnackPosition.BOTTOM,
            //     );
            //   },
            //   isTV: false,
            // ),

            // Puedes añadir más secciones aquí, por ejemplo:
            // const SizedBox(height: 30),
            // Text("Próximas Tareas", style: Get.textTheme.titleLarge),
            // Divider(),
            // Placeholder para una lista de próximas tareas
            // _buildUpcomingTasksList(),
          ],
        ),
      ),
      // Considera si el FAB es necesario o si la navegación es clara desde las secciones
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () {
      //     // Lógica para acción principal, ej. añadir tarea rápida o proyecto
      //     // Podrías mostrar un BottomSheet con opciones
      //     Get.bottomSheet(
      //       Container(
      //         padding: const EdgeInsets.all(16),
      //         child: Wrap(
      //           children: <Widget>[
      //             ListTile(
      //               leading: const Icon(Icons.add_circle_outline),
      //               title: const Text('Nuevo Proyecto'),
      //               onTap: () {
      //                 Get.back(); // Cerrar BottomSheet
      //                 Get.find<ProjectController>().navigateToAddProject();
      //               },
      //             ),
      //             ListTile(
      //               leading: const Icon(Icons.add_task_outlined),
      //               title: const Text('Nueva Tarea Rápida'),
      //               onTap: () {
      //                 Get.back(); // Cerrar BottomSheet
      //                 // Necesitarías una forma de seleccionar proyecto o una tarea "sin asignar"
      //                 // Get.find<TaskController>().navigateToAddTask(projectId: null); // o una lógica diferente
      //                  Get.snackbar("Nueva Tarea", "Selecciona un proyecto primero o crea una tarea rápida.");
      //               },
      //             ),
      //           ],
      //         ),
      //       ),
      //       backgroundColor: Colors.white,
      //       elevation: 10,
      //       shape: RoundedRectangleBorder(
      //         borderRadius: BorderRadius.circular(10.0),
      //       ),
      //     );
      //   },
      //   label: const Text("Añadir"),
      //   icon: const Icon(Icons.add),
      //   // backgroundColor: GFColors.PRIMARY,
      // ),
    );
  }

  // Widget helper para secciones de características (placeholder)
  Widget _buildFeatureSection({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isTV = false,
  }) {
    return GFListTile(
      avatar: GFAvatar(
        backgroundColor: color.withValues(alpha: isTV ? 0.3 : 0.15),
        child: Icon(
          icon,
          color: isTV ? Colors.white : color,
          size: isTV ? 30 : 24,
        ),
      ),
      title: Text(
        title,
        style: Get.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: isTV ? Colors.white70 : Get.textTheme.titleLarge?.color,
        ),
      ),
      icon: Icon(
        Icons.arrow_forward_ios,
        color: isTV ? Colors.white54 : Colors.grey,
        size: 18,
      ),
      onTap: onTap,
      color: isTV ? Colors.blueGrey[800] : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.symmetric(vertical: 4),
      radius: 12,
      listItemTextColor: isTV ? Colors.white70 : null,
      // shadow: BoxShadow( // Opcional: añadir sombra
      //   color: Colors.grey.withOpacity(0.1),
      //   spreadRadius: 1,
      //   blurRadius: 3,
      //   offset: Offset(0, 1),
      // ),
    );
  }
}
