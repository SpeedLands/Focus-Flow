import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:focus_flow/data/models/app_notification_model.dart';
import 'package:focus_flow/data/models/project_model.dart';
import 'package:focus_flow/data/models/project_invitation_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:focus_flow/data/services/notification_service.dart';
import 'package:focus_flow/data/services/task_service.dart';
import 'package:focus_flow/modules/auth/auth_controller.dart';
import 'package:focus_flow/routes/app_routes.dart';
import 'package:get/get.dart';

class ProjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TaskService _taskService = Get.find<TaskService>();

  CollectionReference<ProjectModel> get _projectsCollectionRef => _firestore
      .collection('projects')
      .withConverter<ProjectModel>(
        fromFirestore: (snapshots, _) => ProjectModel.fromFirestore(snapshots),
        toFirestore: (project, _) => project.toJson(),
      );

  CollectionReference<ProjectInvitationModel>
  get _projectInvitationsCollectionRef => _firestore
      .collection('projectInvitations')
      .withConverter<ProjectInvitationModel>(
        fromFirestore: (snapshots, _) =>
            ProjectInvitationModel.fromFirestore(snapshots),
        toFirestore: (invitation, _) => invitation.toJson(),
      );

  String? get _currentUserId => _auth.currentUser?.uid;

  String _userRoleString(String userId, String role) => '$userId:$role';

  Future<DocumentReference<ProjectModel>?> addProject(
    ProjectModel projectDataFromController,
  ) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception("Usuario no autenticado para crear proyecto.");
    }

    final newProject = projectDataFromController.copyWith(
      adminUserId: userId,
      userRoles: [_userRoleString(userId, "admin")],
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    );

    try {
      final docRef = await _projectsCollectionRef.add(newProject);
      debugPrint("Proyecto creado con ID: ${docRef.id}");
      return docRef;
    } catch (e) {
      debugPrint("Error al crear proyecto: $e");
      throw Exception("No se pudo crear el proyecto: ${e.toString()}");
    }
  }

  Stream<List<ProjectModel>> getProjectsStream() {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    final String userAsAdmin = _userRoleString(userId, 'admin');
    final String userAsMember = _userRoleString(userId, 'member');

    return _projectsCollectionRef
        .where('userRoles', arrayContainsAny: [userAsAdmin, userAsMember])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          debugPrint("Proyectos recibidos del stream: ${snapshot.docs.length}");
          return snapshot.docs.map((doc) => doc.data()).toList();
        })
        .handleError((error) {
          debugPrint("Error en getProjectsStream: $error");
          return <ProjectModel>[];
        });
  }

  Future<void> updateProjectDetails(ProjectModel project) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception("Usuario no autenticado para actualizar proyecto.");
    }
    if (project.id == null) {
      throw Exception("ID de proyecto no puede ser nulo para actualizar.");
    }

    final currentProjectDoc = await _projectsCollectionRef
        .doc(project.id)
        .get();
    final currentProjectData = currentProjectDoc.data();

    if (!currentProjectDoc.exists ||
        currentProjectData?.adminUserId != userId) {
      throw Exception("No tienes permisos para actualizar este proyecto.");
    }

    final projectToUpdate = project.copyWith(updatedAt: Timestamp.now());
    return _projectsCollectionRef
        .doc(project.id)
        .update(projectToUpdate.toJsonForUpdate());
  }

  Future<void> deleteProject(String projectId) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception("Usuario no autenticado para eliminar proyecto.");
    }

    final projectDocRef = _projectsCollectionRef.doc(projectId);
    final projectSnapshot = await projectDocRef.get();
    final projectData = projectSnapshot.data();

    if (!projectSnapshot.exists) throw Exception("El proyecto no existe.");
    if (projectData?.adminUserId != userId) {
      throw Exception("No tienes permisos para eliminar este proyecto.");
    }

    final batch = _firestore.batch();
    await _taskService.deleteAllTasksFromProjectWithBatch(projectId, batch);

    final invitationsSnapshot = await _projectInvitationsCollectionRef
        .where('projectId', isEqualTo: projectId)
        .get();
    for (var invDoc in invitationsSnapshot.docs) {
      batch.delete(invDoc.reference);
    }
    batch.delete(projectDocRef);

    try {
      await batch.commit();
      debugPrint(
        "Proyecto $projectId y sus datos asociados eliminados correctamente.",
      );
    } catch (e) {
      debugPrint("Error al eliminar el proyecto $projectId con batch: $e");
      throw Exception("Error al eliminar el proyecto: ${e.toString()}");
    }
  }

  Future<ProjectModel?> getProjectById(String projectId) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception("Usuario no autenticado.");
    }

    final doc = await _projectsCollectionRef.doc(projectId).get();
    final projectData = doc.data();

    if (doc.exists && projectData != null) {
      final isMember = projectData.userRoles.any(
        (roleEntry) => roleEntry.startsWith('$userId:'),
      );
      if (isMember) {
        return projectData;
      }
    }
    return null;
  }

  Future<String> generateAccessCode(String projectId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception("Usuario no autenticado.");

    final projectDoc = await _projectsCollectionRef.doc(projectId).get();
    if (!projectDoc.exists || projectDoc.data()?.adminUserId != userId) {
      throw Exception(
        "No tienes permisos para generar un código para este proyecto.",
      );
    }
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final Random random = Random.secure();
    const int codeLength = 6;
    String generatedCode = String.fromCharCodes(
      Iterable.generate(
        codeLength,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
    String accessCode = generatedCode;
    await _projectsCollectionRef.doc(projectId).update({
      'accessCode': accessCode,
      'updatedAt': Timestamp.now(),
    });
    debugPrint("Código de acceso generado para $projectId: $accessCode");
    return accessCode;
  }

  Future<bool> joinProjectWithCode(String accessCode) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception("Usuario no autenticado.");
    if (accessCode.trim().isEmpty) {
      throw Exception("El código de acceso no puede estar vacío.");
    }

    final querySnapshot = await _projectsCollectionRef
        .where('accessCode', isEqualTo: accessCode.trim().toUpperCase())
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception("Código de acceso inválido o expirado.");
    }

    final projectDoc = querySnapshot.docs.first;
    final project = projectDoc.data();

    final alreadyMember = project.userRoles.any(
      (roleEntry) => roleEntry.startsWith('$userId:'),
    );
    if (alreadyMember) {
      debugPrint("El usuario ya es miembro de este proyecto.");
      return true;
    }

    await projectDoc.reference.update({
      'userRoles': FieldValue.arrayUnion([_userRoleString(userId, 'member')]),
      'updatedAt': Timestamp.now(),
    });
    debugPrint(
      "Usuario $userId unido al proyecto ${projectDoc.id} con código.",
    );
    return true;
  }

  Future<void> inviteUserToProject(
    String projectId,
    String invitedUserEmail,
  ) async {
    final adminUserId = _currentUserId;
    if (adminUserId == null) throw Exception("Usuario no autenticado.");

    String? adminName = "Un administrador";
    final currentUser = _auth.currentUser;
    if (currentUser?.displayName != null &&
        currentUser!.displayName!.isNotEmpty) {
      adminName = currentUser.displayName!;
    } else if (currentUser?.email != null) {
      adminName = currentUser!.email;
    }

    final projectDoc = await _projectsCollectionRef.doc(projectId).get();
    if (!projectDoc.exists || projectDoc.data()?.adminUserId != adminUserId) {
      throw Exception("No tienes permisos para invitar a este proyecto.");
    }
    final project = projectDoc.data()!;
    final cleanInvitedUserEmail = invitedUserEmail.trim().toLowerCase();

    final newInvitation = ProjectInvitationModel(
      projectId: projectId,
      projectName: project.name,
      invitedUserEmail: cleanInvitedUserEmail,
      invitedByUserId: adminUserId,
      createdAt: Timestamp.now(),
    );
    final invitationDocRef = await _projectInvitationsCollectionRef.add(
      newInvitation,
    );
    debugPrint(
      "Invitación creada con ID: ${invitationDocRef.id} para $cleanInvitedUserEmail",
    );

    final AppNotificationModel appNotif = AppNotificationModel(
      title: "Invitación al proyecto: ${project.name}",
      body: "$adminName te ha invitado a unirte al proyecto '${project.name}'.",
      type: AppNotificationType.projectInvitation,
      routeToNavigate: AppRoutes.PROJECTS_LIST,
      data: {
        'invitationId': invitationDocRef.id,
        'projectId': projectId,
        'projectName': project.name,
        'invitedBy': ?adminName,
        'screen': AppRoutes.PROJECTS_LIST,
      },
      createdAt: Timestamp.now(),
    );

    try {
      final AuthController authController = Get.find<AuthController>();
      final dataUser = await authController.getUserDataByEmail(
        invitedUserEmail,
      );
      await authController.addUserNotification(dataUser!.uid, appNotif);
      List<String>? targetFcmTokens = await authController
          .getUserFcmTokensByEmail(cleanInvitedUserEmail);

      if (targetFcmTokens != null && targetFcmTokens.isNotEmpty) {
        final NotificationService notificationService =
            NotificationService.instance;
        String notificationTitle = "Invitación al proyecto: ${project.name}";
        String notificationBody =
            "$adminName te ha invitado a unirte al proyecto '${project.name}'.";
        Map<String, String> notificationDataPayload = {
          'type': 'project_invitation',
          'invitationId': invitationDocRef.id,
          'projectId': projectId,
          'projectName': project.name,
          'invitedBy': ?adminName,
          'title': notificationTitle,
          'body': notificationBody,
          'screen': AppRoutes.PROJECTS_LIST,
        };
        for (String token in targetFcmTokens) {
          debugPrint("Enviando invitación por notificación a token: $token");
          await notificationService.sendNotificationToDevice(
            targetDeviceToken: token,
            title: notificationTitle,
            body: notificationBody,
            data: notificationDataPayload,
          );
        }
        Get.snackbar(
          "Invitación Enviada",
          "Se ha enviado una invitación y notificación a $cleanInvitedUserEmail.",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        debugPrint(
          "No se encontraron tokens FCM para $cleanInvitedUserEmail. Solo se creó la invitación en BD.",
        );
        Get.snackbar(
          "Invitación Creada",
          "Se creó una invitación para $cleanInvitedUserEmail (usuario no encontrado para notificación push).",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint("Error al intentar enviar notificación de invitación: $e");
      Get.snackbar(
        "Invitación Creada (Error Notif.)",
        "Se creó la invitación, pero hubo un error al notificar: ${e.toString()}",
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.black,
        duration: const Duration(seconds: 5),
      );
    }
  }

  Stream<List<ProjectInvitationModel>> getProjectInvitationsStream() {
    final userEmail = _auth.currentUser?.email;
    if (userEmail == null) return Stream.value([]);
    return _projectInvitationsCollectionRef
        .where('invitedUserEmail', isEqualTo: userEmail.toLowerCase())
        .where('status', isEqualTo: InvitationStatus.pending.toString())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> acceptProjectInvitation(String invitationId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception("Usuario no autenticado.");

    final invitationDocRef = _projectInvitationsCollectionRef.doc(invitationId);
    final invitationSnapshot = await invitationDocRef.get();

    if (!invitationSnapshot.exists) {
      throw Exception("Invitación no encontrada.");
    }
    final invitation = invitationSnapshot.data()!;

    if (invitation.invitedUserEmail !=
        _auth.currentUser?.email?.toLowerCase()) {
      throw Exception("Esta invitación no es para ti.");
    }
    if (invitation.status != InvitationStatus.pending) {
      throw Exception(
        "Esta invitación ya ha sido ${invitation.status.toString().split('.').last}.",
      );
    }

    final projectDocRef = _projectsCollectionRef.doc(invitation.projectId);
    final projectSnapshot = await projectDocRef.get();
    if (!projectSnapshot.exists) {
      throw Exception("El proyecto asociado a esta invitación ya no existe.");
    }
    final projectData = projectSnapshot.data()!;
    final alreadyMember = projectData.userRoles.any(
      (roleEntry) => roleEntry.startsWith('$userId:'),
    );
    if (alreadyMember) {
      await invitationDocRef.update({
        'status': InvitationStatus.accepted.toString(),
      });
      debugPrint(
        "Invitación aceptada. Usuario $userId ya era miembro del proyecto ${invitation.projectId}.",
      );
      return;
    }

    final batch = _firestore.batch();
    batch.update(invitationDocRef, {
      'status': InvitationStatus.accepted.toString(),
    });

    batch.update(projectDocRef, {
      'userRoles': FieldValue.arrayUnion([_userRoleString(userId, 'member')]),
      'updatedAt': Timestamp.now(),
    });

    await batch.commit();
    debugPrint(
      "Invitación aceptada. Usuario $userId añadido al proyecto ${invitation.projectId}.",
    );
  }

  Future<void> declineProjectInvitation(String invitationId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception("Usuario no autenticado.");
    final invitationDocRef = _projectInvitationsCollectionRef.doc(invitationId);
    await invitationDocRef.update({
      'status': InvitationStatus.declined.toString(),
    });
    debugPrint("Invitación $invitationId declinada.");
  }

  Future<void> leaveProject(String projectId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception("Usuario no autenticado.");

    final projectDocRef = _projectsCollectionRef.doc(projectId);
    final projectSnapshot = await projectDocRef.get();

    if (!projectSnapshot.exists) throw Exception("Proyecto no encontrado.");
    final project = projectSnapshot.data()!;

    String? userRoleInProject;
    for (String roleEntry in project.userRoles) {
      if (roleEntry.startsWith('$userId:')) {
        userRoleInProject = roleEntry;
        break;
      }
    }

    if (userRoleInProject == null) {
      throw Exception("No eres miembro de este proyecto.");
    }

    final uniqueUserIdsInProject = project.userRoles
        .map((r) => r.split(':').first)
        .toSet();

    if (project.adminUserId == userId && uniqueUserIdsInProject.length > 1) {
      throw Exception(
        "Eres el administrador. Debes transferir la administración o eliminar el proyecto.",
      );
    }
    if (project.adminUserId == userId && uniqueUserIdsInProject.length == 1) {
      debugPrint(
        "Admin es el último miembro, eliminando proyecto $projectId...",
      );
      return deleteProject(projectId);
    }

    await projectDocRef.update({
      'userRoles': FieldValue.arrayRemove([userRoleInProject]),
      'updatedAt': Timestamp.now(),
    });
    debugPrint("Usuario $userId ha salido del proyecto $projectId.");
  }

  Future<void> removeMemberFromProject(
    String projectId,
    String memberIdToRemove,
  ) async {
    final adminUserId = _currentUserId;
    if (adminUserId == null) throw Exception("Usuario no autenticado.");

    final projectDocRef = _projectsCollectionRef.doc(projectId);
    final projectSnapshot = await projectDocRef.get();

    if (!projectSnapshot.exists) throw Exception("Proyecto no encontrado.");
    final project = projectSnapshot.data()!;

    if (project.adminUserId != adminUserId) {
      throw Exception(
        "No tienes permisos para remover miembros de este proyecto.",
      );
    }
    if (memberIdToRemove == adminUserId) {
      throw Exception(
        "El administrador no puede removerse a sí mismo de esta manera.",
      );
    }

    String? memberRoleToRemoveString;
    for (String roleEntry in project.userRoles) {
      if (roleEntry.startsWith('$memberIdToRemove:')) {
        memberRoleToRemoveString = roleEntry;
        break;
      }
    }

    if (memberRoleToRemoveString == null) {
      debugPrint(
        "El usuario $memberIdToRemove no es miembro de este proyecto.",
      );
      return;
    }

    await projectDocRef.update({
      'userRoles': FieldValue.arrayRemove([memberRoleToRemoveString]),
      'updatedAt': Timestamp.now(),
    });
    debugPrint(
      "Miembro $memberIdToRemove removido del proyecto $projectId por el admin $adminUserId.",
    );
  }
}
