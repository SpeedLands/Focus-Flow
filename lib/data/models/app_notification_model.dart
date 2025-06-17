import 'package:cloud_firestore/cloud_firestore.dart';

enum AppNotificationType {
  projectInvitation,
  taskAssigned,
  taskCompleted,
  projectUpdate,
  pomodoroEnd,
  generic,
  taskModificationRequest,
  taskModificationApproved,
  taskModificationRejected,
  projectDeletionRequest,
  projectDeletionApproved,
  projectDeletionRejected,
}

class AppNotificationModel {
  final String? id;
  final String title;
  final String body;
  final AppNotificationType type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final Timestamp createdAt;
  final String? iconName;
  final String? routeToNavigate;

  AppNotificationModel({
    this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    this.isRead = false,
    required this.createdAt,
    this.iconName,
    this.routeToNavigate,
  });

  factory AppNotificationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final d = snapshot.data()!;
    return AppNotificationModel(
      id: snapshot.id,
      title: d['title'] ?? 'Notificación',
      body: d['body'] ?? '',
      type: AppNotificationType.values.firstWhere(
        (e) => e.toString() == d['type'],
        orElse: () => AppNotificationType.generic,
      ),
      data: d['data'] != null ? Map<String, dynamic>.from(d['data']) : null,
      isRead: d['isRead'] ?? false,
      createdAt: d['createdAt'] ?? Timestamp.now(),
      iconName: d['iconName'],
      routeToNavigate: d['routeToNavigate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'type': type.toString(),
      if (data != null) 'data': data,
      'isRead': isRead,
      'createdAt': createdAt,
      if (iconName != null) 'iconName': iconName,
      if (routeToNavigate != null) 'routeToNavigate': routeToNavigate,
    };
  }

  AppNotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    AppNotificationType? type,
    Map<String, dynamic>? data,
    bool? isRead,
    Timestamp? createdAt,
    String? iconName,
    bool setIconNameToNull = false,
    String? routeToNavigate,
    bool setRouteToNavigateToNull = false,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      iconName: setIconNameToNull ? null : (iconName ?? this.iconName),
      routeToNavigate: setRouteToNavigateToNull
          ? null
          : (routeToNavigate ?? this.routeToNavigate),
    );
  }
}
