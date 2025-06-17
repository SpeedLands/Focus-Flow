// lib/app/modules/notifications/notification_controller.dart
import 'dart:async';
import 'package:focus_flow/routes/app_routes.dart';
import 'package:get/get.dart';
import 'package:focus_flow/data/models/app_notification_model.dart';
import 'package:focus_flow/data/services/app_notification_db_service.dart';
import 'package:focus_flow/modules/auth/auth_controller.dart';
import 'package:focus_flow/modules/tasks/tasks_controller.dart';

class NotificationController extends GetxController {
  final AppNotificationDbService _notificationDbService =
      Get.find<AppNotificationDbService>();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<AppNotificationModel> appNotifications =
      <AppNotificationModel>[].obs;
  final RxBool isLoadingNotifications = true.obs;
  final RxInt unreadNotificationCount = 0.obs;

  late Worker _authEverWorker;

  @override
  void onInit() {
    print("[GETX_CONTROLLER] NotificationController - onInit() CALLED");
    super.onInit();

    _authEverWorker = ever(_authController.currentUser, (firebaseUser) {
      print(
        "[NotificationController] Auth state changed. User: ${firebaseUser?.uid}",
      );
      if (firebaseUser != null) {
        print(
          "[NotificationController] User is authenticated (uid: ${firebaseUser.uid}). Binding notifications stream.",
        );
        _bindAppNotificationsStream(firebaseUser.uid);
      } else {
        print(
          "[NotificationController] User is not authenticated. Clearing notifications.",
        );
        _clearAndResetNotifications();
      }
    });

    final initialUser = _authController.currentUser.value;
    if (initialUser != null) {
      print(
        "[NotificationController] onInit - User ALREADY authenticated (uid: ${initialUser.uid}). Binding stream.",
      );
      _bindAppNotificationsStream(initialUser.uid);
    } else {
      print(
        "[NotificationController] onInit - User NOT authenticated initially. Waiting for auth state change.",
      );
      isLoadingNotifications.value = false;
      _clearAndResetNotifications();
    }
  }

  void _bindAppNotificationsStream(String userId) {
    print(
      "[NotificationController] _bindAppNotificationsStream - Binding for userId: $userId",
    );
    isLoadingNotifications.value = true;
    appNotifications.bindStream(
      _notificationDbService
          .getAppNotificationsStream(userId)
          .map((notifications) {
            print(
              "NotificationController: Stream emitted ${notifications.length} notifications for $userId.",
            );
            unreadNotificationCount.value = notifications
                .where((n) => !n.isRead)
                .length;
            isLoadingNotifications.value = false;
            return notifications;
          })
          .handleError((error, stackTrace) {
            print(
              "NotificationController: ERROR in stream of AppNotifications for $userId: $error",
            );
            print("NotificationController: StackTrace: $stackTrace");
            isLoadingNotifications.value = false;
            unreadNotificationCount.value = 0;
            appNotifications.clear();
            return <AppNotificationModel>[];
          }),
    );
  }

  void _clearAndResetNotifications() {
    print(
      "[NotificationController] Clearing local notifications and resetting state.",
    );
    appNotifications.clear();
    isLoadingNotifications.value = false;
    unreadNotificationCount.value = 0;
  }

  Future<void> markAsRead(String notificationId) async {
    final userId = _authController.currentUser.value?.uid;
    if (userId == null) {
      print("[NotificationController] markAsRead - User not authenticated.");
      return;
    }
    try {
      await _notificationDbService.markNotificationAsRead(
        userId,
        notificationId,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudo marcar la notificación como leída: ${e.toString()}",
      );
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    final userId = _authController.currentUser.value?.uid;
    if (userId == null) {
      print(
        "[NotificationController] deleteNotification - User not authenticated.",
      );
      return;
    }
    try {
      await _notificationDbService.deleteAppNotification(
        userId,
        notificationId,
      );
      Get.snackbar(
        "Notificación Eliminada",
        "La notificación ha sido eliminada.",
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudo eliminar la notificación: ${e.toString()}",
      );
    }
  }

  Future<void> markAllAsRead() async {
    final userId = _authController.currentUser.value?.uid;
    if (userId == null) {
      print("[NotificationController] markAllAsRead - User not authenticated.");
      return;
    }
    try {
      await _notificationDbService.markAllNotificationsAsRead(userId);
      Get.snackbar(
        "Notificaciones Leídas",
        "Todas las notificaciones han sido marcadas como leídas.",
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudieron marcar todas como leídas: ${e.toString()}",
      );
    }
  }

  Future<void> acceptTaskModificationRequest(
    AppNotificationModel notification,
  ) async {
    if (notification.type != AppNotificationType.taskModificationRequest) {
      Get.snackbar(
        "Error",
        "Esta notificación no es una solicitud de tarea válida.",
      );
      return;
    }
    if (notification.id == null) {
      Get.snackbar("Error", "ID de notificación no válido.");
      return;
    }

    final userId = _authController.currentUser.value?.uid;
    if (userId == null) {
      print(
        "[NotificationController] acceptTaskModificationRequest - User not authenticated.",
      );
      Get.snackbar("Error", "Usuario no autenticado.");
      return;
    }

    try {
      final TaskController taskController = Get.find<TaskController>();

      await taskController.approveTaskModificationRequest(notification);

      Get.snackbar(
        "Solicitud Aceptada",
        "La solicitud de tarea ha sido procesada.",
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print("Error en acceptTaskModificationRequest: $e");
      Get.snackbar("Error", "No se pudo aceptar la solicitud: ${e.toString()}");
    }
  }

  Future<void> rejectTaskModificationRequest(
    AppNotificationModel notification,
  ) async {
    if (notification.type != AppNotificationType.taskModificationRequest) {
      Get.snackbar(
        "Error",
        "Esta notificación no es una solicitud de tarea válida.",
      );
      return;
    }
    if (notification.id == null) {
      Get.snackbar("Error", "ID de notificación no válido.");
      return;
    }

    final userId = _authController.currentUser.value?.uid;
    if (userId == null) {
      print(
        "[NotificationController] rejectTaskModificationRequest - User not authenticated.",
      );
      Get.snackbar("Error", "Usuario no autenticado.");
      return;
    }

    try {
      final TaskController taskController = Get.find<TaskController>();
      await taskController.rejectTaskModificationRequest(notification);

      Get.snackbar(
        "Solicitud Rechazada",
        "La solicitud de tarea ha sido rechazada.",
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print("Error en rejectTaskModificationRequest: $e");
      Get.snackbar(
        "Error",
        "No se pudo rechazar la solicitud: ${e.toString()}",
      );
    }
  }

  void navigateFromNotification(AppNotificationModel notification) {
    final AuthController authController = Get.find<AuthController>();

    // 1. Marcar como leída (si aplica)
    if (!notification.isRead && notification.id != null) {
      markAsRead(notification.id!);
    }

    // 2. Extraer datos comunes de notification.data
    final String? projectId = notification.data?['projectId'] as String?;
    final String? projectName = notification.data?['projectName'] as String?;
    final String? taskId = notification.data?['taskId'] as String?;
    // final String? taskName = notification.data?['taskName'] as String?;
    final String? adminUserIdForProject =
        notification.data?['adminUserIdForProject'] as String?;
    final String? requestingUserId =
        notification.data?['requestingUserId'] as String?;

    // 3. Lógica de navegación específica por tipo
    switch (notification.type) {
      case AppNotificationType.projectInvitation:
        if (projectId != null) {
          Get.toNamed(
            AppRoutes
                .PROJECTS_LIST, // Asume que PROJECT_FORM puede manejar invitaciones
            arguments: {
              'projectId': projectId,
              'projectName': projectName ?? 'Invitación a Proyecto',
              'isInvitation': true,
            },
          );
          return;
        }
        break;

      case AppNotificationType.taskAssigned:
      case AppNotificationType.taskCompleted:
        if (projectId != null) {
          Get.toNamed(
            AppRoutes.TASKS_LIST,
            arguments: {
              'projectId': projectId,
              'projectName': projectName ?? 'Tareas del Proyecto',
              'taskIdToFocus': taskId,
            },
          );
          return;
        }
        break;

      case AppNotificationType.projectUpdate:
        if (projectId != null) {
          Get.toNamed(
            AppRoutes.PROJECTS_LIST,
            arguments: {
              'projectId': projectId,
              'projectName': projectName ?? 'Proyecto Actualizado',
            },
          );
          return;
        }
        break;

      case AppNotificationType.taskModificationRequest:
        if (projectId != null &&
            adminUserIdForProject != null &&
            authController.currentUser.value?.uid == adminUserIdForProject) {
          Get.toNamed(
            AppRoutes.TASKS_LIST,
            arguments: {
              'projectId': projectId,
              'projectName': projectName ?? 'Solicitudes de Tareas',
              'focusRequestSection': true,
            },
          );
          return;
        }
        break;

      case AppNotificationType.taskModificationApproved:
      case AppNotificationType.taskModificationRejected:
        if (requestingUserId != null &&
            authController.currentUser.value?.uid == requestingUserId &&
            projectId != null) {
          Get.toNamed(
            AppRoutes.TASKS_LIST,
            arguments: {
              'projectId': projectId,
              'projectName': projectName ?? 'Mis Tareas',
              'taskIdToFocus': taskId,
            },
          );
          return;
        }
        break;

      case AppNotificationType.projectDeletionRequest:
        if (projectId != null &&
            adminUserIdForProject != null &&
            authController.currentUser.value?.uid == adminUserIdForProject) {
          Get.toNamed(
            AppRoutes.PROJECTS_LIST,
            arguments: {
              'projectIdToFocus': projectId,
              'viewMode': 'deletionRequests',
            },
          );
          return;
        }
        break;

      case AppNotificationType.projectDeletionApproved:
        if (requestingUserId != null &&
            authController.currentUser.value?.uid == requestingUserId) {
          Get.offAllNamed(AppRoutes.PROJECTS_LIST);
          // Es bueno mostrar el snackbar incluso después de la navegación para confirmar
          Get.snackbar(
            notification.title,
            notification.body,
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 4),
          );
          return;
        }
        // Si es para otros miembros, caerá al manejo genérico
        break;

      case AppNotificationType.projectDeletionRejected:
        if (requestingUserId != null &&
            authController.currentUser.value?.uid == requestingUserId &&
            projectId != null) {
          Get.toNamed(
            AppRoutes.TASKS_LIST,
            arguments: {
              'projectId': projectId,
              'projectName': projectName ?? 'Proyecto',
            },
          );
          return;
        }
        break;

      case AppNotificationType.pomodoroEnd:
        // Generalmente no navega. Si routeToNavigate está configurado, se usará.
        // Si no, caerá al snackbar. Puedes añadir un Get.dialog() aquí si prefieres.
        // Ejemplo:
        // Get.dialog(AlertDialog(title: Text(notification.title), content: Text(notification.body)));
        // return; // Si el diálogo es suficiente y no quieres snackbar ni routeToNavigate.
        break;

      case AppNotificationType.generic:
        // No hay navegación específica, usará routeToNavigate o snackbar.
        break;
    }

    // 4. Manejo genérico de navegación (si `routeToNavigate` está presente y no se navegó antes)
    if (notification.routeToNavigate != null &&
        notification.routeToNavigate!.isNotEmpty) {
      if (notification.routeToNavigate == AppRoutes.VERIFY_EMAIL &&
          AppRoutes.VERIFY_EMAIL.isEmpty) {
        print(
          "Advertencia: Se intenta navegar a una ruta vacía (VERIFY_EMAIL). Esto podría no funcionar con Get.toNamed().",
        );
        // Decide cómo manejar esto. Podría ser un error o necesitar una lógica especial.
        // Por ahora, se intentará la navegación.
      }
      Get.toNamed(notification.routeToNavigate!, arguments: notification.data);
      return;
    }

    // 5. Fallback final: mostrar un snackbar si no hubo navegación y no hay routeToNavigate.
    // El modelo de AppNotificationModel requiere title y body, por lo que no deberían ser null.
    Get.snackbar(
      notification.title,
      notification.body,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
      // Considera usar los colores de tu tema:
      // backgroundColor: Get.theme.colorScheme.secondaryContainer,
      // colorText: Get.theme.colorScheme.onSecondaryContainer,
    );
  }

  @override
  void onClose() {
    print("[GETX_CONTROLLER] NotificationController - onClose() CALLED");
    _authEverWorker.dispose();
    super.onClose();
  }
}
