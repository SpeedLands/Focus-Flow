import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class HttpService {
  static const _scope = ['https://www.googleapis.com/auth/firebase.messaging'];
  static const _serviceAccountPath = 'assets/serviceAccountKey.json';

  Future<String> getAccessToken() async {
    try {
      final jsonKey = await rootBundle.loadString(_serviceAccountPath);
      final credentials = ServiceAccountCredentials.fromJson(
        json.decode(jsonKey),
      );
      final client = http.Client();

      try {
        final accessCredentials =
            await obtainAccessCredentialsViaServiceAccount(
              credentials,
              _scope,
              client,
            );
        return accessCredentials.accessToken.data;
      } catch (e) {
        debugPrint('❌ Error obteniendo token FCM: $e');
        return '';
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('❌ Error cargando serviceAccountKey.json: $e');
      return '';
    }
  }

  Future<bool> sendFcmRequest({
    required Map<String, dynamic> body,
    required String accessToken,
    required String projectId,
  }) async {
    final url = Uri.parse(
      'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Notificación enviada: ${response.body}');
        return true;
      } else {
        debugPrint(
          '⚠️ Falla al enviar: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ Excepción al enviar FCM: $e');
      return false;
    }
  }

  Future<bool> sendNotificationToDevice({
    required String targetDeviceToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    required String accessToken,
    required String projectId,
  }) async {
    final message = {
      'message': {
        'token': targetDeviceToken,
        'notification': {'title': title, 'body': body},
        if (data != null) 'data': data,
        'android': {
          'priority': 'high',
          'notification': {
            'sound': 'default',
            "icon": "ic_stat_notification",
            'channel_id': 'high_importance_channel',
          },
        },
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

    return await sendFcmRequest(
      body: message,
      accessToken: accessToken,
      projectId: projectId,
    );
  }
}
