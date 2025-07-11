import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:focus_flow/data/providers/notification_provider.dart';
import 'package:focus_flow/routes/app_routes.dart';
import 'package:focus_flow/data/models/project_invitation_model.dart';
import 'package:focus_flow/data/models/app_notification_model.dart';
import 'package:focus_flow/data/providers/auth_app_provider.dart';
import 'package:focus_flow/data/services/firestore_service.dart';

class ProjectInvitationProvider {
  final FirestoreService _firestoreService;
  final AuthProviderApp _authProviderApp;
  final NotificationProvider _notificationProvider;

  final String _invitesCollection = 'projectInvitations';
  final String _projectsCollection = 'projects';

  ProjectInvitationProvider(
    this._firestoreService,
    this._authProviderApp,
    this._notificationProvider,
  );

  Stream<List<ProjectInvitationModel>> getInvitationsStream() {
    final currentUser = _authProviderApp.currentUser;
    if (currentUser == null) return const Stream.empty();

    final email = currentUser.email!.toLowerCase();
    return _firestoreService
        .listenToCollectionFiltered(
          _invitesCollection,
          filters: [
            QueryFilter(
              field: 'invitedUserEmail',
              operator: FilterOperator.isEqualTo,
              value: email,
            ),
            QueryFilter(
              field: 'status',
              operator: FilterOperator.isEqualTo,
              value: InvitationStatus.pending.toString(),
            ),
          ],
          orderByField: 'createdAt',
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

  Future<ProjectInvitationModel?> getInvitationById(String id) async {
    try {
      final docSnap = await _firestoreService.getDocument(
        _invitesCollection,
        id,
      );
      if (docSnap != null && docSnap.exists) {
        return ProjectInvitationModel.fromFirestore(
          docSnap as DocumentSnapshot<Map<String, dynamic>>,
        );
      } else {
        debugPrint(
          "[ProjectInvitationProvider] Invitación con id '$id' no encontrada.",
        );
        return null;
      }
    } catch (e) {
      debugPrint(
        "[ProjectInvitationProvider] Error al obtener invitación por ID '$id': $e",
      );
      return null;
    }
  }

  Future<void> inviteUser(
    String projectId,
    String projectName,
    String invitedEmail,
  ) async {
    final currentUser = _authProviderApp.currentUser;
    if (currentUser == null) throw Exception('No autenticado');

    final projectDoc = await _firestoreService.getDocument(
      _projectsCollection,
      projectId,
    );
    final project = projectDoc?.data() as Map<String, dynamic>?;
    if (project == null || project['adminUserId'] != currentUser.uid) {
      throw Exception('Sin permisos de administrador');
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
      throw Exception('No se pudo crear la invitación');
    }

    // Crear notificación en BD
    final appNotif = AppNotificationModel(
      title: 'Invitación al proyecto: $projectName',
      body: '${currentUser.displayName ?? currentUser.email} te invitó',
      type: AppNotificationType.projectInvitation,
      routeToNavigate: AppRoutes.PROJECTS_LIST,
      data: {
        'type': 'project_invitation',
        'invitationId': invitationId,
        'projectId': projectId,
        'projectName': projectName,
        'invitedBy': currentUser.displayName ?? currentUser.email!,
        'screen': AppRoutes.PROJECTS_LIST,
      },
      createdAt: Timestamp.now(),
    );

    // Agregar la notificación y enviar FCM
    final dataUser = await _authProviderApp.getUserDataByEmail(cleanEmail);
    if (dataUser != null) {
      await _notificationProvider.saveNotification(
        userId: dataUser.uid,
        notification: appNotif,
      );

      final tokens = await _notificationProvider.getUserTokensByEmail(
        cleanEmail,
      );
      if (tokens != null && tokens.isNotEmpty) {
        for (final t in tokens) {
          await _notificationProvider.sendNotificationToToken(
            token: t,
            title: appNotif.title,
            body: appNotif.body,
            data: appNotif.data!.map((k, v) => MapEntry(k, v.toString())),
          );
        }
      }
    }
  }

  Future<void> acceptInvitation(String invitationId) async {
    final currentUser = _authProviderApp.currentUser;
    if (currentUser == null) throw Exception('No autenticado');

    final docSnap = await _firestoreService.getDocument(
      _invitesCollection,
      invitationId,
    );
    if (docSnap == null || !docSnap.exists) {
      throw Exception('Invitación no existe');
    }

    final inv = ProjectInvitationModel.fromFirestore(
      docSnap as DocumentSnapshot<Map<String, dynamic>>,
    );
    if (inv.invitedUserEmail != currentUser.email!.toLowerCase()) {
      throw Exception('No es tu invitación');
    }
    if (inv.status != InvitationStatus.pending) {
      throw Exception('Invitación ya ${inv.status}');
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
    final currentUser = _authProviderApp.currentUser;
    if (currentUser == null) throw Exception('No autenticado');

    final projectDoc = await _firestoreService.getDocument(
      _projectsCollection,
      projectId,
    );

    // Casting explícito del mapa de datos
    final projData = projectDoc?.data() as Map<String, dynamic>?;

    // Comprobación segura de permisos
    if (projData == null || projData['adminUserId'] != currentUser.uid) {
      throw Exception('Sin permisos');
    }

    // --- LA CORRECCIÓN PRINCIPAL ESTÁ AQUÍ ---
    // 1. Obtenemos la lista de forma segura y la casteamos a List<String>
    final userRoles = (projData['userRoles'] as List?)?.cast<String>() ?? [];

    // 2. Ahora 'userRoles' es una List<String>, por lo que 'firstWhere' devuelve un String.
    final String roleEntry = userRoles.firstWhere(
      (r) => r.startsWith('$memberIdToRemove:'),
      orElse: () => '', // orElse devuelve un String vacío
    );

    // 3. La condición del 'if' ahora es segura porque .isEmpty en un String devuelve un bool.
    if (roleEntry.isEmpty) {
      // La condición ahora es un booleano estático, el error desaparece.
      debugPrint('No se encontró el rol para el miembro: $memberIdToRemove');
      return;
    }

    // El resto de la función es seguro
    await _firestoreService.updateDocument(_projectsCollection, projectId, {
      'userRoles': FieldValue.arrayRemove([roleEntry]),
      'updatedAt': Timestamp.now(),
    });
  }
}
