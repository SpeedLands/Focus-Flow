import 'dart:async';
import 'package:flutter/material.dart';
import 'package:focus_flow/data/providers/notification_provider.dart';
import 'package:focus_flow/routes/app_routes.dart';
import 'package:get/get.dart';
import 'package:focus_flow/data/models/app_notification_model.dart';
import 'package:focus_flow/modules/auth/auth_controller.dart';
import 'package:focus_flow/modules/tasks/tasks_controller.dart';

class NotificationController extends GetxController {
  final NotificationProvider _notificationProvider =
      Get.find<NotificationProvider>();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<AppNotificationModel> appNotifications =
      <AppNotificationModel>[].obs;
  final RxBool isLoadingNotifications = true.obs;
  final RxInt unreadNotificationCount = 0.obs;

  late Worker _authEverWorker;

  @override
  void onInit() {
    debugPrint("[GETX_CONTROLLER] NotificationController - onInit() CALLED");
    super.onInit();

    _authEverWorker = ever(_authController.currentUser, (firebaseUser) {
      debugPrint(
        "[NotificationController] Auth state changed. User: ${firebaseUser?.uid}",
      );
      if (firebaseUser != null) {
        debugPrint(
          "[NotificationController] User is authenticated (uid: ${firebaseUser.uid}). Binding notifications stream.",
        );
        _bindAppNotificationsStream(firebaseUser.uid);
      } else {
        debugPrint(
          "[NotificationController] User is not authenticated. Clearing notifications.",
        );
        _clearAndResetNotifications();
      }
    });

    final initialUser = _authController.currentUser.value;
    if (initialUser != null) {
      debugPrint(
        "[NotificationController] onInit - User ALREADY authenticated (uid: ${initialUser.uid}). Binding stream.",
      );
      _bindAppNotificationsStream(initialUser.uid);
    } else {
      debugPrint(
        "[NotificationController] onInit - User NOT authenticated initially. Waiting for auth state change.",
      );
      isLoadingNotifications.value = false;
      _clearAndResetNotifications();
    }
  }

  void _bindAppNotificationsStream(String userId) {
    debugPrint(
      "[NotificationController] _bindAppNotificationsStream - Binding for userId: $userId",
    );
    isLoadingNotifications.value = true;
    appNotifications.bindStream(
      _notificationProvider
          .getUserNotifications(userId)
          .map((notifications) {
            debugPrint(
              "NotificationController: Stream emitted ${notifications.length} notifications for $userId.",
            );
            unreadNotificationCount.value = notifications
                .where((n) => !n.isRead)
                .length;
            isLoadingNotifications.value = false;
            return notifications;
          })
          .handleError((error, stackTrace) {
            debugPrint(
              "NotificationController: ERROR in stream of AppNotifications for $userId: $error",
            );
            debugPrint("NotificationController: StackTrace: $stackTrace");
            isLoadingNotifications.value = false;
            unreadNotificationCount.value = 0;
            appNotifications.clear();
            return <AppNotificationModel>[];
          }),
    );
  }

  void _clearAndResetNotifications() {
    debugPrint(
      "[NotificationController] Clearing local notifications and resetting state.",
    );
    appNotifications.clear();
    isLoadingNotifications.value = false;
    unreadNotificationCount.value = 0;
  }

  Future<void> markAsRead(String notificationId) async {
    final userId = _authController.currentUser.value?.uid;
    if (userId == null) {
      debugPrint(
        "[NotificationController] markAsRead - User not authenticated.",
      );
      return;
    }
    try {
      await _notificationProvider.markAsRead(userId, notificationId);
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
      debugPrint(
        "[NotificationController] deleteNotification - User not authenticated.",
      );
      return;
    }
    try {
      await _notificationProvider.deleteNotification(userId, notificationId);
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
      debugPrint(
        "[NotificationController] markAllAsRead - User not authenticated.",
      );
      return;
    }
    try {
      await _notificationProvider.markAllAsRead(userId);
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
      debugPrint(
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
      debugPrint("Error en acceptTaskModificationRequest: $e");
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
      debugPrint(
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
      debugPrint("Error en rejectTaskModificationRequest: $e");
      Get.snackbar(
        "Error",
        "No se pudo rechazar la solicitud: ${e.toString()}",
      );
    }
  }

  void navigateFromNotification(AppNotificationModel notification) {
    final AuthController authController = Get.find<AuthController>();

    if (!notification.isRead && notification.id != null) {
      markAsRead(notification.id!);
    }

    final String? projectId = notification.data?['projectId'] as String?;
    final String? projectName = notification.data?['projectName'] as String?;
    final String? taskId = notification.data?['taskId'] as String?;
    final String? adminUserIdForProject =
        notification.data?['adminUserIdForProject'] as String?;
    final String? requestingUserId =
        notification.data?['requestingUserId'] as String?;

    switch (notification.type) {
      case AppNotificationType.projectInvitation:
        if (projectId != null) {
          Get.toNamed(
            AppRoutes.PROJECTS_LIST,
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
          Get.snackbar(
            notification.title,
            notification.body,
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 4),
          );
          return;
        }
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
        break;

      case AppNotificationType.generic:
        break;
    }

    if (notification.routeToNavigate != null &&
        notification.routeToNavigate!.isNotEmpty) {
      if (notification.routeToNavigate == AppRoutes.VERIFY_EMAIL &&
          AppRoutes.VERIFY_EMAIL.isEmpty) {
        debugPrint(
          "Advertencia: Se intenta navegar a una ruta vacía (VERIFY_EMAIL). Esto podría no funcionar con Get.toNamed().",
        );
      }
      Get.toNamed(notification.routeToNavigate!, arguments: notification.data);
      return;
    }

    Get.snackbar(
      notification.title,
      notification.body,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void onClose() {
    debugPrint("[GETX_CONTROLLER] NotificationController - onClose() CALLED");
    _authEverWorker.dispose();
    super.onClose();
  }
}
