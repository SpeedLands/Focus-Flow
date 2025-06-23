import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:focus_flow/data/models/app_notification_model.dart';
import 'package:focus_flow/data/models/user_model.dart';
import 'package:focus_flow/data/services/firestore_service.dart';
import 'package:focus_flow/data/services/messaging_service.dart';
import 'package:focus_flow/data/services/http_service.dart';

class NotificationProvider {
  final FirestoreService _firestore;
  final MessagingService _messaging;
  final HttpService _http;
  final String projectId = 'focusflow-acd29';

  NotificationProvider(this._firestore, this._http, this._messaging);

  final String _usersCollection = 'users';
  final String _notificationsSubCollection = 'app_notifications';
  final String _fcmTokensField = 'fcmTokens';
  final String _emailField = 'email';
  final String _tokenUpdateField = 'lastTokenUpdate';

  // -------------------- 🔐 TOKEN MANAGEMENT --------------------

  Future<String?> getCurrentDeviceToken() async {
    return await _messaging.getToken();
  }

  Future<bool> saveCurrentDeviceToken(String userId) async {
    if (userId.isEmpty) return false;
    final token = await getCurrentDeviceToken();
    if (token == null || token.isEmpty) return false;

    final updateData = {
      _fcmTokensField: FieldValue.arrayUnion([token]),
      _tokenUpdateField: FieldValue.serverTimestamp(),
    };

    return await _updateUser(userId, updateData);
  }

  Future<bool> removeCurrentDeviceToken(String userId) async {
    if (userId.isEmpty) return false;
    final token = await getCurrentDeviceToken();
    if (token == null || token.isEmpty) return true;

    final updateData = {
      _fcmTokensField: FieldValue.arrayRemove([token]),
      _tokenUpdateField: FieldValue.serverTimestamp(),
    };

    return await _updateUser(userId, updateData);
  }

  Future<bool> _updateUser(
    String userId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      await _firestore.updateDocument(_usersCollection, userId, updateData);
      return true;
    } catch (e) {
      debugPrint('Error actualizando documento de usuario $userId: $e');
      return false;
    }
  }

  // -------------------- 📩 NOTIFICATION SENDING --------------------

  Future<bool> sendNotificationToToken({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (token.isEmpty || title.isEmpty || body.isEmpty) return false;

    final accessToken = await _http.getAccessToken();
    if (accessToken.isEmpty) return false;

    return await _http.sendNotificationToDevice(
      targetDeviceToken: token,
      title: title,
      body: body,
      data: data,
      accessToken: accessToken,
      projectId: projectId,
    );
  }

  Future<bool> notifyUserById({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final tokens = await getUserTokensById(userId);
    if (tokens == null || tokens.isEmpty) return false;

    bool result = true;
    for (final token in tokens) {
      result &= await sendNotificationToToken(
        token: token,
        title: title,
        body: body,
        data: data,
      );
    }
    return result;
  }

  // -------------------- 📦 FIRESTORE STORAGE --------------------

  Future<void> saveNotification({
    required String userId,
    required AppNotificationModel notification,
  }) async {
    try {
      await _firestore.addDocumentToSubcollection(
        parentCollectionName: _usersCollection,
        subCollectionName: _notificationsSubCollection,
        documentId: userId,
        data: notification.toJson(),
      );
    } catch (e) {
      debugPrint('Error guardando notificación: $e');
    }
  }

  Stream<List<AppNotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .listenToCollectionFiltered(
          '$_usersCollection/$userId/$_notificationsSubCollection',
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

  Future<void> markAsRead(String userId, String notificationId) async {
    await _firestore.updateDocument(
      '$_usersCollection/$userId/$_notificationsSubCollection',
      notificationId,
      {'isRead': true},
    );
  }

  Future<void> markAllAsRead(String userId) async {
    final docs = await _firestore.getDocumentsWhere(
      collectionName: '$_usersCollection/$userId/$_notificationsSubCollection',
      field: 'isRead',
      isEqualToValue: false,
    );

    if (docs != null && docs.isNotEmpty) {
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    }
  }

  Future<void> deleteNotification(String userId, String notificationId) async {
    await _firestore.deleteDocument(
      '$_usersCollection/$userId/$_notificationsSubCollection',
      notificationId,
    );
  }

  // -------------------- 🔍 TOKEN LOOKUP --------------------

  Future<List<String>?> getUserTokensById(String userId) async {
    final doc = await _firestore.getDocument(_usersCollection, userId);
    if (doc?.exists != true) return [];

    final data = doc!.data() as Map<String, dynamic>?;
    final tokens = data?[_fcmTokensField];

    return (tokens is List) ? tokens.whereType<String>().toList() : [];
  }

  Future<List<String>?> getUserTokensByEmail(String email) async {
    final docs = await _firestore.getDocumentsWhere(
      collectionName: _usersCollection,
      field: _emailField,
      isEqualToValue: email.trim().toLowerCase(),
      limit: 1,
    );

    if (docs == null || docs.isEmpty) return [];

    final data = docs.first.data() as Map<String, dynamic>?;
    final tokens = data?[_fcmTokensField];

    return (tokens is List) ? tokens.whereType<String>().toList() : [];
  }

  // -------------------- 👤 USER DATA --------------------

  Future<UserData?> getUserDataByEmail(String email) async {
    final docs = await _firestore.getDocumentsWhere(
      collectionName: _usersCollection,
      field: _emailField,
      isEqualToValue: email.trim().toLowerCase(),
      limit: 1,
    );

    if (docs == null || docs.isEmpty) return null;

    try {
      return UserData.fromFirestore(docs.first);
    } catch (e) {
      debugPrint("Error convirtiendo UserData: $e");
      return null;
    }
  }

  // -------------------- 🧠 LISTENERS --------------------

  Stream<RemoteMessage> get onForegroundMessageReceived {
    return FirebaseMessaging.onMessage;
  }
}
