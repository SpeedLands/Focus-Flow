import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:focus_flow/data/services/notifications_service.dart';

Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  final notification = message.notification;
  if (notification != null) {
    await NotificationsService().showNotificationWithActions(
      title: notification.title ?? 'Notificación',
      body: notification.body ?? '',
      channelId: 'general_background',
      channelName: 'Mensajes en segundo plano',
      channelDescription: 'Notificaciones recibidas en segundo plano',
    );
  }
}

class MessagingService {
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  final String? vapidKey = (kIsWeb)
      ? 'BL65ppqoGPtjysI0oq2oenSLny_yUfYAcBE3Ww9Bo9HW3fTzPlBBpahW4dGJQXNSFIQEO9zmI6fA2bVaQFU2-Yk'
      : null;

  Future<String?> getToken() async {
    try {
      return await firebaseMessaging.getToken(vapidKey: vapidKey);
    } catch (e) {
      debugPrint('Error obteniendo token FCM: $e');
      return null;
    }
  }

  Future<void> requestPermission() async {
    try {
      final NotificationSettings settings = await firebaseMessaging
          .requestPermission(alert: true, badge: true, sound: true);

      switch (settings.authorizationStatus) {
        case AuthorizationStatus.authorized:
          debugPrint('✅ Permiso FCM autorizado');
          break;
        case AuthorizationStatus.provisional:
          debugPrint('⚠️ Permiso FCM provisional otorgado');
          break;
        case AuthorizationStatus.denied:
          debugPrint('❌ Permiso FCM denegado');
          break;
        default:
          debugPrint('🔍 Estado de permiso FCM desconocido');
      }
    } catch (e) {
      debugPrint('Error solicitando permiso FCM: $e');
    }
  }

  void setupMessageHandlers() {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message, isBackgroundOpen: true);
    });

    firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleNotificationTap(message, isTerminatedOpen: true);
      }
    });

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      final type = data['type'] as String?;
      final payload = jsonEncode(data);

      if (type == 'project_invitation') {
        // Mostrar con botones
        NotificationsService().showNotificationWithActions(
          title: notification.title ?? 'Notificación',
          body: notification.body ?? '',
          channelId: 'general_foreground',
          channelName: 'Mensajes en foreground',
          channelDescription:
              'Notificaciones recibidas mientras la app está activa',
          payload: payload,
        );
      } else {
        // Mostrar sin botones
        NotificationsService().showBasicNotification(
          title: notification.title ?? 'Notificación',
          body: notification.body ?? '',
          channelId: 'general_foreground',
          channelName: 'Mensajes en foreground',
          channelDescription:
              'Notificaciones recibidas mientras la app está activa',
          payload: payload,
        );
      }
    }
  }

  Future<void> _handleNotificationTap(
    RemoteMessage message, {
    bool isBackgroundOpen = false,
    bool isTerminatedOpen = false,
  }) async {
    final data = message.data;
    final String? screen = data['screen'] as String?;
    if (screen != null) {
      debugPrint('📲 Navegando a $screen con datos: $data');
      await Future<void>.delayed(const Duration(milliseconds: 600));
      // Aquí deberías hacer la navegación real con tu sistema de rutas (ej: Get.toNamed)
    }
  }
}
