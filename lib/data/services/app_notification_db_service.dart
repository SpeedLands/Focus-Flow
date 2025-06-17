// lib/data/services/app_notification_db_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:focus_flow/data/models/app_notification_model.dart';

class AppNotificationDbService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<AppNotificationModel> _userAppNotificationsRef(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('app_notifications')
        .withConverter<AppNotificationModel>(
          fromFirestore: (snapshot, _) =>
              AppNotificationModel.fromFirestore(snapshot),
          toFirestore: (model, _) => model.toJson(),
        );
  }

  // Ya tienes un método similar en AuthController para guardar
  Future<void> addNotificationForUser(
    String userId,
    AppNotificationModel notification,
  ) async {
    try {
      await _userAppNotificationsRef(userId).add(notification);
      debugPrint(
        "AppNotificationDbService: Notificación guardada para $userId",
      );
    } catch (e) {
      debugPrint(
        "AppNotificationDbService: Error guardando notificación para $userId: $e",
      );
      rethrow; // Para que el llamador pueda manejarlo
    }
  }

  Stream<List<AppNotificationModel>> getAppNotificationsStream(String userId) {
    return _userAppNotificationsRef(userId)
        .orderBy('createdAt', descending: true)
        .limit(50) // Limitar para no cargar demasiadas al inicio
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> markNotificationAsRead(
    String userId,
    String notificationId,
  ) async {
    await _userAppNotificationsRef(
      userId,
    ).doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    final batch = _firestore.batch();
    final querySnapshot = await _userAppNotificationsRef(
      userId,
    ).where('isRead', isEqualTo: false).get();

    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    if (querySnapshot.docs.isNotEmpty) {
      // Solo hacer commit si hay algo que actualizar
      await batch.commit();
    }
  }

  // Opcional: eliminar
  Future<void> deleteAppNotification(
    String userId,
    String notificationId,
  ) async {
    await _userAppNotificationsRef(userId).doc(notificationId).delete();
  }
}
