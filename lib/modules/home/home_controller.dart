// lib/app/modules/home/home_controller.dart
import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:focus_flow/data/services/notification_service.dart';
import 'package:get/get.dart';
import 'package:focus_flow/modules/auth/auth_controller.dart'; // Para acceder a datos del usuario
import 'package:focus_flow/data/models/user_model.dart'; // Para el tipo UserData

class HomeController extends GetxController {
  // Acceder al AuthController para obtener la información del usuario
  // AuthController ya debería estar inicializado y con datos si llegamos a Home.
  final AuthController _authController = Get.find<AuthController>();
  final NotificationService _notificationService = NotificationService.instance;
  // ignore: unused_field
  StreamSubscription<RemoteMessage>? _foregroundNotificationSubscription;

  // Observable para el nombre del usuario, para que la UI reaccione si cambia.
  final Rx<UserData?> userData = Rx<UserData?>(null);

  @override
  void onInit() {
    super.onInit();
    // Obtener los datos del usuario del AuthController
    // y suscribirse a cambios si es necesario (aunque currentUser en AuthController ya es Rx)
    userData.value = _authController.currentUser.value;

    _determineDeviceType();

    _listenToForegroundNotifications();

    // Si quieres que reaccione a cambios en el currentUser del AuthController:
    ever(_authController.currentUser, (UserData? userFromAuth) {
      userData.value = userFromAuth;
    });
  }

  void _listenToForegroundNotifications() {
    _foregroundNotificationSubscription = _notificationService.onForegroundMessageReceived.listen(
      (RemoteMessage message) {
        print("HomeController: Notificación en primer plano recibida!");
        // Extraer título y cuerpo (similar a como lo haces en NotificationService)
        String? title = message.notification?.title;
        String? body = message.notification?.body;
        final Map<String, dynamic> data = message.data;

        // Fallback a los datos si message.notification es nulo
        title ??= data['title'] as String?;
        body ??= data['body'] as String?;

        if (title != null && body != null) {
          // Determinar si hay una acción de navegación
          String? routeToNavigate = data['screen'] as String?;
          bool canNavigate =
              routeToNavigate != null && routeToNavigate.isNotEmpty;

          Get.defaultDialog(
            title: title,
            middleText: body,
            backgroundColor: Get.isDarkMode ? Colors.grey[800] : Colors.white,
            titleStyle: TextStyle(
              color: Get.isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
            middleTextStyle: TextStyle(
              color: Get.isDarkMode ? Colors.white70 : Colors.black54,
            ),
            textConfirm: canNavigate ? "VER" : "OK",
            textCancel: canNavigate
                ? "Cerrar"
                : null, // No mostrar "Cerrar" si no hay acción "VER"
            confirmTextColor: Colors.white,
            cancelTextColor: Get.isDarkMode ? Colors.white70 : Colors.black54,
            buttonColor: Get.theme.colorScheme.primary,
            onConfirm: () {
              Get.back(); // Cerrar el diálogo
              if (canNavigate) {
                // Aquí puedes llamar a un método en NotificationController para marcarla como leída
                // si es que se guarda una AppNotificationModel también para las de foreground.
                // O simplemente navegar.
                print(
                  "HomeController: Navegando desde diálogo a: $routeToNavigate con datos: ${message.data}",
                );
                Get.toNamed(routeToNavigate, arguments: message.data);
              }
            },
            onCancel: canNavigate
                ? () {
                    /* Get.back() ya se maneja por defecto */
                  }
                : null,
          );
        }
      },
      onError: (error) {
        print(
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
    // La lógica de logout y redirección está en AuthController
    _authController.logout();
  }

  final Rx<DeviceType> deviceType = DeviceType.mobile.obs;

  void _determineDeviceType() {
    final screenWidth = Get.width;
    final screenHeight = Get.height;
    final shortestSide = Get.mediaQuery.size.shortestSide;

    if (shortestSide < 300 && screenWidth < 350) {
      // Umbrales más específicos para watch
      deviceType.value = DeviceType.watch;
    } else if (shortestSide >= 600) {
      // Un umbral común para tablets/TVs pequeñas
      if (GetPlatform.isWeb ||
          GetPlatform.isDesktop ||
          (screenWidth > 800 &&
              screenHeight >
                  500 /*o alguna API específica de TV si usas un plugin para ello*/ )) {
        deviceType.value = DeviceType
            .tv; // Asumiendo que TV se detecta por tamaño grande o plataforma
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
