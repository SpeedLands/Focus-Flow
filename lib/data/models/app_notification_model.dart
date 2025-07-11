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
    final d = snapshot.data();

    // Es una buena práctica verificar si el documento tiene datos antes de proceder.
    if (d == null) {
      // Puedes lanzar una excepción o devolver un objeto por defecto si el documento está vacío.
      // Lanzar una excepción suele ser mejor para detectar problemas en los datos.
      throw StateError(
        'El documento de notificación ${snapshot.id} no tiene datos.',
      );
    }

    return AppNotificationModel(
      id: snapshot.id,

      // Para Strings: Haz un cast a String nulable y luego proporciona un valor por defecto.
      title: (d['title'] as String?) ?? 'Notificación',
      body: (d['body'] as String?) ?? '',

      // Para el Enum: La lógica actual es buena, pero podemos hacer el cast más explícito.
      type: AppNotificationType.values.firstWhere(
        (e) => e.toString() == (d['type'] as String?), // Cast a String nulable
        orElse: () => AppNotificationType.generic,
      ),

      // Para el Map anidado: Tu lógica es correcta, pero podemos añadir el cast.
      data: d['data'] != null
          ? Map<String, dynamic>.from(d['data'] as Map)
          : null,

      // Para Bools:
      isRead: (d['isRead'] as bool?) ?? false,

      // Para Timestamps:
      createdAt: (d['createdAt'] as Timestamp?) ?? Timestamp.now(),

      // Para campos que pueden ser nulos y quieres que sigan siéndolo:
      // Simplemente haz un cast al tipo nulable.
      iconName: d['iconName'] as String?,
      routeToNavigate: d['routeToNavigate'] as String?,
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
