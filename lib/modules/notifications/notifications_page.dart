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
    return const Scaffold();
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
}
