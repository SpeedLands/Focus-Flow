import 'package:cloud_firestore/cloud_firestore.dart';

enum InvitationStatus { pending, accepted, declined }

class ProjectInvitationModel {
  final String? id;
  final String projectId;
  final String projectName;
  final String invitedUserEmail;
  final String invitedByUserId;
  final InvitationStatus status;
  final Timestamp createdAt;

  ProjectInvitationModel({
    this.id,
    required this.projectId,
    required this.projectName,
    required this.invitedUserEmail,
    required this.invitedByUserId,
    this.status = InvitationStatus.pending,
    required this.createdAt,
  });

  factory ProjectInvitationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();

    // Guarda de seguridad por si el documento no tiene datos.
    if (data == null) {
      throw StateError(
        'El documento de invitación ${snapshot.id} no tiene datos.',
      );
    }

    return ProjectInvitationModel(
      id: snapshot.id,

      // Para los campos String requeridos
      projectId: (data['projectId'] as String?) ?? '',
      projectName: (data['projectName'] as String?) ?? 'Proyecto Desconocido',
      invitedUserEmail: (data['invitedUserEmail'] as String?) ?? '',
      invitedByUserId: (data['invitedByUserId'] as String?) ?? '',

      // Para el Enum
      status: InvitationStatus.values.firstWhere(
        (e) =>
            e.toString() ==
            (data['status'] as String?), // Cast a String nulable
        orElse: () => InvitationStatus
            .pending, // Valor por defecto si no se encuentra o es null
      ),

      // Para el Timestamp
      createdAt: (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'projectName': projectName,
      'invitedUserEmail': invitedUserEmail,
      'invitedByUserId': invitedByUserId,
      'status': status.toString(),
      'createdAt': createdAt,
    };
  }

  ProjectInvitationModel copyWith({
    String? id,
    String? projectId,
    String? projectName,
    String? invitedUserEmail,
    String? invitedByUserId,
    InvitationStatus? status,
    Timestamp? createdAt,
  }) {
    return ProjectInvitationModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      invitedUserEmail: invitedUserEmail ?? this.invitedUserEmail,
      invitedByUserId: invitedByUserId ?? this.invitedByUserId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
