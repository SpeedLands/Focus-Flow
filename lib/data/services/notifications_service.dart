import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:focus_flow/data/providers/auth_app_provider.dart';
// import 'package:focus_flow/data/providers/notification_provider.dart';
// import 'package:focus_flow/data/providers/project_invitation_provider.dart';
// import 'package:focus_flow/data/providers/project_provider.dart';
// import 'package:focus_flow/data/providers/task_provider.dart';
// import 'package:focus_flow/data/services/auth_service.dart';
// import 'package:focus_flow/data/services/firestore_service.dart';
// import 'package:focus_flow/data/services/http_service.dart';
// import 'package:focus_flow/data/services/messaging_service.dart';
// import 'package:focus_flow/modules/projects/project_controller.dart';
// import 'package:get/get.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  NotificationsService().handleBackgroundAction(response);
}

class NotificationsService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final NotificationsService _instance =
      NotificationsService._internal();
  factory NotificationsService() => _instance;
  NotificationsService._internal();

  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@drawable/ic_stat_notification');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    await createNotificationChannel();

    tz.initializeTimeZones(); // Necesario para programación
  }

  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    debugPrint('Payload recibido: $payload');
    // Manejar aquí la lógica de botones o redirecciones
    if (response.actionId == 'accept') {
      // lógica para aceptar invitación
      debugPrint('aceptar $response');
    } else if (response.actionId == 'decline') {
      // lógica para rechazar invitación
    } else {
      // acción por defecto (tap)
    }
  }

  void handleBackgroundAction(NotificationResponse response) {
    final actionId = response.actionId;
    final payload = response.payload;

    if (actionId == 'accept') {
      debugPrint('🔵 Acción en BG: Aceptar');
      debugPrint('Payload recibido: $payload');
      if (payload != null) {
        final data = jsonDecode(response.payload!);
        final type = data['type'];
        if (type == 'project_invitation') {
          // final projectId = data['projectId'];
          // final invitationId = data['invitationId'];
          // final projectName = data['projectName'];
          // final invitedBy = data['invitedBy'];

          // final authService = AuthService();
          // final firestore = FirestoreService();
          // final httpService = HttpService();
          // final messagingService = MessagingService();
          // final notification = NotificationProvider(
          //   firestore,
          //   httpService,
          //   messagingService,
          // );
          // final auth = AuthProviderApp(
          //   authService,
          //   firestore,
          //   notification,
          // ); // <- también sin Get

          // final projectInvitationProvider = ProjectInvitationProvider(
          //   firestore,
          //   auth,
          //   notification,
          // );

          // projectInvitationProvider.acceptInvitation(invitationId);
        }
      }
      // Ejecutar lógica para aceptar
    } else if (actionId == 'decline') {
      debugPrint('🔴 Acción en BG: Rechazar');
      if (payload != null) {
        final data = jsonDecode(response.payload!);
        final type = data['type'];
        if (type == 'project_invitation') {
          // final projectId = data['projectId'];
          // final invitationId = data['invitationId'];
          // final projectName = data['projectName'];
          // final invitedBy = data['invitedBy'];
          // final authService = AuthService();
          // final firestore = FirestoreService();
          // final httpService = HttpService();
          // final messagingService = MessagingService();
          // final notification = NotificationProvider(
          //   firestore,
          //   httpService,
          //   messagingService,
          // );
          // final auth = AuthProviderApp(
          //   authService,
          //   firestore,
          //   notification,
          // ); // <- también sin Get

          // final projectInvitationProvider = ProjectInvitationProvider(
          //   firestore,
          //   auth,
          //   notification,
          // );

          // projectInvitationProvider.declineInvitation(invitationId);
        }
      }
      // Ejecutar lógica para rechazar
    } else {
      debugPrint('🟡 Acción en BG: Tap sin botón');
      // Acción default
    }
  }

  NotificationDetails _buildNotificationDetails({
    required String channelId,
    required String channelName,
    required String channelDescription,
    List<AndroidNotificationAction>? actions,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        actions: actions,
      ),
    );
  }

  Future<void> showBasicNotification({
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    required String channelDescription,
    String? payload,
  }) async {
    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      _buildNotificationDetails(
        channelId: channelId,
        channelName: channelName,
        channelDescription: channelDescription,
      ),
      payload: payload,
    );
  }

  Future<void> showNotificationWithActions({
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    required String channelDescription,
    String? payload,
  }) async {
    final actions = [
      const AndroidNotificationAction('accept', 'Aceptar'),
      const AndroidNotificationAction('decline', 'Rechazar'),
    ];

    await _flutterLocalNotificationsPlugin.show(
      1,
      title,
      body,
      _buildNotificationDetails(
        channelId: channelId,
        channelName: channelName,
        channelDescription: channelDescription,
        actions: actions,
      ),
      payload: payload,
    );
  }

  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String channelId,
    required String channelName,
    required String channelDescription,
    String? payload,
  }) async {
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      2,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      _buildNotificationDetails(
        channelId: channelId,
        channelName: channelName,
        channelDescription: channelDescription,
      ),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // ID del canal
      'Notificaciones importantes', // Nombre visible
      description: 'Este canal se usa para notificaciones críticas',
      importance: Importance.max,
    );

    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(channel);
  }
}
