import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:focus_flow/modules/notifications/notifications_controller.dart';
import 'package:focus_flow/routes/app_routes.dart';

class NotificationIconBadge extends StatelessWidget {
  const NotificationIconBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationController notificationController;
    try {
      notificationController = Get.find<NotificationController>();
    } catch (e) {
      debugPrint(
        "NotificationIconBadge: NotificationController no encontrado, intentando ponerlo...",
      );

      return IconButton(
        icon: const Icon(Icons.notifications_off_outlined, color: Colors.grey),
        tooltip: "Notificaciones (Error de controlador)",
        onPressed: () {
          Get.snackbar("Error", "Controlador de notificaciones no disponible.");
        },
      );
    }

    return Obx(() {
      int unreadCount = notificationController.unreadNotificationCount.value;
      return Stack(
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: "Notificaciones",
            onPressed: () {
              Get.toNamed(AppRoutes.NOTIFICATIONS_LIST);
            },
          ),
          if (unreadCount > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  unreadCount > 9 ? '9+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      );
    });
  }
}
