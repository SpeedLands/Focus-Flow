import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:focus_flow/data/models/app_notification_model.dart';
import 'package:focus_flow/data/services/notification_service.dart';
import 'package:focus_flow/modules/notifications/notifications_controller.dart';
import 'package:get/get.dart';
import 'package:focus_flow/data/models/project_model.dart';
import 'package:focus_flow/data/models/project_invitation_model.dart';
import 'package:focus_flow/data/services/project_service.dart';
import 'package:focus_flow/modules/auth/auth_controller.dart';
import 'package:focus_flow/routes/app_routes.dart';
import 'package:focus_flow/data/services/task_service.dart';

class ProjectController extends GetxController {
  final ProjectService _projectService = Get.find<ProjectService>();
  final AuthController _authController = Get.find<AuthController>();
  final NotificationService _notificationService =
      Get.find<NotificationService>();
  final NotificationController _notificationController =
      Get.find<NotificationController>();
  final TaskService _taskService = Get.find<TaskService>();

  late Worker _authEverWorker;

  final RxList<ProjectModel> projects = <ProjectModel>[].obs;
  final RxBool isLoadingProjects = true.obs;
  final RxString projectListError = ''.obs;

  final GlobalKey<FormState> projectFormKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final Rx<Color> selectedColor = Rx<Color>(Colors.blue);
  final Rx<String> selectedIconName = Rx<String>('default_icon');
  final Rx<ProjectModel?> currentEditingProject = Rx<ProjectModel?>(null);
  bool get isEditing => currentEditingProject.value != null;
  final RxBool isSavingProject = false.obs;

  final RxString currentProjectRole = ''.obs;
  final RxList<ProjectInvitationModel> projectInvitations =
      <ProjectInvitationModel>[].obs;
  final RxBool isLoadingInvitations = false.obs;
  final TextEditingController inviteEmailController = TextEditingController();
  final TextEditingController accessCodeController = TextEditingController();
  final RxString generatedAccessCode = ''.obs;

  final RxList<AppNotificationModel> pendingProjectDeletionRequests =
      <AppNotificationModel>[].obs;
  final RxBool isLoadingDeletionRequests = false.obs;
  StreamSubscription? _pendingDeletionRequestsSubscription;

  final List<Color> predefinedColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];
  final List<Map<String, dynamic>> predefinedIcons = [
    {'name': 'work', 'icon': Icons.work_outline},
    {'name': 'home', 'icon': Icons.home_outlined},
    {'name': 'personal', 'icon': Icons.person_outline},
    {'name': 'book', 'icon': Icons.book_outlined},
    {'name': 'fitness', 'icon': Icons.fitness_center_outlined},
    {'name': 'shopping', 'icon': Icons.shopping_cart_outlined},
    {'name': 'travel', 'icon': Icons.flight_takeoff_outlined},
    {'name': 'code', 'icon': Icons.code_outlined},
    {'name': 'default_icon', 'icon': Icons.folder_outlined},
  ];

  @override
  void onInit() {
    super.onInit();
    debugPrint("[ProjectController] onInit CALLED");

    _authEverWorker = ever(_authController.currentUser, (firebaseUser) {
      debugPrint(
        "[ProjectController] Auth state changed. User: ${firebaseUser?.uid}",
      );
      if (firebaseUser != null) {
        debugPrint(
          "[ProjectController] User is authenticated. Initializing project data.",
        );
        _initializeProjectRelatedData(firebaseUser.uid);
      } else {
        debugPrint(
          "[ProjectController] User is NOT authenticated. Clearing project data.",
        );
        _clearAllProjectDataAndStreams();
      }
    });

    final initialUser = _authController.currentUser.value;
    if (initialUser != null) {
      debugPrint(
        "[ProjectController] onInit - User ALREADY authenticated (uid: ${initialUser.uid}). Initializing data.",
      );
      _initializeProjectRelatedData(initialUser.uid);
    } else {
      debugPrint(
        "[ProjectController] onInit - User NOT authenticated initially. Waiting for auth state change.",
      );
      _clearAllProjectDataAndStreams();
    }
  }

  void _initializeProjectRelatedData(String userId) {
    _bindProjectsStream();
    _bindProjectInvitationsStream();
    _fetchPendingProjectDeletionRequestsForCurrentUserAdmin();
  }

  void _clearAllProjectDataAndStreams() {
    debugPrint("[ProjectController] Clearing all project data and streams.");
    projects.clear();
    isLoadingProjects.value = false;
    projectListError.value =
        "Usuario no autenticado. Inicia sesión para ver tus proyectos.";

    projectInvitations.clear();
    isLoadingInvitations.value = false;
    pendingProjectDeletionRequests.clear();
    isLoadingDeletionRequests.value = false;
    _pendingDeletionRequestsSubscription?.cancel();
    _pendingDeletionRequestsSubscription = null;

    currentEditingProject.value = null;
    currentProjectRole.value = '';
    _resetFormFields();
  }

  void reloadProjects() {
    if (_authController.currentUser.value != null) {
      _bindProjectsStream();
      _bindProjectInvitationsStream();
      _fetchPendingProjectDeletionRequestsForCurrentUserAdmin();
    } else {
      debugPrint(
        "[ProjectController] reloadProjects - Cannot reload, user not authenticated.",
      );
    }
  }

  void _bindProjectsStream() {
    isLoadingProjects.value = true;
    projectListError.value = '';
    debugPrint(
      "[ProjectController] _bindProjectsStream - Binding projects stream.",
    );

    projects.bindStream(
      _projectService
          .getProjectsStream()
          .map((projectList) {
            isLoadingProjects.value = false;
            if (projectList.isNotEmpty) projectListError.value = '';
            if (currentEditingProject.value != null) {
              final updatedProject = projectList.firstWhereOrNull(
                (p) => p.id == currentEditingProject.value!.id,
              );
              if (updatedProject != null) {
                setCurrentProjectRole(updatedProject);
              }
            }
            return projectList;
          })
          .handleError((error, stackTrace) {
            debugPrint(
              "[ProjectController] Error in projects stream: $error\n$stackTrace",
            );
            projectListError.value =
                "Error al cargar proyectos: ${error.toString()}";
            isLoadingProjects.value = false;
            return <ProjectModel>[];
          }),
    );
  }

  void _bindProjectInvitationsStream() {
    isLoadingInvitations.value = true;
    debugPrint(
      "[ProjectController] _bindProjectInvitationsStream - Binding invitations stream.",
    );
    projectInvitations.bindStream(
      _projectService
          .getProjectInvitationsStream()
          .map((invitations) {
            isLoadingInvitations.value = false;
            return invitations;
          })
          .handleError((error, stackTrace) {
            debugPrint(
              "[ProjectController] Error in project invitations stream: $error\n$stackTrace",
            );
            isLoadingInvitations.value = false;
            return <ProjectInvitationModel>[];
          }),
    );
  }

  String? getCurrentUserRoleInProject(ProjectModel? project) {
    final currentUserId = _authController.currentUser.value?.uid;
    if (project == null || currentUserId == null) return null;
    for (String roleEntry in project.userRoles) {
      if (roleEntry.startsWith('$currentUserId:')) {
        return roleEntry.split(':')[1];
      }
    }
    return null;
  }

  bool isCurrentUserAdmin(ProjectModel? project) {
    final currentUserId = _authController.currentUser.value?.uid;
    if (project == null || currentUserId == null) return false;
    return project.adminUserId == currentUserId;
  }

  bool isCurrentUserMemberOfProject(ProjectModel project) {
    final currentUserId = _authController.currentUser.value?.uid;
    if (currentUserId == null) return false;
    if (isCurrentUserAdmin(project)) return true;
    return project.userRoles.any(
      (roleEntry) => roleEntry.startsWith('$currentUserId:'),
    );
  }

  void setCurrentProjectRole(ProjectModel project) {
    currentProjectRole.value = getCurrentUserRoleInProject(project) ?? "";
  }

  void navigateToAddProject() {
    if (_authController.currentUser.value == null) {
      Get.snackbar(
        "Autenticación Requerida",
        "Debes iniciar sesión para crear un proyecto.",
      );
      return;
    }
    currentEditingProject.value = null;
    _resetFormFields();
    Get.toNamed(AppRoutes.PROJECT_FORM);
  }

  void navigateToEditProject(ProjectModel project) {
    if (_authController.currentUser.value == null) {
      Get.snackbar(
        "Autenticación Requerida",
        "Debes iniciar sesión para editar un proyecto.",
      );
      return;
    }
    if (!isCurrentUserAdmin(project)) {
      Get.snackbar(
        "Permiso Denegado",
        "Solo el administrador puede editar los detalles del proyecto.",
      );
      return;
    }
    currentEditingProject.value = project;
    setCurrentProjectRole(project);
    nameController.text = project.name;
    descriptionController.text = project.description ?? '';
    selectedColor.value = project.projectColor;
    selectedIconName.value = project.iconName;
    Get.toNamed(AppRoutes.PROJECT_FORM);
  }

  void _resetFormFields() {
    nameController.clear();
    descriptionController.clear();
    selectedColor.value = predefinedColors.first;
    selectedIconName.value = predefinedIcons.firstWhere(
      (i) => i['name'] == 'default_icon',
    )['name'];
    inviteEmailController.clear();
    accessCodeController.clear();
    generatedAccessCode.value = '';
  }

  Future<void> saveProject() async {
    final currentUserId = _authController.currentUser.value?.uid;
    if (currentUserId == null) {
      Get.snackbar(
        "Error",
        "Usuario no autenticado. No se puede guardar el proyecto.",
      );
      isSavingProject.value = false;
      return;
    }
    if (projectFormKey.currentState?.validate() ?? false) {
      isSavingProject.value = true;
      try {
        if (isEditing) {
          if (currentEditingProject.value == null) {
            throw Exception("No hay proyecto para editar.");
          }
          ProjectModel projectToUpdate = currentEditingProject.value!.copyWith(
            name: nameController.text.trim(),
            description: descriptionController.text.trim().isNotEmpty
                ? descriptionController.text.trim()
                : null,
            colorHex: ProjectModel.colorToHex(selectedColor.value),
            iconName: selectedIconName.value,
          );
          await _projectService.updateProjectDetails(projectToUpdate);
          Get.snackbar(
            "Éxito",
            "Proyecto actualizado correctamente.",
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          ProjectModel newProjectData = ProjectModel(
            name: nameController.text.trim(),
            description: descriptionController.text.trim().isNotEmpty
                ? descriptionController.text.trim()
                : null,
            colorHex: ProjectModel.colorToHex(selectedColor.value),
            iconName: selectedIconName.value,
            adminUserId: '',
            userRoles: [],
            createdAt: Timestamp.now(),
          );
          await _projectService.addProject(newProjectData);
          Get.snackbar(
            "Éxito",
            "Proyecto creado correctamente.",
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        }
        _resetFormFields();
        Get.back();
      } catch (e) {
        Get.snackbar(
          "Error",
          "No se pudo guardar el proyecto: ${e.toString()}",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      } finally {
        isSavingProject.value = false;
      }
    }
  }

  Future<void> handleDeleteProjectAction(ProjectModel project) async {
    final currentUser = _authController.currentUser.value;
    if (currentUser == null) {
      Get.snackbar("Autenticación Requerida", "Debes iniciar sesión.");
      return;
    }

    if (!isCurrentUserAdmin(project)) {
      final existingRequest = pendingProjectDeletionRequests.firstWhereOrNull(
        (req) => req.data?['projectId'] == project.id && req.isRead == false,
      );
      if (existingRequest != null) {
        Get.snackbar(
          "Solicitud Existente",
          "Ya existe una solicitud de eliminación pendiente para este proyecto.",
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    }

    Get.defaultDialog(
      title: isCurrentUserAdmin(project)
          ? "Confirmar Eliminación"
          : "Solicitar Eliminación",
      middleText: isCurrentUserAdmin(project)
          ? "ADVERTENCIA: ¿Estás seguro de que quieres eliminar el proyecto '${project.name}' y TODAS sus tareas? Esta acción es irreversible."
          : "Vas a solicitar la eliminación del proyecto '${project.name}'. El administrador del proyecto (${project.adminUserId}) deberá aprobarlo.",
      textConfirm: isCurrentUserAdmin(project)
          ? "Sí, Eliminar Proyecto"
          : "Sí, Solicitar",
      textCancel: "Cancelar",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back();
        if (isCurrentUserAdmin(project)) {
          await _deleteProjectDirectly(project);
        } else {
          if (!isCurrentUserMemberOfProject(project)) {
            Get.snackbar(
              "Permiso Denegado",
              "No eres miembro de este proyecto para solicitar su eliminación.",
              snackPosition: SnackPosition.BOTTOM,
            );
            return;
          }
          await _createAndSendProjectDeletionRequest(project);
        }
      },
    );
  }

  Future<void> _deleteProjectDirectly(ProjectModel project) async {
    isLoadingProjects.value = true;
    try {
      debugPrint(
        "[ProjectController] Eliminando tareas para el proyecto ${project.id}...",
      );
      await _taskService.deleteAllTasksForProject(project.id!);
      debugPrint(
        "[ProjectController] Tareas eliminadas. Eliminando proyecto ${project.id}...",
      );

      await _projectService.deleteProject(project.id!);
      debugPrint("[ProjectController] Proyecto ${project.id} eliminado.");

      final pendingRequestsForThisProject = pendingProjectDeletionRequests
          .where(
            (req) =>
                req.data?['projectId'] == project.id && req.isRead == false,
          )
          .toList();
      for (var req in pendingRequestsForThisProject) {
        if (req.id != null) await _notificationController.markAsRead(req.id!);
      }

      Get.snackbar(
        "Proyecto Eliminado",
        "El proyecto '${project.name}' y sus tareas han sido eliminados.",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      if (currentEditingProject.value?.id == project.id) {
        currentEditingProject.value = null;
        currentProjectRole.value = "";
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudo eliminar el proyecto: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      debugPrint(
        "[ProjectController] Error eliminando proyecto directamente: $e",
      );
    } finally {
      isLoadingProjects.value = false;
    }
  }

  Future<void> _createAndSendProjectDeletionRequest(
    ProjectModel project,
  ) async {
    final requester = _authController.currentUser.value;
    if (requester == null) {
      Get.snackbar("Error", "No se pudo procesar la solicitud. Faltan datos.");
      return;
    }
    if (requester.uid == project.adminUserId) {
      return;
    }

    final String title = "Solicitud de Eliminación de Proyecto";
    final String body =
        "${requester.name ?? requester.email} (${requester.email}) solicita la eliminación del proyecto '${project.name}'.";

    Map<String, dynamic> notificationData = {
      'projectId': project.id!,
      'projectName': project.name,
      'projectAdminId': project.adminUserId,
      'requesterId': requester.uid,
      'requesterName': requester.name ?? requester.email,
      'requesterEmail': requester.email,
      'requestType': "project_deletion",
    };

    final AppNotificationModel appNotification = AppNotificationModel(
      title: title,
      body: body,
      type: AppNotificationType.projectDeletionRequest,
      data: notificationData,
      createdAt: Timestamp.now(),
      isRead: false,
      routeToNavigate: AppRoutes.PROJECTS_LIST,
    );

    try {
      await _authController.addUserNotification(
        project.adminUserId,
        appNotification,
      );
      debugPrint(
        "[ProjectController] Notificación de solicitud guardada para admin ${project.adminUserId}",
      );

      List<String>? adminTokens = await _authController.getUserFcmTokens(
        project.adminUserId,
      );
      if (adminTokens != null && adminTokens.isNotEmpty) {
        Map<String, String> pushDataPayload = {
          'type': 'new_project_deletion_request',
          'projectId': project.id!,
          'screen': AppRoutes.PROJECTS_LIST,
          'title': title,
          'body': "Revisa la solicitud de eliminación para '${project.name}'.",
        };
        for (String token in adminTokens) {
          await _notificationService.sendNotificationToDevice(
            targetDeviceToken: token,
            title: title,
            body: pushDataPayload['body']!,
            data: pushDataPayload,
          );
        }
      }
      Get.snackbar(
        "Solicitud Enviada",
        "Tu solicitud para eliminar '${project.name}' ha sido enviada al administrador.",
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudo enviar la solicitud: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      debugPrint(
        "[ProjectController] Error enviando solicitud de eliminación de proyecto: $e",
      );
    }
  }

  Future<void> _fetchPendingProjectDeletionRequestsForCurrentUserAdmin() async {
    final adminId = _authController.currentUser.value?.uid;
    if (adminId == null) {
      pendingProjectDeletionRequests.clear();
      return;
    }

    isLoadingDeletionRequests.value = true;
    _pendingDeletionRequestsSubscription?.cancel();

    _pendingDeletionRequestsSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(adminId)
        .collection('app_notifications')
        .where(
          'type',
          isEqualTo: AppNotificationType.projectDeletionRequest.toString(),
        )
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            pendingProjectDeletionRequests.value = snapshot.docs
                .map((doc) => AppNotificationModel.fromFirestore(doc))
                .toList();
            isLoadingDeletionRequests.value = false;
            debugPrint(
              "[ProjectController] Solicitudes de eliminación de proyecto cargadas: ${pendingProjectDeletionRequests.length}",
            );
          },
          onError: (error) {
            debugPrint(
              "[ProjectController] Error al cargar solicitudes de eliminación de proyecto: $error",
            );
            pendingProjectDeletionRequests.clear();
            isLoadingDeletionRequests.value = false;
          },
        );
  }

  Future<void> approveProjectDeletionRequest(
    AppNotificationModel request,
  ) async {
    final adminUser = _authController.currentUser.value;
    if (adminUser == null || request.data == null) {
      Get.snackbar("Error", "No autorizado o solicitud inválida.");
      return;
    }

    final requestData = request.data!;
    final String projectId = requestData['projectId'];
    final String projectName = requestData['projectName'];
    final String requesterId = requestData['requesterId'];
    final String? projectAdminIdFromRequest = requestData['projectAdminId'];

    if (adminUser.uid != projectAdminIdFromRequest) {
      Get.snackbar(
        "Error",
        "No eres el administrador designado para esta solicitud.",
      );
      return;
    }

    ProjectModel? projectToVerify;
    try {
      projectToVerify = await _projectService.getProjectById(projectId);
      if (projectToVerify == null ||
          projectToVerify.adminUserId != adminUser.uid) {
        Get.snackbar(
          "Error",
          "Proyecto no encontrado o no eres el administrador actual del proyecto.",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        await _notificationController.markAsRead(request.id!);
        return;
      }
    } catch (e) {
      Get.snackbar("Error", "No se pudo verificar el proyecto: $e");
      return;
    }

    isLoadingProjects.value = true;
    try {
      debugPrint(
        "[ProjectController] Aprobando eliminación para proyecto $projectId...",
      );
      await _taskService.deleteAllTasksForProject(projectId);
      debugPrint(
        "[ProjectController] Tareas eliminadas. Eliminando proyecto $projectId...",
      );
      await _projectService.deleteProject(projectId);
      debugPrint(
        "[ProjectController] Proyecto $projectId eliminado por aprobación.",
      );

      await _notificationController.markAsRead(request.id!);
      Get.snackbar(
        "Proyecto Eliminado",
        "El proyecto '$projectName' ha sido eliminado por aprobación.",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      await _sendProjectDeletionDecisionNotificationToRequester(
        requesterId: requesterId,
        requesterEmail: requestData['requesterEmail'],
        projectName: projectName,
        isApproved: true,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudo procesar la aprobación: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      debugPrint(
        "[ProjectController] Error aprobando solicitud ${request.id}: $e",
      );
    } finally {
      isLoadingProjects.value = false;
    }
  }

  Future<void> rejectProjectDeletionRequest(
    AppNotificationModel request,
  ) async {
    final adminUser = _authController.currentUser.value;
    if (adminUser == null || request.data == null) {
      Get.snackbar("Error", "No autorizado o solicitud inválida.");
      return;
    }

    final requestData = request.data!;
    final String projectName = requestData['projectName'];
    final String requesterId = requestData['requesterId'];
    final String? projectAdminIdFromRequest = requestData['projectAdminId'];

    if (adminUser.uid != projectAdminIdFromRequest) {
      Get.snackbar(
        "Error",
        "No eres el administrador designado para esta solicitud.",
      );
      return;
    }

    try {
      await _notificationController.markAsRead(request.id!);
      Get.snackbar(
        "Solicitud Rechazada",
        "La solicitud para eliminar '$projectName' ha sido rechazada.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );

      await _sendProjectDeletionDecisionNotificationToRequester(
        requesterId: requesterId,
        requesterEmail: requestData['requesterEmail'],
        projectName: projectName,
        isApproved: false,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudo procesar el rechazo: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      debugPrint(
        "[ProjectController] Error rechazando solicitud ${request.id}: $e",
      );
    }
  }

  Future<void> _sendProjectDeletionDecisionNotificationToRequester({
    required String requesterId,
    String? requesterEmail,
    required String projectName,
    required bool isApproved,
  }) async {
    final String title = isApproved
        ? "Solicitud Aprobada"
        : "Solicitud Rechazada";
    final String decision = isApproved ? "aprobada" : "rechazada";
    final String body =
        "Tu solicitud para eliminar el proyecto '$projectName' ha sido $decision por el administrador.";

    final AppNotificationModel feedbackNotification = AppNotificationModel(
      title: title,
      body: body,
      type: isApproved
          ? AppNotificationType.projectDeletionApproved
          : AppNotificationType.projectDeletionRejected,
      data: {
        'projectName': projectName,
        'decision': decision,
        'screen': AppRoutes.PROJECTS_LIST,
      },
      createdAt: Timestamp.now(),
    );

    await _authController.addUserNotification(
      requesterId,
      feedbackNotification,
    );

    List<String>? requesterTokens = await _authController.getUserFcmTokens(
      requesterId,
    );
    if (requesterTokens != null && requesterTokens.isNotEmpty) {
      Map<String, String> pushDataPayload = {
        'type': isApproved
            ? 'project_deletion_approved'
            : 'project_deletion_rejected',
        'title': title,
        'body': body,
        'screen': AppRoutes.PROJECTS_LIST,
      };
      for (String token in requesterTokens) {
        _notificationService.sendNotificationToDevice(
          targetDeviceToken: token,
          title: title,
          body: body,
          data: pushDataPayload,
        );
      }
    }
    debugPrint(
      "[ProjectController] Notificación de decisión enviada a $requesterId ($requesterEmail)",
    );
  }

  Future<void> performInviteUser(String projectId) async {
    if (_authController.currentUser.value == null) {
      Get.snackbar(
        "Autenticación Requerida",
        "Debes iniciar sesión para invitar usuarios.",
      );
      return;
    }
    final project = projects.firstWhereOrNull((p) => p.id == projectId);
    if (!isCurrentUserAdmin(project)) {
      Get.snackbar(
        "Permiso Denegado",
        "Solo el administrador puede invitar usuarios.",
      );
      return;
    }
    if (inviteEmailController.text.trim().isEmpty ||
        !GetUtils.isEmail(inviteEmailController.text.trim())) {
      Get.snackbar("Error", "Por favor, ingresa un correo electrónico válido.");
      return;
    }
    try {
      await _projectService.inviteUserToProject(
        projectId,
        inviteEmailController.text.trim(),
      );
      inviteEmailController.clear();
    } catch (e) {
      Get.snackbar("Error de Invitación", e.toString());
    }
  }

  Future<void> performGenerateAccessCode(String projectId) async {
    if (_authController.currentUser.value == null) {
      Get.snackbar(
        "Autenticación Requerida",
        "Debes iniciar sesión para generar códigos.",
      );
      return;
    }
    final project = projects.firstWhereOrNull((p) => p.id == projectId);
    if (!isCurrentUserAdmin(project)) {
      Get.snackbar(
        "Permiso Denegado",
        "Solo el administrador puede generar códigos de acceso.",
      );
      return;
    }
    try {
      final code = await _projectService.generateAccessCode(projectId);
      generatedAccessCode.value = code;
      Get.snackbar(
        "Código Generado",
        "Código de acceso: $code. Compártelo con tus colaboradores.",
        duration: const Duration(seconds: 6),
      );
    } catch (e) {
      Get.snackbar("Error", "No se pudo generar el código: ${e.toString()}");
    }
  }

  Future<void> performJoinProjectWithCode() async {
    if (_authController.currentUser.value == null) {
      Get.snackbar(
        "Autenticación Requerida",
        "Debes iniciar sesión para unirte a un proyecto.",
      );
      return;
    }
    if (accessCodeController.text.trim().isEmpty) {
      Get.snackbar("Error", "Por favor, ingresa un código de acceso.");
      return;
    }
    try {
      final success = await _projectService.joinProjectWithCode(
        accessCodeController.text.trim(),
      );
      if (success) {
        Get.snackbar(
          "Éxito",
          "Te has unido al proyecto.",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        accessCodeController.clear();
      }
    } catch (e) {
      Get.snackbar("Error al Unirse", e.toString());
    }
  }

  Future<void> performAcceptInvitation(String invitationId) async {
    if (_authController.currentUser.value == null) {
      Get.snackbar(
        "Autenticación Requerida",
        "Debes iniciar sesión para aceptar invitaciones.",
      );
      return;
    }
    try {
      await _projectService.acceptProjectInvitation(invitationId);
      Get.snackbar(
        "Invitación Aceptada",
        "Ahora eres miembro del proyecto.",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudo aceptar la invitación: ${e.toString()}",
      );
    }
  }

  Future<void> performDeclineInvitation(String invitationId) async {
    if (_authController.currentUser.value == null) {
      Get.snackbar(
        "Autenticación Requerida",
        "Debes iniciar sesión para declinar invitaciones.",
      );
      return;
    }
    try {
      await _projectService.declineProjectInvitation(invitationId);
      Get.snackbar(
        "Invitación Declinada",
        "Has rechazado la invitación.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudo declinar la invitación: ${e.toString()}",
      );
    }
  }

  Future<void> performLeaveProject(String projectId) async {
    if (_authController.currentUser.value == null) {
      Get.snackbar(
        "Autenticación Requerida",
        "Debes iniciar sesión para abandonar un proyecto.",
      );
      return;
    }
    Get.defaultDialog(
      title: "Abandonar Proyecto",
      middleText: "¿Estás seguro de que quieres abandonar este proyecto?",
      textConfirm: "Sí, abandonar",
      textCancel: "Cancelar",
      confirmTextColor: Colors.white,
      buttonColor: Colors.orange,
      onConfirm: () async {
        Get.back();
        try {
          await _projectService.leaveProject(projectId);
          Get.snackbar(
            "Has Abandonado el Proyecto",
            "",
            backgroundColor: Colors.blue,
            colorText: Colors.white,
          );
          if (currentEditingProject.value?.id == projectId) {
            currentEditingProject.value = null;
            currentProjectRole.value = "";
          }
        } catch (e) {
          Get.snackbar(
            "Error",
            "No se pudo abandonar el proyecto: ${e.toString()}",
          );
        }
      },
    );
  }

  Future<void> performRemoveMember(
    String projectId,
    String memberIdToRemove,
    String memberName,
  ) async {
    if (_authController.currentUser.value == null) {
      Get.snackbar(
        "Autenticación Requerida",
        "Debes iniciar sesión para remover miembros.",
      );
      return;
    }
    final project = projects.firstWhereOrNull((p) => p.id == projectId);
    if (!isCurrentUserAdmin(project)) {
      Get.snackbar(
        "Permiso Denegado",
        "Solo el administrador puede remover miembros.",
      );
      return;
    }
    Get.defaultDialog(
      title: "Remover Miembro",
      middleText:
          "¿Estás seguro de que quieres remover a '$memberName' de este proyecto?",
      textConfirm: "Sí, remover",
      textCancel: "Cancelar",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back();
        try {
          await _projectService.removeMemberFromProject(
            projectId,
            memberIdToRemove,
          );
          Get.snackbar(
            "Miembro Removido",
            "'$memberName' ha sido removido del proyecto.",
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        } catch (e) {
          Get.snackbar(
            "Error",
            "No se pudo remover al miembro: ${e.toString()}",
          );
        }
      },
    );
  }

  IconData getIconDataByName(String iconName) {
    final iconMap = predefinedIcons.firstWhere(
      (icon) => icon['name'] == iconName,
      orElse: () =>
          predefinedIcons.firstWhere((i) => i['name'] == 'default_icon'),
    );
    return iconMap['icon'] as IconData;
  }
}
