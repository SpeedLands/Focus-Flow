import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class MessagingService {
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  final String? vapidKey = (kIsWeb)
      ? 'BL65ppqoGPtjysI0oq2oenSLny_yUfYAcBE3Ww9Bo9HW3fTzPlBBpahW4dGJQXNSFIQEO9zmI6fA2bVaQFU2-Yk'
      : null;

  Future<String> getToken() async {
    String? token = await firebaseMessaging.getToken(vapidKey: vapidKey);
    return token!;
  }

  Future<void> requestPermission() async {
    try {
      NotificationSettings settings = await firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('Permiso de notificación FCM otorgado por el usuario.');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint(
          'Permiso de notificación FCM provisional otorgado por el usuario.',
        );
      } else {
        debugPrint(
          'El usuario ha rechazado o no ha aceptado el permiso de notificación FCM.',
        );
      }
    } catch (e) {
      debugPrint("Error solicitando permisos de notificación: $e");
    }
  }

  void setupMessageHandlers() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {});

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {});
    if (defaultTargetPlatform != TargetPlatform.windows) {
      firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {}
      });
    }

    // FirebaseMessaging.onBackgroundMessage();
  }

  Future<void> _handleReceivedFcmMessage(
    RemoteMessage message, {
    bool isBackgroundOpen = false,
    bool isTerminatedOpen = false,
  }) async {
    final Map<String, dynamic> data = message.data;
    String? routeToNavigate = data['screen'] as String?;

    if ((isBackgroundOpen || isTerminatedOpen) && routeToNavigate != null) {
      debugPrint(
        "_handleReceivedFcmMessage: Navegando a $routeToNavigate con datos: $data",
      );
      // setNavigatingFromNotification(true);
      await Future.delayed(const Duration(milliseconds: 600));
      // Get.toNamed(routeToNavigate, arguments: data);
      Future.delayed(const Duration(seconds: 3), () {
        // setNavigatingFromNotification(false);
      });
    }
  }
}
