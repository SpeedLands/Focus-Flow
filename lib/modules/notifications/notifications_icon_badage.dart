import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
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
        'NotificationIconBadge: NotificationController no encontrado.',
      );

      return GFIconButton(
        icon: const Icon(Icons.notifications_off_outlined, color: Colors.grey),
        onPressed: () {
          Get.snackbar('Error', 'Controlador de notificaciones no disponible.');
        },
        tooltip: 'Notificaciones (Error de controlador)',
        type: GFButtonType.transparent,
      );
    }

    final iconColor = IconTheme.of(context).color;

    return Obx(() {
      final int unreadCount =
          notificationController.unreadNotificationCount.value;

      return GFIconBadge(
        position: const GFBadgePosition(top: 5, end: 5),
        counterChild: unreadCount > 0
            ? GFBadge(
                color: Colors.redAccent,
                textColor: Colors.white,
                shape: GFBadgeShape.pills,
                size: GFSize.SMALL,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
                child: Text(unreadCount > 9 ? '9+' : unreadCount.toString()),
              )
            : const SizedBox.shrink(),
        child: GFIconButton(
          onPressed: () {
            Get.toNamed<Object>(AppRoutes.NOTIFICATIONS_LIST);
          },
          icon: Icon(Icons.notifications_outlined, color: iconColor),
          tooltip: 'Notificaciones',
          type: GFButtonType.transparent,
        ),
      );
    });
  }
}
