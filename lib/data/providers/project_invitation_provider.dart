import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:focus_flow/data/providers/notification_provider.dart';
import 'package:focus_flow/routes/app_routes.dart';
import 'package:focus_flow/data/models/project_invitation_model.dart';
import 'package:focus_flow/data/models/app_notification_model.dart';
import 'package:focus_flow/data/providers/auth_provider.dart';
import 'package:focus_flow/data/services/firestore_service.dart';

class ProjectInvitationProvider {
  final FirestoreService _firestoreService;
  final AuthProvider _authProvider;
  final NotificationProvider _notificationProvider;

  final String _invitesCollection = "projectInvitations";
  final String _projectsCollection = "projects";

  ProjectInvitationProvider(
    this._firestoreService,
    this._authProvider,
    this._notificationProvider,
  );

  Stream<List<ProjectInvitationModel>> getInvitationsStream() {
    final currentUser = _authProvider.currentUser;
    if (currentUser == null) return const Stream.empty();

    final email = currentUser.email!.toLowerCase();
    return _firestoreService
        .listenToCollectionFiltered(
          _invitesCollection,
          filters: [
            QueryFilter(
              field: "invitedUserEmail",
              operator: FilterOperator.isEqualTo,
              value: email,
            ),
            QueryFilter(
              field: "status",
              operator: FilterOperator.isEqualTo,
              value: InvitationStatus.pending.toString(),
            ),
          ],
          orderByField: "createdAt",
          descending: true,
        )
        .map(
          (snap) => snap.docs
              .map(
                (doc) => ProjectInvitationModel.fromFirestore(
                  doc as DocumentSnapshot<Map<String, dynamic>>,
                ),
              )
              .toList(),
        );
  }

  Future<void> inviteUser(
    String projectId,
    String projectName,
    String invitedEmail,
  ) async {
    final currentUser = _authProvider.currentUser;
    if (currentUser == null) throw Exception("No autenticado");

    final projectDoc = await _firestoreService.getDocument(
      _projectsCollection,
      projectId,
    );
    final project = projectDoc?.data() as Map<String, dynamic>?;
    if (project == null || project['adminUserId'] != currentUser.uid) {
      throw Exception("Sin permisos de administrador");
    }

    final cleanEmail = invitedEmail.trim().toLowerCase();
    final invitation = ProjectInvitationModel(
      projectId: projectId,
      projectName: projectName,
      invitedUserEmail: cleanEmail,
      invitedByUserId: currentUser.uid,
      createdAt: Timestamp.now(),
    );

    final invitationId = await _firestoreService.addDocument(
      _invitesCollection,
      invitation.toJson(),
    );
    if (invitationId == null) {
      throw Exception("No se pudo crear la invitación");
    }

    // Crear notificación en BD
    final appNotif = AppNotificationModel(
      title: "Invitación al proyecto: $projectName",
      body: "${currentUser.displayName ?? currentUser.email} te invitó",
      type: AppNotificationType.projectInvitation,
      routeToNavigate: AppRoutes.PROJECTS_LIST,
      data: {
        'invitationId': invitationId,
        'projectId': projectId,
        'projectName': projectName,
        'invitedBy': currentUser.displayName ?? currentUser.email!,
        'screen': AppRoutes.PROJECTS_LIST,
      },
      createdAt: Timestamp.now(),
    );

    // Agregar la notificación y enviar FCM
    final dataUser = await _authProvider.getUserDataByEmail(cleanEmail);
    if (dataUser != null) {
      await _notificationProvider.addUserNotification(dataUser.uid, appNotif);

      final tokens = await _notificationProvider.getUserFcmTokensByEmail(
        cleanEmail,
      );
      if (tokens != null && tokens.isNotEmpty) {
        for (final t in tokens) {
          await _notificationProvider.sendNotificationToDevice(
            targetDeviceToken: t,
            title: appNotif.title,
            body: appNotif.body,
            data: appNotif.data!.map((k, v) => MapEntry(k, v.toString())),
          );
        }
      }
    }
  }

  Future<void> acceptInvitation(String invitationId) async {
    final currentUser = _authProvider.currentUser;
    if (currentUser == null) throw Exception("No autenticado");

    final docSnap = await _firestoreService.getDocument(
      _invitesCollection,
      invitationId,
    );
    if (docSnap == null || !docSnap.exists)
      throw Exception("Invitación no existe");

    final inv = ProjectInvitationModel.fromFirestore(
      docSnap as DocumentSnapshot<Map<String, dynamic>>,
    );
    if (inv.invitedUserEmail != currentUser.email!.toLowerCase()) {
      throw Exception("No es tu invitación");
    }
    if (inv.status != InvitationStatus.pending) {
      throw Exception("Invitación ya ${inv.status}");
    }

    // Batch update: marcar invitación aceptada + agregar usuario al proyecto
    await _firestoreService.setDocument(_invitesCollection, invitationId, {
      'status': InvitationStatus.accepted.toString(),
    }, SetOptions(merge: true));

    final memberRole = '${currentUser.uid}:member';
    await _firestoreService.updateDocument(_projectsCollection, inv.projectId, {
      'userRoles': FieldValue.arrayUnion([memberRole]),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> declineInvitation(String invitationId) async {
    await _firestoreService.updateDocument(_invitesCollection, invitationId, {
      'status': InvitationStatus.declined.toString(),
    });
  }

  Future<void> removeMember(String projectId, String memberIdToRemove) async {
    final currentUser = _authProvider.currentUser;
    if (currentUser == null) throw Exception("No autenticado");

    final projectDoc = await _firestoreService.getDocument(
      _projectsCollection,
      projectId,
    );
    final proj = projectDoc?.data() as Map<String, dynamic>?;
    if (proj == null || proj['adminUserId'] != currentUser.uid) {
      throw Exception("Sin permisos");
    }

    final roleEntry = proj['userRoles'].firstWhere(
      (r) => r.startsWith('$memberIdToRemove:'),
      orElse: () => '',
    );
    if (roleEntry.isEmpty) return;

    await _firestoreService.updateDocument(_projectsCollection, projectId, {
      'userRoles': FieldValue.arrayRemove([roleEntry]),
      'updatedAt': Timestamp.now(),
    });
  }
}
