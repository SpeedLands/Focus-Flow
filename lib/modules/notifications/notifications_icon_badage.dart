// lib/app/widgets/notification_icon_badge.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// Asegúrate que la ruta al controlador sea correcta
import 'package:focus_flow/modules/notifications/notifications_controller.dart';
import 'package:focus_flow/routes/app_routes.dart';

class NotificationIconBadge extends StatelessWidget {
  const NotificationIconBadge({super.key});

  @override
  Widget build(BuildContext context) {
    // --- INICIO DE CORRECCIÓN ---
    // Obtener la instancia del NotificationController que fue registrada por un Binding.
    // Esto asume que NotificationController está siendo puesto (put/lazyPut)
    // antes de que este widget se construya, típicamente en un InitialBinding
    // o si este widget siempre se usa en pantallas donde NotificationBinding ya se ejecutó.
    // Para un widget global como este, es mejor que NotificationController sea un servicio
    // o esté en un binding que se ejecute muy temprano (como InitialBinding o AppBinding).
    final NotificationController notificationController;
    try {
      notificationController = Get.find<NotificationController>();
    } catch (e) {
      // Si NotificationController no se encuentra, podría ser porque
      // el binding aún no se ha ejecutado o no está registrado globalmente.
      // En este caso, podríamos intentar ponerlo aquí si es la primera vez,
      // pero esto es más un workaround. Idealmente, ya está registrado.
      print(
        "NotificationIconBadge: NotificationController no encontrado, intentando ponerlo...",
      );
      // Esta línea es peligrosa si múltiples instancias de NotificationIconBadge
      // intentan hacer Get.put() sin un 'permanent: true' o una gestión cuidadosa.
      // Es mejor asegurar que esté en un binding.
      // Get.put(NotificationController(), permanent: true); // ¡Cuidado con esto!
      // notificationController = Get.find<NotificationController>();

      // Por ahora, para que no crashee y puedas depurar, devolvemos un placeholder
      // si no se encuentra. Esto te indica que el binding no está bien.
      return IconButton(
        icon: const Icon(Icons.notifications_off_outlined, color: Colors.grey),
        tooltip: "Notificaciones (Error de controlador)",
        onPressed: () {
          Get.snackbar("Error", "Controlador de notificaciones no disponible.");
        },
      );
    }
    // --- FIN DE CORRECCIÓN ---

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
