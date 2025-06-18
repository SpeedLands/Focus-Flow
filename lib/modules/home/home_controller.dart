import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:focus_flow/data/services/notification_service.dart';
import 'package:get/get.dart';
import 'package:focus_flow/modules/auth/auth_controller.dart';
import 'package:focus_flow/data/models/user_model.dart';

class HomeController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final NotificationService _notificationService = NotificationService.instance;
  StreamSubscription<RemoteMessage>? _foregroundNotificationSubscription;

  final Rx<UserData?> userData = Rx<UserData?>(null);

  @override
  void onInit() {
    super.onInit();
    userData.value = _authController.currentUser.value;

    _determineDeviceType();

    _listenToForegroundNotifications();

    ever(_authController.currentUser, (UserData? userFromAuth) {
      userData.value = userFromAuth;
    });
  }

  void _listenToForegroundNotifications() {
    _foregroundNotificationSubscription = _notificationService
        .onForegroundMessageReceived
        .listen(
          (RemoteMessage message) {
            debugPrint(
              "HomeController: Notificación en primer plano recibida!",
            );
            String? title = message.notification?.title;
            String? body = message.notification?.body;
            final Map<String, dynamic> data = message.data;

            title ??= data['title'] as String?;
            body ??= data['body'] as String?;

            if (title != null && body != null) {
              String? routeToNavigate = data['screen'] as String?;
              bool canNavigate =
                  routeToNavigate != null && routeToNavigate.isNotEmpty;

              Get.defaultDialog(
                title: title,
                middleText: body,
                backgroundColor: Get.isDarkMode
                    ? Colors.grey[800]
                    : Colors.white,
                titleStyle: TextStyle(
                  color: Get.isDarkMode ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
                middleTextStyle: TextStyle(
                  color: Get.isDarkMode ? Colors.white70 : Colors.black54,
                ),
                textConfirm: canNavigate ? "VER" : "OK",
                textCancel: canNavigate ? "Cerrar" : null,
                confirmTextColor: Colors.white,
                cancelTextColor: Get.isDarkMode
                    ? Colors.white70
                    : Colors.black54,
                buttonColor: Get.theme.colorScheme.primary,
                onConfirm: () {
                  Get.back();
                  if (canNavigate) {
                    debugPrint(
                      "HomeController: Navegando desde diálogo a: $routeToNavigate con datos: ${message.data}",
                    );
                    Get.toNamed(routeToNavigate, arguments: message.data);
                  }
                },
                onCancel: canNavigate ? () {} : null,
              );
            }
          },
          onError: (error) {
            debugPrint(
              "HomeController: Error en el stream de notificaciones en primer plano: $error",
            );
          },
        );
  }

  String get greeting {
    if (userData.value != null && userData.value!.name!.isNotEmpty) {
      return "¡Hola, ${userData.value!.name}!";
    }
    return "¡Bienvenido a FocusFlow!";
  }

  void logout() {
    _authController.logout();
  }

  final Rx<DeviceType> deviceType = DeviceType.mobile.obs;

  void _determineDeviceType() {
    final screenWidth = Get.width;
    final screenHeight = Get.height;
    final shortestSide = Get.mediaQuery.size.shortestSide;

    if (shortestSide < 300 && screenWidth < 350) {
      deviceType.value = DeviceType.watch;
    } else if (shortestSide >= 600) {
      if (GetPlatform.isWeb ||
          GetPlatform.isDesktop ||
          (screenWidth > 800 && screenHeight > 500)) {
        deviceType.value = DeviceType.tv;
      } else {
        deviceType.value = DeviceType.tablet;
      }
    } else {
      deviceType.value = DeviceType.mobile;
    }
    debugPrint("Detected device type: ${deviceType.value}");
  }
}

enum DeviceType { mobile, tablet, tv, watch }
