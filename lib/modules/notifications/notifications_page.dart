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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notificaciones"),
        actions: [
          Obx(
            () => controller.unreadNotificationCount.value > 0
                ? TextButton(
                    onPressed: controller.markAllAsRead,
                    child: Text(
                      "Marcar Todas Leídas",
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
                  "No tienes notificaciones",
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
                      "Eliminar",
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
                        text: "Aprobar",
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
                        text: "Rechazar",
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
