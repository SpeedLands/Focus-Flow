import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_messaging/firebase_messaging.dart";
import "package:flutter/material.dart";
import "package:focus_flow/data/models/app_notification_model.dart";
import "package:focus_flow/data/models/user_model.dart";
import "package:focus_flow/data/services/firestore_service.dart";
import "package:focus_flow/data/services/messaging_service.dart";
import "package:focus_flow/data/services/http_service.dart";

class NotificationProvider {
  final FirestoreService _firestoreService;
  final MessagingService _messagingService;
  final HttpService _httpService;

  NotificationProvider(
    this._firestoreService,
    this._httpService,
    this._messagingService,
  );

  final parentCollectionName = "users";
  final subCollectionName = "notifications";
  final fcmTokensField = 'fcmTokens';
  final emailField = 'email';
  final lastTokenUpdateField = 'lastTokenUpdate';
  final projectId = 'focusflow-acd29';
  bool isNavigatingFromNotification = false;

  Future<String?> getDeviceFcmToken() async {
    return _messagingService.getToken();
  }

  Future<bool> saveDeviceFcmTokenForUser(String userId) async {
    if (userId.isEmpty) {
      debugPrint(
        "Error en saveDeviceFcmTokenForUser: userId no puede estar vacío.",
      );
      return false;
    }

    try {
      final String? deviceToken = await getDeviceFcmToken();

      if (deviceToken == null || deviceToken.isEmpty) {
        debugPrint(
          "Error en saveDeviceFcmTokenForUser: No se pudo obtener el token FCM del dispositivo.",
        );
        return false;
      }

      final Map<String, dynamic> updateData = {
        fcmTokensField: FieldValue.arrayUnion([deviceToken]),
        lastTokenUpdateField: FieldValue.serverTimestamp(),
      };

      await _firestoreService.updateDocument(
        parentCollectionName,
        userId,
        updateData,
      );

      debugPrint(
        "Token FCM '$deviceToken' y lastTokenUpdate guardados/actualizados para el usuario '$userId'.",
      );
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        debugPrint(
          "Error en saveDeviceFcmTokenForUser: Usuario '$userId' no encontrado. No se pudo actualizar el documento.",
        );
      } else {
        debugPrint(
          "Error de Firebase al guardar el token FCM para '$userId': ${e.message} (Código: ${e.code})",
        );
      }
      return false;
    } catch (e, stackTrace) {
      debugPrint(
        "Error inesperado al guardar el token FCM para '$userId': $e\nStackTrace: $stackTrace",
      );
      return false;
    }
  }

  Future<bool> removeFcmTokenForUser(
    String userId,
    String tokenToRemove,
  ) async {
    if (userId.isEmpty || tokenToRemove.isEmpty) {
      debugPrint(
        "Error en removeFcmTokenForUser: userId o tokenToRemove no pueden estar vacíos.",
      );
      return false;
    }
    try {
      final Map<String, dynamic> updateData = {
        fcmTokensField: FieldValue.arrayRemove([tokenToRemove]),
        lastTokenUpdateField: FieldValue.serverTimestamp(),
      };
      await _firestoreService.updateDocument(
        parentCollectionName,
        userId,
        updateData,
      );
      debugPrint(
        "Token FCM '$tokenToRemove' eliminado y lastTokenUpdate actualizado para el usuario '$userId'.",
      );
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        debugPrint(
          "Advertencia en removeFcmTokenForUser: Usuario '$userId' no encontrado.",
        );
      } else {
        debugPrint(
          "Error de Firebase al eliminar el token FCM para '$userId': ${e.message} (Código: ${e.code})",
        );
      }
      return false;
    } catch (e, stackTrace) {
      debugPrint(
        "Error inesperado al eliminar el token FCM para '$userId': $e\nStackTrace: $stackTrace",
      );
      return false;
    }
  }

  Future<bool> removeCurrentDeviceFcmTokenForUser(String userId) async {
    if (userId.isEmpty) {
      debugPrint(
        "Error en removeCurrentDeviceFcmTokenForUser: userId no puede estar vacío.",
      );
      return false;
    }
    try {
      final String? deviceToken = await getDeviceFcmToken();
      if (deviceToken == null || deviceToken.isEmpty) {
        debugPrint(
          "No se pudo obtener el token del dispositivo actual para eliminarlo (usuario '$userId').",
        );
        return true;
      }
      return await removeFcmTokenForUser(userId, deviceToken);
    } catch (e, stackTrace) {
      debugPrint(
        "Error inesperado al obtener el token del dispositivo para eliminarlo (usuario '$userId'): $e\nStackTrace: $stackTrace",
      );
      return false;
    }
  }

  Future<bool> sendNotificationToDevice({
    required String targetDeviceToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (targetDeviceToken.isEmpty) {
      debugPrint(
        "Error: targetDeviceToken no puede estar vacío para sendNotificationToDevice.",
      );
      return false;
    }
    if (title.isEmpty || body.isEmpty) {
      debugPrint(
        "Error: El título y el cuerpo no pueden estar vacíos para sendNotificationToDevice.",
      );
      return false;
    }

    try {
      final String? accessToken = await _httpService.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        debugPrint(
          "Error enviando notificación: No se pudo obtener el AccessToken de FCM.",
        );
        return false;
      }

      final bool success = await _httpService.sendNotificationToDevice(
        targetDeviceToken: targetDeviceToken,
        title: title,
        body: body,
        data: data,
        accessToken: accessToken,
        projectId: projectId,
      );

      if (success) {
        debugPrint(
          "Notificación enviada exitosamente al token: $targetDeviceToken",
        );
      } else {
        debugPrint(
          "Falló el envío de la notificación al token: $targetDeviceToken (HttpService reportó fallo).",
        );
      }
      return success;
    } catch (e, stackTrace) {
      debugPrint(
        "Error excepcional en NotificationProvider.sendNotificationToDevice: $e\nStackTrace: $stackTrace",
      );
      return false;
    }
  }

  Future<void> addUserNotification(
    String userId,
    AppNotificationModel notification,
  ) async {
    try {
      await _firestoreService.addDocumentToSubcollection(
        parentCollectionName: parentCollectionName,
        subCollectionName: subCollectionName,
        documentId: userId,
        data: notification.toJson(),
      );
    } catch (e) {
      debugPrint("Error guardando AppNotification para $userId: $e");
    }
  }

  Future<List<String>?> getUserFcmTokens(String memberId) async {
    const String fcmTokensField = 'fcmTokens';

    if (memberId.isEmpty) {
      debugPrint("Error: memberId no puede estar vacío.");
      return null;
    }

    try {
      final DocumentSnapshot? userDoc = await _firestoreService.getDocument(
        parentCollectionName,
        memberId,
      );

      if (userDoc == null || !userDoc.exists) {
        debugPrint(
          "Usuario con ID '$memberId' no encontrado en la colección '$parentCollectionName'.",
        );
        return [];
      }

      final data = userDoc.data() as Map<String, dynamic>?;

      if (data == null || !data.containsKey(fcmTokensField)) {
        debugPrint(
          "El documento del usuario '$memberId' no contiene el campo '$fcmTokensField' o no tiene datos.",
        );
        return [];
      }

      final dynamic fcmTokensData = data[fcmTokensField];

      if (fcmTokensData is List) {
        final List<String> fcmTokens = fcmTokensData
            .whereType<String>()
            .toList();

        if (fcmTokens.length != fcmTokensData.length) {
          debugPrint(
            "Advertencia: Algunos elementos en '$fcmTokensField' para el usuario '$memberId' no eran strings y fueron omitidos.",
          );
        }
        return fcmTokens;
      } else if (fcmTokensData == null) {
        debugPrint(
          "El campo '$fcmTokensField' para el usuario '$memberId' es nulo.",
        );
        return [];
      } else {
        debugPrint(
          "El campo '$fcmTokensField' para el usuario '$memberId' no es una lista. Tipo encontrado: ${fcmTokensData.runtimeType}",
        );
        return [];
      }
    } on FirebaseException catch (e, stackTrace) {
      debugPrint(
        "Error de Firebase al obtener tokens FCM para '$memberId': ${e.message} (Código: ${e.code})\nStackTrace: $stackTrace",
      );
      return null;
    } catch (e, stackTrace) {
      debugPrint(
        "Error inesperado al obtener tokens FCM para '$memberId': $e\nStackTrace: $stackTrace",
      );
      return null;
    }
  }

  Future<List<String>?> getUserFcmTokensByEmail(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      debugPrint("Error: Email proporcionado no es válido: '$email'.");
      return [];
    }

    try {
      final List<QueryDocumentSnapshot>? userDocs = await _firestoreService
          .getDocumentsWhere(
            collectionName: parentCollectionName,
            field: emailField,
            isEqualToValue: email,
            limit: 1,
          );

      if (userDocs == null) {
        debugPrint(
          "Error al consultar usuarios por email '$email' (el servicio retornó null).",
        );
        return null;
      }

      if (userDocs.isEmpty) {
        debugPrint("No se encontró un usuario con el email '$email'.");
        return [];
      }

      final userDoc = userDocs.first;
      final data = userDoc.data() as Map<String, dynamic>?;

      if (data == null || !data.containsKey(fcmTokensField)) {
        debugPrint(
          "El usuario con email '$email' no tiene el campo '$fcmTokensField' o no tiene datos.",
        );
        return [];
      }

      final dynamic fcmTokensData = data[fcmTokensField];

      if (fcmTokensData is List) {
        final List<String> fcmTokens = fcmTokensData
            .whereType<String>()
            .toList();
        if (fcmTokens.length != fcmTokensData.length) {
          debugPrint(
            "Advertencia: Algunos elementos en '$fcmTokensField' para el usuario con email '$email' no eran strings y fueron omitidos.",
          );
        }
        debugPrint("Tokens FCM para el usuario con email '$email': $fcmTokens");
        return fcmTokens;
      } else if (fcmTokensData == null) {
        debugPrint(
          "El campo '$fcmTokensField' para el usuario con email '$email' es nulo.",
        );
        return [];
      } else {
        debugPrint(
          "El campo '$fcmTokensField' para el usuario con email '$email' no es una lista. Tipo encontrado: ${fcmTokensData.runtimeType}",
        );
        return [];
      }
    } on FirebaseException catch (e, stackTrace) {
      debugPrint(
        "Error de Firebase al obtener tokens FCM por email '$email': ${e.message} (Código: ${e.code})\nStackTrace: $stackTrace",
      );
      return null;
    } catch (e, stackTrace) {
      debugPrint(
        "Error inesperado al obtener tokens FCM por email '$email': $e\nStackTrace: $stackTrace",
      );
      return null;
    }
  }

  Future<UserData?> getUserDataByEmail(String email) async {
    if (email.isEmpty) {
      debugPrint("Error: Email proporcionado está vacío.");
      return null;
    }
    final String normalizedEmail = email.trim().toLowerCase();

    try {
      final List<QueryDocumentSnapshot>? userDocs = await _firestoreService
          .getDocumentsWhere(
            collectionName: parentCollectionName,
            field: emailField,
            isEqualToValue: normalizedEmail,
            limit: 1,
          );

      if (userDocs == null) {
        debugPrint(
          "Error al consultar usuario por email '$normalizedEmail' (el servicio retornó null).",
        );
        return null;
      }

      if (userDocs.isEmpty) {
        debugPrint(
          "No se encontró un usuario con el email '$normalizedEmail'.",
        );
        return null;
      }

      final QueryDocumentSnapshot userDocSnapshot = userDocs.first;

      try {
        final UserData userData = UserData.fromFirestore(userDocSnapshot);
        debugPrint(
          "UserData obtenido para el email '$normalizedEmail': ID ${userData.uid}",
        );
        return userData;
      } catch (e, stackTrace) {
        debugPrint(
          "Error al convertir el documento a UserData para el email '$normalizedEmail' (ID: ${userDocSnapshot.id}): $e\nStackTrace: $stackTrace",
        );
        return null;
      }
    } on FirebaseException catch (e, stackTrace) {
      debugPrint(
        "Error de Firebase al obtener UserData por email '$normalizedEmail': ${e.message} (Código: ${e.code})\nStackTrace: $stackTrace",
      );
      return null;
    } catch (e, stackTrace) {
      debugPrint(
        "Error inesperado al obtener UserData por email '$normalizedEmail': $e\nStackTrace: $stackTrace",
      );
      return null;
    }
  }

  Stream<List<AppNotificationModel>> getAppNotificationsStream(String userId) {
    return _firestoreService
        .listenToCollectionFiltered(
          'users/$userId/app_notifications',
          orderByField: 'createdAt',
          descending: true,
          limit: 50,
        )
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => AppNotificationModel.fromFirestore(
                  doc as DocumentSnapshot<Map<String, dynamic>>,
                ),
              )
              .toList(),
        );
  }

  Future<void> markNotificationAsRead(
    String userId,
    String notificationId,
  ) async {
    await _firestoreService.updateDocument(
      'users/$userId/app_notifications',
      notificationId,
      {'isRead': true},
    );
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    final querySnapshot = await _firestoreService.getDocumentsWhere(
      collectionName: 'users/$userId/app_notifications',
      field: 'isRead',
      isEqualToValue: false,
    );

    if (querySnapshot != null && querySnapshot.isNotEmpty) {
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in querySnapshot) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    }
  }

  Future<void> deleteAppNotification(
    String userId,
    String notificationId,
  ) async {
    await _firestoreService.deleteDocument(
      'users/$userId/app_notifications',
      notificationId,
    );
  }

  Stream<RemoteMessage> get onForegroundMessageReceived {
    return FirebaseMessaging.onMessage;
  }
}
