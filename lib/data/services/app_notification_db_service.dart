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
      rethrow;
    }
  }

  Stream<List<AppNotificationModel>> getAppNotificationsStream(String userId) {
    return _userAppNotificationsRef(userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
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
      await batch.commit();
    }
  }

  Future<void> deleteAppNotification(
    String userId,
    String notificationId,
  ) async {
    await _userAppNotificationsRef(userId).doc(notificationId).delete();
  }
}
