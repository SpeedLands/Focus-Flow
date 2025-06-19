import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class HttpService {
  Future<String> getAccessToken() async {
    try {
      final serviceAccountJsonString = await rootBundle.loadString(
        'assets/serviceAccountKey.json',
      );
      final Map<String, dynamic> serviceAccountData = json.decode(
        serviceAccountJsonString,
      );
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
        String accessToken = accessCredentials.accessToken.data;
        return accessToken;
      } catch (e) {
        debugPrint('Error obteniendo AccessToken vía ServiceAccount: $e');
        return '';
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('Error cargando o parseando serviceAccountKey.json: $e');
      return '';
    }
  }

  Future<bool> sendFcmRequest(
    Map<String, dynamic> body,
    String projectId,
    String accessToken,
  ) async {
    final String url =
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Excepción al enviar la solicitud FCM: $e');
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

    return await sendFcmRequest(messagePayload, projectId, accessToken);
  }
}
