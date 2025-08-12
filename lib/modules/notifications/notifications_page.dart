import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:focus_flow/modules/notifications/notifications_controller.dart';
import 'package:focus_flow/data/models/app_notification_model.dart';
import 'package:focus_flow/modules/auth/auth_controller.dart';
import 'package:intl/intl.dart';
import 'package:getwidget/getwidget.dart';

class NotificationListScreen extends GetView<NotificationController> {
  const NotificationListScreen({super.key});
  AuthController get _authController => Get.find<AuthController>();

  Widget _buildMobileTasksScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          Obx(
            () => controller.unreadNotificationCount.value > 0
                ? TextButton(
                    onPressed: controller.markAllAsRead,
                    child: Text(
                      'Marcar Todas Leídas',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingNotifications.value &&
            controller.appNotifications.isEmpty) {
          return const Center(child: GFLoader(type: GFLoaderType.circle));
        }
        if (controller.appNotifications.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_off_outlined,
                  size: 70,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No tienes notificaciones',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          itemCount: controller.appNotifications.length,
          separatorBuilder: (context, index) =>
              const Divider(height: 1, indent: 72, endIndent: 16),
          itemBuilder: (context, index) {
            final notification = controller.appNotifications[index];
            return Dismissible(
              key: Key(notification.id ?? 'notification_$index'),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                if (notification.id != null) {
                  controller.deleteNotification(notification.id!);
                }
              },
              background: Container(
                color: Colors.redAccent.shade100.withValues(alpha: 0.8),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: AlignmentDirectional.centerEnd,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_sweep_outlined,
                      color: Colors.white,
                      size: 30,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Eliminar',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
              child: _buildNotificationItem(context, notification),
            );
          },
        );
      }),
    );
  }

  Widget _buildTvTasksScreen(BuildContext context) {
    // Estado local para manejar la notificación seleccionada en la UI de TV.

    return Scaffold(
      backgroundColor: const Color(0xFF101827),
      appBar: GFAppBar(
        title: const Text('Notificaciones'),
        backgroundColor: const Color(0xFF1a2436),
        actions: [
          Obx(
            () => controller.unreadNotificationCount.value > 0
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: GFButton(
                      onPressed: controller.markAllAsRead,
                      text: 'Marcar Todas Leídas',
                      icon: const Icon(Icons.done_all, color: Colors.white),
                      type: GFButtonType.outline,
                      shape: GFButtonShape.pills,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingNotifications.value &&
            controller.appNotifications.isEmpty) {
          return const Center(child: GFLoader(type: GFLoaderType.square));
        }

        if (controller.appNotifications.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_off_outlined,
                  size: 90,
                  color: Colors.grey,
                ),
                SizedBox(height: 24),
                Text(
                  'No tienes notificaciones',
                  style: TextStyle(fontSize: 22, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Row(
          children: [
            // Panel izquierdo: Lista de notificaciones
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Obx(
                  () => ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    itemCount: controller.appNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = controller.appNotifications[index];

                      return GFListTile(
                        focusColor: GFColors.ALT,
                        title: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: !notification.isRead
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 16,
                            color: GFColors.WHITE,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subTitle: Text(
                          notification.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: GFColors.WHITE),
                        ),
                        avatar: GFAvatar(
                          backgroundColor: _getIconBackgroundColor(
                            notification.type,
                            context,
                          ).withOpacity(0.2),
                          child: Icon(
                            _iconForNotificationType(notification.type),
                            color: _getIconColor(notification.type, context),
                            size: 24,
                          ),
                        ),
                        onTap: () {
                          controller.selectedNotification.value = notification;
                        },
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        margin: const EdgeInsets.symmetric(
                          vertical: 2,
                          horizontal: 8,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Panel derecho: Detalles de la notificación seleccionada
            Expanded(
              flex: 3,
              child: Obx(() {
                final selected = controller.selectedNotification.value;
                if (selected == null) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Selecciona una notificación para ver los detalles',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // Lógica para mostrar botones de acción, reutilizada de la vista móvil
                bool showActionButtons = false;
                final String? currentUserId =
                    _authController.currentUser.value?.uid;
                final data = selected.data;

                if (selected.type ==
                        AppNotificationType.taskModificationRequest &&
                    !selected.isRead &&
                    data != null &&
                    data.containsKey('requesterId') &&
                    data.containsKey('adminUserIdForProject') &&
                    currentUserId != null &&
                    data['requesterId'] != currentUserId &&
                    (data['adminUserIdForProject'] == currentUserId ||
                        data['projectOwnerId'] == currentUserId)) {
                  showActionButtons = true;
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: GFCard(
                    boxFit: BoxFit.cover,
                    title: GFListTile(
                      padding: EdgeInsets.zero,
                      margin: EdgeInsets.zero,
                      avatar: GFAvatar(
                        backgroundColor: _getIconBackgroundColor(
                          selected.type,
                          context,
                        ).withOpacity(0.2),
                        child: Icon(
                          _iconForNotificationType(selected.type),
                          color: _getIconColor(selected.type, context),
                          size: 28,
                        ),
                      ),
                      title: Text(
                        selected.title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: !selected.isRead
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                      ),
                      subTitle: Text(
                        DateFormat(
                          'dd MMMM yyyy, HH:mm',
                          Get.locale?.toString(),
                        ).format(selected.createdAt.toDate()),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 24),
                        Text(
                          selected.body,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontSize: 18, height: 1.5),
                        ),
                        const SizedBox(height: 24),
                        if (showActionButtons)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              GFButton(
                                onPressed: () => controller
                                    .acceptTaskModificationRequest(selected),
                                text: 'Aprobar',
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                type: GFButtonType.solid,
                                shape: GFButtonShape.pills,
                                color: GFColors.SUCCESS,
                                size: GFSize.LARGE,
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 16),
                              GFButton(
                                onPressed: () => controller
                                    .rejectTaskModificationRequest(selected),
                                text: 'Rechazar',
                                icon: const Icon(
                                  Icons.cancel_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                type: GFButtonType.solid,
                                shape: GFButtonShape.pills,
                                color: GFColors.DANGER,
                                size: GFSize.LARGE,
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                        // Botón para navegar al contenido relacionado
                        if (!showActionButtons)
                          Align(
                            alignment: Alignment.bottomRight,
                            child: GFButton(
                              onPressed: () =>
                                  controller.navigateFromNotification(selected),
                              text: 'Ver Detalles',
                              icon: const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 20,
                              ),
                              type: GFButtonType.solid,
                              shape: GFButtonShape.pills,
                              size: GFSize.LARGE,
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildWatchTasksScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: Column(
            children: [
              const Text(
                'Notificaciones',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Obx(() {
                  if (controller.isLoadingNotifications.value &&
                      controller.appNotifications.isEmpty) {
                    return const Center(
                      child: GFLoader(
                        type: GFLoaderType.circle,
                        size: GFSize.SMALL,
                      ),
                    );
                  }

                  if (controller.appNotifications.isEmpty) {
                    return const Center(
                      child: Text(
                        'Sin notificaciones',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: controller.appNotifications.length,
                    itemBuilder: (context, index) {
                      final n = controller.appNotifications[index];
                      final icon = _iconForNotificationType(n.type);
                      final time = DateFormat.Hm().format(n.createdAt.toDate());

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: n.isRead ? Colors.grey[850] : Colors.grey[800],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(icon, color: Colors.white, size: 20),
                          title: Text(
                            n.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '$time · ${n.body}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => controller.navigateFromNotification(n),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForNotificationType(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.projectInvitation:
        return Icons.group_add_outlined;
      case AppNotificationType.taskAssigned:
        return Icons.assignment_ind_outlined;
      case AppNotificationType.taskCompleted:
        return Icons.check_circle_outline;
      case AppNotificationType.projectUpdate:
        return Icons.campaign_outlined;
      case AppNotificationType.pomodoroEnd:
        return Icons.timer_outlined;
      case AppNotificationType.taskModificationRequest:
        return Icons.pending_actions_outlined;
      case AppNotificationType.taskModificationApproved:
        return Icons.thumb_up_alt_outlined;
      case AppNotificationType.taskModificationRejected:
        return Icons.thumb_down_alt_outlined;
      case AppNotificationType.projectDeletionRequest:
        return Icons.delete_forever_outlined;
      case AppNotificationType.projectDeletionApproved:
        return Icons.delete_sweep_outlined;
      case AppNotificationType.projectDeletionRejected:
        return Icons.unpublished_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = Get.width;
    final isTV = screenWidth > 800 && Get.height > 500;
    final isWatch = screenWidth < 300;

    if (isWatch) {
      return _buildWatchTasksScreen(context);
    } else if (isTV) {
      return _buildTvTasksScreen(context);
    } else {
      return _buildMobileTasksScreen(context);
    }
  }

  Widget _buildNotificationItem(
    BuildContext context,
    AppNotificationModel notification,
  ) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color unreadColor = isDark
        ? Colors.blueGrey.shade700.withValues(alpha: 0.3)
        : Colors.blue.shade50.withValues(alpha: 0.8);
    final Color readColor =
        Theme.of(context).cardTheme.color ??
        (isDark ? Colors.grey.shade800 : Colors.white);

    IconData itemIcon = Icons.notifications_active_outlined;
    Color iconBgColor = Theme.of(
      context,
    ).colorScheme.primary.withValues(alpha: 0.1);
    Color iconColor = Theme.of(context).colorScheme.primary;

    switch (notification.type) {
      case AppNotificationType.projectInvitation:
        itemIcon = Icons.group_add_outlined;
        iconBgColor = Colors.purple.withValues(alpha: 0.1);
        iconColor = Colors.purple;
        break;
      case AppNotificationType.taskAssigned:
        itemIcon = Icons.assignment_ind_outlined;
        iconBgColor = Colors.cyan.withValues(alpha: 0.1);
        iconColor = Colors.cyan;
        break;
      case AppNotificationType.taskCompleted:
        itemIcon = Icons.check_circle_outline;
        iconBgColor = Colors.green.withValues(alpha: 0.1);
        iconColor = Colors.green;
        break;
      case AppNotificationType.projectUpdate:
        itemIcon = Icons.campaign_outlined;
        iconBgColor = Colors.amber.withValues(alpha: 0.15);
        iconColor = Colors.amber.shade700;
        break;
      case AppNotificationType.pomodoroEnd:
        itemIcon = Icons.timer_outlined;
        iconBgColor = Colors.redAccent.withValues(alpha: 0.1);
        iconColor = Colors.redAccent;
        break;
      case AppNotificationType.generic:
        itemIcon = Icons.info_outline;
        iconBgColor = Colors.grey.withValues(alpha: 0.15);
        iconColor = Colors.grey.shade600;
        break;
      case AppNotificationType.taskModificationRequest:
        itemIcon = Icons.pending_actions_outlined;
        iconBgColor = Colors.orange.withValues(alpha: 0.1);
        iconColor = Colors.orange.shade700;
        break;
      case AppNotificationType.taskModificationApproved:
        itemIcon = Icons.thumb_up_alt_outlined;
        iconBgColor = Colors.lightBlue.withValues(alpha: 0.1);
        iconColor = Colors.lightBlue;
        break;
      case AppNotificationType.taskModificationRejected:
        itemIcon = Icons.thumb_down_alt_outlined;
        iconBgColor = Colors.pink.withValues(alpha: 0.1);
        iconColor = Colors.pink;
        break;
      case AppNotificationType.projectDeletionRequest:
        itemIcon = Icons.delete_forever_outlined;
        iconBgColor = Colors.deepOrange.withValues(alpha: 0.1);
        iconColor = Colors.deepOrange;
        break;
      case AppNotificationType.projectDeletionApproved:
        itemIcon = Icons.delete_sweep_outlined;
        iconBgColor = Colors.black54.withValues(alpha: 0.1);
        iconColor = Colors.black87;
        break;
      case AppNotificationType.projectDeletionRejected:
        itemIcon = Icons.unpublished_outlined;
        iconBgColor = Colors.brown.withValues(alpha: 0.1);
        iconColor = Colors.brown;
        break;
    }

    bool showActionButtons = false;
    final String? currentUserId = _authController.currentUser.value?.uid;
    final data = notification.data;

    if (notification.type == AppNotificationType.taskModificationRequest &&
        !notification.isRead &&
        data != null &&
        data.containsKey('requesterId') &&
        data.containsKey('adminUserIdForProject') &&
        currentUserId != null &&
        data['requesterId'] != currentUserId &&
        (data['adminUserIdForProject'] == currentUserId ||
            data['projectOwnerId'] == currentUserId)) {
      showActionButtons = true;
    }

    return Material(
      color: notification.isRead ? readColor : unreadColor,
      child: InkWell(
        onTap: () => controller.navigateFromNotification(notification),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: iconBgColor,
                        child: Icon(itemIcon, color: iconColor, size: 24),
                      ),
                      if (!notification.isRead)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.redAccent.shade200,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    Theme.of(context).cardTheme.color ??
                                    (isDark
                                        ? Colors.grey.shade800
                                        : Colors.white),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                            fontSize: 15,
                            color: notification.isRead
                                ? (isDark ? Colors.grey[400] : Colors.grey[700])
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          style: TextStyle(
                            fontSize: 13,
                            color: notification.isRead
                                ? Colors.grey[isDark ? 500 : 600]
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat(
                            'dd MMM yyyy, HH:mm',
                            Get.locale?.toString(),
                          ).format(notification.createdAt.toDate()),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[isDark ? 500 : 600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (showActionButtons)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0, left: 56.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      GFButton(
                        onPressed: () => controller
                            .acceptTaskModificationRequest(notification),
                        text: 'Aprobar',
                        icon: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 18,
                        ),
                        type: GFButtonType.solid,
                        shape: GFButtonShape.pills,
                        color: GFColors.SUCCESS,
                        size: GFSize.SMALL,
                        textStyle: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        buttonBoxShadow: true,
                      ),
                      const SizedBox(width: 12),
                      GFButton(
                        onPressed: () => controller
                            .rejectTaskModificationRequest(notification),
                        text: 'Rechazar',
                        icon: const Icon(
                          Icons.cancel_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                        type: GFButtonType.solid,
                        shape: GFButtonShape.pills,
                        color: GFColors.DANGER,
                        size: GFSize.SMALL,
                        textStyle: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        buttonBoxShadow: true,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getIconColor(AppNotificationType type, BuildContext context) {
    // Puedes ajustar estos colores para que coincidan perfectamente con tu paleta de TV
    switch (type) {
      case AppNotificationType.projectInvitation:
        return Colors.purple.shade300;
      case AppNotificationType.taskAssigned:
        return Colors.cyan.shade300;
      case AppNotificationType.taskCompleted:
        return Colors.green.shade400;
      case AppNotificationType.projectUpdate:
        return Colors.amber.shade400;
      case AppNotificationType.pomodoroEnd:
        return Colors.red.shade400;
      case AppNotificationType.taskModificationRequest:
        return Colors.orange.shade400;
      case AppNotificationType.taskModificationApproved:
        return Colors.lightBlue.shade300;
      case AppNotificationType.taskModificationRejected:
        return Colors.pink.shade300;
      case AppNotificationType.projectDeletionRequest:
        return Colors.deepOrange.shade300;
      case AppNotificationType.projectDeletionApproved:
        return Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade400
            : Colors.black87;
      case AppNotificationType.projectDeletionRejected:
        return Colors.brown.shade300;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  // Helper para obtener el color de fondo del ícono.
  // En la UI de TV, simplemente reutilizamos el color del ícono,
  // y el widget se encarga de aplicarle opacidad.
  Color _getIconBackgroundColor(
    AppNotificationType type,
    BuildContext context,
  ) {
    return _getIconColor(type, context);
  }
}
