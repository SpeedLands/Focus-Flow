import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    await createNotificationChannel();

    tz.initializeTimeZones();
  }

  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    debugPrint('Payload recibido: $payload');
    if (response.actionId == 'accept') {
      debugPrint('aceptar $response');
    } else if (response.actionId == 'decline') {
    } else {}
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
        if (type == 'project_invitation') {}
      }
    } else if (actionId == 'decline') {
      debugPrint('🔴 Acción en BG: Rechazar');
      if (payload != null) {
        final data = jsonDecode(response.payload!);
        final type = data['type'];
        if (type == 'project_invitation') {}
      }
    } else {
      debugPrint('🟡 Acción en BG: Tap sin botón');
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
      'high_importance_channel',
      'Notificaciones importantes',
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
