// lib/data/models/project_invitation_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum InvitationStatus { pending, accepted, declined }

class ProjectInvitationModel {
  final String? id; // ID del documento de invitación
  final String projectId;
  final String projectName; // Desnormalizado para la UI
  final String invitedUserEmail; // O podrías usar invitedUserId si ya lo tienes
  final String invitedByUserId; // UID del admin que invita
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
    final data = snapshot.data()!;
    return ProjectInvitationModel(
      id: snapshot.id,
      projectId: data['projectId'] ?? '',
      projectName: data['projectName'] ?? 'Proyecto Desconocido',
      invitedUserEmail: data['invitedUserEmail'] ?? '',
      invitedByUserId: data['invitedByUserId'] ?? '',
      status: InvitationStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => InvitationStatus.pending,
      ),
      createdAt: data['createdAt'] ?? Timestamp.now(),
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
