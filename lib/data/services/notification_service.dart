import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, debugPrint;
import 'package:flutter/services.dart';
import 'package:focus_flow/data/models/app_notification_model.dart';
import 'package:focus_flow/modules/auth/auth_controller.dart';
import 'package:get/get.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('HANDLING A BACKGROUND MESSAGE: ${message.messageId}');
  debugPrint('  Título: ${message.notification?.title}');
  debugPrint('  Cuerpo: ${message.notification?.body}');
  debugPrint('  Datos: ${message.data}');
}

class NotificationService {
  final RxBool _isNavigatingFromNotification = false.obs;
  bool get isNavigatingFromNotification => _isNavigatingFromNotification.value;
  void setNavigatingFromNotification(bool value) {
    _isNavigatingFromNotification.value = value;
  }

  NotificationService._privateConstructor();
  static final NotificationService _instance =
      NotificationService._privateConstructor();
  static NotificationService get instance => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final String projectId = 'focusflow-acd29';
  final String? vapidKey =
      (kIsWeb || defaultTargetPlatform == TargetPlatform.windows)
      ? 'BL65ppqoGPtjysI0oq2oenSLny_yUfYAcBE3Ww9Bo9HW3fTzPlBBpahW4dGJQXNSFIQEO9zmI6fA2bVaQFU2-Yk'
      : null;

  String _accessToken = '';
  String? _deviceToken;
  bool _isInitialized = false;

  final StreamController<String?> _deviceTokenStreamController =
      StreamController<String?>.broadcast();
  Stream<String?> get onDeviceTokenChanged =>
      _deviceTokenStreamController.stream;
  String? get currentDeviceToken => _deviceToken;

  final StreamController<RemoteMessage> _messageLogStreamController =
      StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onMessageReceivedForLog =>
      _messageLogStreamController.stream;

  final StreamController<RemoteMessage> _foregroundMessageStreamController =
      StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onForegroundMessageReceived =>
      _foregroundMessageStreamController.stream;

  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint("NotificationService ya está inicializado.");
      return;
    }

    await _requestPermissions();
    await _configureTokenHandling();
    _setupMessageHandlers();

    _isInitialized = true;
    debugPrint("NotificationService inicializado exitosamente.");
  }

  Future<void> _requestPermissions() async {
    debugPrint("Solicitando permisos de notificación...");
    try {
      NotificationSettings settings = await _messaging.requestPermission(
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

  Future<void> _configureTokenHandling() async {
    debugPrint("Configurando manejo de token FCM...");
    try {
      String? token = await _messaging.getToken(vapidKey: vapidKey);
      if (token != null) {
        if (_deviceToken != token) {
          _deviceToken = token;
          _deviceTokenStreamController.add(_deviceToken);
          debugPrint("Token FCM del dispositivo obtenido: $_deviceToken");
          _saveTokenToFirestore(_deviceToken);
        }
        debugPrint("Token FCM del dispositivo no ha cambiado: $_deviceToken");
      } else {
        _deviceTokenStreamController.add(null);
        debugPrint("Error: No se pudo obtener el token FCM del dispositivo.");
      }

      _messaging.onTokenRefresh
          .listen((newToken) async {
            if (_deviceToken != newToken) {
              debugPrint("Token FCM del dispositivo refrescado: $newToken");
              _deviceToken = newToken;
              _deviceTokenStreamController.add(_deviceToken);
              _saveTokenToFirestore(_deviceToken);
            }
          })
          .onError((error) {
            debugPrint("Error en onTokenRefresh: $error");
            _deviceTokenStreamController.add(null);
          });
    } catch (e) {
      debugPrint("Error configurando el manejo de token FCM: $e");
      _deviceTokenStreamController.add(null);
    }
  }

  Future<void> _saveTokenToFirestore(String? token) async {
    if (token == null || token.isEmpty) return;

    try {
      if (Get.isRegistered<AuthController>()) {
        final authController = Get.find<AuthController>();
        if (authController.isAuthenticated.value) {
          debugPrint(
            "NotificationService: Usuario autenticado, intentando guardar token: $token",
          );
          await authController.updateUserDeviceToken(token);
        } else {
          debugPrint(
            "NotificationService: Usuario no autenticado, token $token se guardará después del login.",
          );
        }
      } else {
        debugPrint(
          "NotificationService: AuthController no está registrado aún. Token $token se guardará después del login.",
        );
      }
    } catch (e) {
      debugPrint(
        "NotificationService: Excepción al intentar acceder a AuthController para guardar token: $e",
      );
    }
  }

  Future<void> uploadCurrentDeviceTokenIfAvailable() async {
    if (_deviceToken != null && _deviceToken!.isNotEmpty) {
      debugPrint(
        "NotificationService: Intentando subir token existente '$_deviceToken' después del login/auth_change.",
      );
      await _saveTokenToFirestore(_deviceToken);
    } else {
      debugPrint(
        "NotificationService: No hay token de dispositivo actual para subir post-login.",
      );
    }
  }

  Future<void> _handleReceivedFcmMessage(
    RemoteMessage message, {
    bool isForeground = false,
    bool isBackgroundOpen = false,
    bool isTerminatedOpen = false,
  }) async {
    final Map<String, dynamic> data = message.data;
    debugPrint(
      "_handleReceivedFcmMessage: Procesando mensajeId: ${message.messageId}, datos: $data",
    );

    String? title = message.notification?.title;
    String? body = message.notification?.body;

    if (isForeground && (title == null || body == null)) {
      title = data['title'] as String? ?? title;
      body = data['body'] as String? ?? body;
    }
    title ??= data['title'] as String?;
    body ??= data['body'] as String?;

    final String? notificationType = data['type'] as String?;

    if (notificationType == null || title == null || body == null) {
      debugPrint(
        "_handleReceivedFcmMessage: Datos incompletos (type, title, o body es null). Type: $notificationType, Title: $title, Body: $body",
      );
      if (isForeground) {
        debugPrint(
          "  (Para notificaciones en primer plano, asegúrate de que 'title' y 'body' estén en el payload 'data' si message.notification es nulo)",
        );
      }
      return;
    }

    if (!Get.isRegistered<AuthController>()) {
      debugPrint(
        "_handleReceivedFcmMessage: AuthController no registrado. No se puede guardar AppNotificationModel.",
      );
      return;
    }
    final AuthController authController = Get.find<AuthController>();

    if (!authController.isAuthenticated.value ||
        authController.currentUser.value == null) {
      debugPrint(
        "_handleReceivedFcmMessage: Usuario no autenticado. No se puede guardar AppNotificationModel.",
      );
      return;
    }

    final String currentUserId = authController.currentUser.value!.uid;
    AppNotificationType appNotifType = AppNotificationType.generic;
    String? routeToNavigate = data['screen'] as String?;
    String? iconName;

    switch (notificationType) {
      case 'project_invitation':
        appNotifType = AppNotificationType.projectInvitation;
        iconName = 'mail_outline';
        break;
      case 'task_event':
        appNotifType = AppNotificationType.projectUpdate;
        iconName = 'task_alt';
        break;
      default:
        appNotifType = AppNotificationType.generic;
        iconName = 'notifications';
    }

    try {
      debugPrint(
        "_handleReceivedFcmMessage: AppNotificationModel guardada en Firestore para $currentUserId.",
      );
    } catch (e) {
      debugPrint(
        "_handleReceivedFcmMessage: Error al guardar AppNotificationModel en Firestore: $e",
      );
    }

    if ((isBackgroundOpen || isTerminatedOpen) && routeToNavigate != null) {
      debugPrint(
        "_handleReceivedFcmMessage: Navegando a $routeToNavigate con datos: $data",
      );
      setNavigatingFromNotification(true);
      await Future.delayed(const Duration(milliseconds: 600));
      Get.toNamed(routeToNavigate, arguments: data);
      Future.delayed(const Duration(seconds: 3), () {
        setNavigatingFromNotification(false);
      });
    }
  }

  void _setupMessageHandlers() {
    debugPrint("Configurando manejadores de mensajes FCM...");

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Mensaje FCM recibido en primer plano:");
      debugPrint("  Título: ${message.notification?.title}");
      debugPrint("  Cuerpo: ${message.notification?.body}");
      debugPrint("  Datos: ${message.data}");

      _messageLogStreamController.add(message);
      _foregroundMessageStreamController.add(message);

      _handleReceivedFcmMessage(message, isForeground: true);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("Mensaje FCM abierto (app en background):");
      _messageLogStreamController.add(message);
      _handleReceivedFcmMessage(message, isBackgroundOpen: true);
    });

    if (defaultTargetPlatform != TargetPlatform.windows) {
      _messaging.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          debugPrint("Mensaje FCM inicial que abrió la app (app terminada):");
          _messageLogStreamController.add(message);
          _handleReceivedFcmMessage(message, isTerminatedOpen: true);
        }
      });
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<bool> sendNotificationToDevice({
    required String targetDeviceToken,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    if (!_isInitialized) {
      debugPrint("Error: NotificationService no está inicializado.");
      return false;
    }
    if (targetDeviceToken.isEmpty) {
      debugPrint("Error: El token del dispositivo destino está vacío.");
      return false;
    }
    if (projectId.isEmpty) {
      debugPrint("Error: projectId está vacío en NotificationService.");
      return false;
    }

    debugPrint("Intentando enviar notificación a $targetDeviceToken...");
    await _getAccessToken();

    if (_accessToken.isEmpty) {
      debugPrint(
        "Error: No se pudo obtener el AccessToken para enviar la notificación.",
      );
      return false;
    }

    final Map<String, dynamic> messagePayload = {
      'message': {
        'token': targetDeviceToken,
        'notification': {'title': title, 'body': body},
        if (data != null) 'data': data,
        'android': {},
        'apns': {
          'payload': {
            'aps': {
              'alert': {'title': title, 'body': body},
              'sound': 'default',
            },
          },
        },
        'webpush': {
          'notification': {'title': title, 'body': body},
          if (data != null) 'data': data,
        },
      },
    };

    return await _sendFcmRequest(messagePayload);
  }

  Future<void> _getAccessToken() async {
    debugPrint("Obteniendo AccessToken para la API de FCM...");
    try {
      final serviceAccountJsonString = await rootBundle.loadString(
        'assets/serviceAccountKey.json',
      );
      final Map<String, dynamic> serviceAccountData = json.decode(
        serviceAccountJsonString,
      );

      if (serviceAccountData['project_id'] != projectId) {
        debugPrint(
          "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",
        );
        debugPrint(
          "!! ALERTA DE CONFIGURACIÓN INCORRECTA EN NotificationService !!",
        );
        debugPrint(
          "!! El 'project_id' en serviceAccountKey.json ('${serviceAccountData['project_id']}')",
        );
        debugPrint(
          "!! NO COINCIDE con el 'projectId' definido en el código ('$projectId').",
        );
        debugPrint(
          "!! Las notificaciones FALLARÁN. Asegúrate de que AMBOS sean del MISMO proyecto Firebase.",
        );
        debugPrint(
          "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",
        );
        _accessToken = '';
        return;
      }

      final accountCredentials = ServiceAccountCredentials.fromJson(
        serviceAccountData,
      );
      const scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = http.Client();

      try {
        final accessCredentials =
            await obtainAccessCredentialsViaServiceAccount(
              accountCredentials,
              scopes,
              client,
            );
        _accessToken = accessCredentials.accessToken.data;
        debugPrint('AccessToken obtenido exitosamente.');
      } catch (e) {
        debugPrint('Error obteniendo AccessToken vía ServiceAccount: $e');
        _accessToken = '';
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('Error cargando o parseando serviceAccountKey.json: $e');
      _accessToken = '';
    }
  }

  Future<bool> _sendFcmRequest(Map<String, dynamic> body) async {
    final String url =
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';
    debugPrint("Enviando solicitud FCM a: $url");
    debugPrint("Payload: ${json.encode(body)}");

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        debugPrint('Solicitud FCM exitosa. Respuesta: ${response.body}');
        return true;
      } else {
        debugPrint('Error en la solicitud FCM: ${response.statusCode}');
        debugPrint('Cuerpo de la respuesta FCM: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Excepción al enviar la solicitud FCM: $e');
      return false;
    }
  }
}
