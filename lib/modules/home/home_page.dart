import 'package:flutter/material.dart';
import 'package:focus_flow/modules/home/widgets/config_button.dart';
import 'package:focus_flow/modules/notifications/notifications_icon_badage.dart';
import 'package:focus_flow/routes/app_routes.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:focus_flow/modules/home/home_controller.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentDeviceType = controller.deviceType.value;

      switch (currentDeviceType) {
        case DeviceType.watch:
          return _buildWatchHomeScreen(context);
        case DeviceType.tv:
          return _buildTvHomeScreen(context);
        case DeviceType.tablet:
          return _buildTabletHomeScreen(context);
        case DeviceType.mobile:
          return _buildMobileHomeScreen(context);
      }
    });
  }

  Widget _buildWatchHomeScreen(BuildContext context) {
    final titleStyle = Get.textTheme.titleMedium?.copyWith(color: Colors.white);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: ListView(
          children: [
            Column(
              children: [
                Obx(
                  () => Text(
                    controller.greeting.split(',').first,
                    style: titleStyle?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Obx(
                  () => Text(
                    controller.userData.value?.name?.split(' ').first ?? "",
                    style: titleStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildWatchAction(
              context: context,
              text: "Iniciar Pomodoro",
              icon: Icons.timer_outlined,
              color: GFColors.WARNING,
              onTap: () => Get.toNamed(AppRoutes.POMODORO_LIST),
            ),
            const SizedBox(height: 10),

            _buildWatchAction(
              context: context,
              text: "Mis Proyectos",
              icon: Icons.folder_open,
              color: GFColors.PRIMARY,
              onTap: () => Get.toNamed(AppRoutes.PROJECTS_LIST),
            ),
            const SizedBox(height: 10),

            _buildWatchAction(
              context: context,
              text: "Notificaciones",
              icon: Icons.notifications_outlined,
              color: GFColors.INFO,
              onTap: () => Get.toNamed(AppRoutes.NOTIFICATIONS_LIST),
            ),
            const SizedBox(height: 10),

            _buildWatchAction(
              context: context,
              text: "Mi Perfil",
              icon: Icons.settings_outlined,
              color: Colors.teal,
              onTap: () => Get.toNamed(AppRoutes.USER_SETTINGS),
            ),
            const SizedBox(height: 10),

            _buildWatchAction(
              context: context,
              text: "Salir",
              icon: Icons.exit_to_app,
              color: GFColors.DANGER,
              onTap: controller.logout,
              isDestructive: true,
            ),
          ],
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
      shape: GFButtonShape.pills,
      color: isDestructive ? color : color.withValues(alpha: 0.2),
      textColor: isDestructive ? Colors.white : color,
      size: GFSize.LARGE,
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
      body: SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Obx(() => Text(controller.greeting, style: titleStyle)),
            const SizedBox(height: 10),
            Text("Bienvenido a FocusFlow. Organiza tu día.", style: bodyStyle),
            const SizedBox(height: 50),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 30,
              crossAxisSpacing: 30,
              childAspectRatio: 1.8,
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

  Widget _buildFeatureCardTV({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.blueGrey[800],
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        focusColor: color.withValues(alpha: 0.3),
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
    final titleStyle = Get.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.bold,
    );
    final bodyStyle = Get.textTheme.bodyLarge;
    final padding = const EdgeInsets.all(30.0);

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
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
            const SizedBox(width: 20),
            Expanded(
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
    final padding = const EdgeInsets.all(20.0);

    return Scaffold(
      appBar: GFAppBar(
        backgroundColor: GFColors.PRIMARY,
        title: const GFTypography(
          text: "FocusFlow Home",
          type: GFTypographyType.typo1,
          showDivider: false,
          textColor: GFColors.WHITE,
        ),
        elevation: 2.0,
        actions: [NotificationIconBadge(), GoToSettingsButton()],
      ),
      body: SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Obx(
              () => GFTypography(
                text: controller.greeting,
                type: GFTypographyType.typo1,
                showDivider: false,
              ),
            ),
            const SizedBox(height: 10),
            GFTypography(
              text: "Organiza tus proyectos y maximiza tu productividad.",
              type: GFTypographyType.typo4,
              showDivider: false,
            ),
            const SizedBox(height: 30),

            _buildFeatureSection(
              title: "Mis Proyectos",
              icon: Icons.folder_special_outlined,
              color: GFColors.PRIMARY,
              onTap: () {
                Get.toNamed(AppRoutes.PROJECTS_LIST);
              },
              isTV: false,
            ),
            const SizedBox(height: 15),
            _buildFeatureSection(
              title: "Temporizador Pomodoro",
              icon: Icons.timer_outlined,
              color: GFColors.WARNING,
              onTap: () {
                Get.offAllNamed(AppRoutes.POMODORO_LIST);
              },
              isTV: false,
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

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
    );
  }
}
