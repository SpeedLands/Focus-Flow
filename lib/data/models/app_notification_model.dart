import 'package:cloud_firestore/cloud_firestore.dart';

enum AppNotificationType {
  projectInvitation, // Invitación a un proyecto
  taskAssigned, // Si implementas asignación de tareas
  taskCompleted, // Tarea completada por otro miembro
  projectUpdate, // Actualización importante en un proyecto
  pomodoroEnd, // Fin de un ciclo Pomodoro
  generic, // Notificación genérica
  taskModificationRequest, //  Solicitud de miembro para editar/eliminar tarea
  taskModificationApproved, //  Notificación al miembro de que su solicitud fue aprobada
  taskModificationRejected, // Notificación al miembro de que su solicitud fue rechazada
  projectDeletionRequest,
  projectDeletionApproved,
  projectDeletionRejected,
}

class AppNotificationModel {
  final String?
  id; // ID del documento de notificación en Firestore (para el usuario)
  final String title;
  final String body;
  final AppNotificationType type;
  final Map<String, dynamic>?
  data; // Datos adicionales (ej. projectId, taskId, invitationId)
  final bool isRead;
  final Timestamp createdAt;
  final String? iconName; // Opcional: para mostrar un icono específico
  final String? routeToNavigate; // Opcional: ruta a la que navegar al tocar

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
      data:
          data ??
          this.data, // Si se pasa data, se usa; si no, se mantiene el anterior. Para eliminarlo, se pasaría un mapa vacío o null explícitamente.
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      iconName: setIconNameToNull ? null : (iconName ?? this.iconName),
      routeToNavigate: setRouteToNavigateToNull
          ? null
          : (routeToNavigate ?? this.routeToNavigate),
    );
  }
}
