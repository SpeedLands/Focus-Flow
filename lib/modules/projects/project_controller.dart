import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:focus_flow/data/models/app_notification_model.dart';
import 'package:focus_flow/data/providers/notification_provider.dart';
import 'package:focus_flow/data/providers/project_invitation_provider.dart';
import 'package:focus_flow/data/providers/project_provider.dart';
import 'package:focus_flow/data/providers/task_provider.dart';
import 'package:focus_flow/modules/notifications/notifications_controller.dart';
import 'package:get/get.dart';
import 'package:focus_flow/data/models/project_model.dart';
import 'package:focus_flow/data/models/project_invitation_model.dart';
import 'package:focus_flow/modules/auth/auth_controller.dart';
import 'package:focus_flow/routes/app_routes.dart';

class ProjectController extends GetxController {
  final ProjectProvider _projectProvider = Get.find<ProjectProvider>();
  final ProjectInvitationProvider _projectInvitationProvider =
      Get.find<ProjectInvitationProvider>();
  final AuthController _authController = Get.find<AuthController>();
  final NotificationProvider _notificationProvider =
      Get.find<NotificationProvider>();
  final NotificationController _notificationController =
      Get.find<NotificationController>();
  final TaskProvider _taskProvider = Get.find<TaskProvider>();

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

  bool get isInitialLoading =>
      isLoadingProjects.value &&
      projects.isEmpty &&
      isLoadingDeletionRequests.value &&
      pendingProjectDeletionRequests.isEmpty &&
      isLoadingInvitations.value &&
      projectInvitations.isEmpty;

  // NUEVO: Getter para simplificar la condición de error
  bool get hasError => projectListError.value.isNotEmpty && projects.isEmpty;

  final RxString currentProjectRole = ''.obs;
  final RxList<ProjectInvitationModel> projectInvitations =
      <ProjectInvitationModel>[].obs;
  final RxBool isLoadingInvitations = false.obs;
  final TextEditingController inviteEmailController = TextEditingController();
  final TextEditingController accessCodeController = TextEditingController();
  final RxString generatedAccessCode = ''.obs;

  final Rx<ProjectModel?> selectedProjectForTv = Rx<ProjectModel?>(null);
  final RxInt selectedTvDetailViewIndex = 0.obs;
  final RxBool isLoadingTvDetails = false.obs;
  final RxList<Map<String, dynamic>> projectTaskStats =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> recentActivity =
      <Map<String, dynamic>>[].obs;

  final RxList<AppNotificationModel> pendingProjectDeletionRequests =
      <AppNotificationModel>[].obs;
  final RxBool isLoadingDeletionRequests = false.obs;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _pendingDeletionRequestsSubscription;

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
    debugPrint('[ProjectController] onInit CALLED');

    ever(_authController.currentUser, (firebaseUser) {
      if (firebaseUser != null) {
        _initializeProjectRelatedData(firebaseUser.uid);
      } else {
        _clearAllProjectDataAndStreams();
      }
    });

    final initialUser = _authController.currentUser.value;
    if (initialUser != null) {
      _initializeProjectRelatedData(initialUser.uid);
    } else {
      _clearAllProjectDataAndStreams();
    }
  }

  void _initializeProjectRelatedData(String userId) {
    _bindProjectsStream();
    _bindProjectInvitationsStream();
    _fetchPendingProjectDeletionRequestsForCurrentUserAdmin();
  }

  void _clearAllProjectDataAndStreams() {
    projects.clear();
    isLoadingProjects.value = false;
    projectListError.value =
        'Usuario no autenticado. Inicia sesión para ver tus proyectos.';

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
        '[ProjectController] reloadProjects - Cannot reload, user not authenticated.',
      );
    }
  }

  void showInviteUserDialog(BuildContext context, String projectId) {
    inviteEmailController.clear();
    Get.defaultDialog<void>(
      title: 'Invitar Usuario al Proyecto',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Ingresa el correo electrónico del usuario que quieres invitar.',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: inviteEmailController,
            decoration: const InputDecoration(
              labelText: 'Email del Invitado',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            onFieldSubmitted: (_) => performInviteUser(projectId),
          ),
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () => performInviteUser(projectId),
        child: const Text('ENVIAR INVITACIÓN'),
      ),
      cancel: ElevatedButton(
        onPressed: () => Get.back<Object>(),
        child: const Text('CANCELAR'),
      ),
    );
  }

  void _bindProjectsStream() {
    isLoadingProjects.value = true;
    projectListError.value = '';
    debugPrint(
      '[ProjectController] _bindProjectsStream - Binding projects stream.',
    );

    projects.bindStream(
      _projectProvider
          .getProjectsStream()
          .map((projectList) {
            isLoadingProjects.value = false;
            if (projectList.isNotEmpty) {
              projectListError.value = '';
              if (selectedProjectForTv.value == null) {
                selectProjectForTv(projectList.first);
              }
            }
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
          .handleError((Object error, Object stackTrace) {
            debugPrint(
              '[ProjectController] Error in projects stream: $error\n$stackTrace',
            );
            projectListError.value =
                'Error al cargar proyectos: ${error.toString()}';
            isLoadingProjects.value = false;
            return <ProjectModel>[];
          }),
    );
  }

  void showAccessCodeDialog() {
    Get.defaultDialog<void>(
      title: 'Código de Acceso del Proyecto',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Este es el código de acceso del proyecto. Puedes compartirlo con otros usuarios para que se unan.',
          ),
          const SizedBox(height: 16),
          Obx(
            () => SelectableText(
              generatedAccessCode.value,
              style: Get.textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Copiar Código'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: generatedAccessCode.value));
              Get.snackbar(
                'Código Copiado',
                'El código de acceso ha sido copiado al portapapeles.',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 2),
              );
            },
          ),
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () => Get.back<Object>(),
        child: const Text('CERRAR'),
      ),
    );
  }

  void selectProjectForTv(ProjectModel? project) {
    if (project == null || project.id == selectedProjectForTv.value?.id) return;

    selectedProjectForTv.value = project;
    // Resetea a la vista principal (gráfica) cada vez que cambias de proyecto
    selectedTvDetailViewIndex.value = 0;
    // Carga los detalles para la nueva selección
    fetchDetailsForTv();
  }

  void changeTvDetailView(int index) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // Mueve aquí el código que cambia el estado
      selectedTvDetailViewIndex.value = index;
      fetchDetailsForTv();
    });
  }

  Future<void> fetchDetailsForTv() async {
    final project = selectedProjectForTv.value;
    if (project == null) return;

    isLoadingTvDetails.value = true;
    try {
      switch (selectedTvDetailViewIndex.value) {
        case 0: // Gráfico de barras
          await fetchProjectTaskStats();
          break;
        case 1: // Actividad Reciente (tareas completadas)
          await fetchRecentActivityForTv(project.id!);
          break;
        case 2: // Miembros (ya están en el modelo de proyecto, no se necesita fetch)
          break;
        case 3: // Código de acceso (se genera bajo demanda)
          generatedAccessCode.value = '...'; // Placeholder
          break;
      }
    } catch (e) {
      debugPrint('Error fetching TV details: $e');
      // Opcional: mostrar un snackbar de error
    } finally {
      isLoadingTvDetails.value = false;
    }
  }

  // En ProjectController.dart

  Future<void> fetchProjectTaskStats() async {
    // Usamos List<Future<...>> y Future.wait para ejecutar las consultas en paralelo,
    // lo cual es mucho más eficiente que un bucle con `await` dentro.
    final List<Future<Map<String, dynamic>>> futures = projects.map((
      proj,
    ) async {
      // Obtenemos ambos conteos al mismo tiempo
      final totalCountFuture = _taskProvider.getTotalTasksCount(proj.id!);
      final pendingCountFuture = _taskProvider.getPendingTasksCount(proj.id!);

      // Esperamos a que ambas consultas terminen para este proyecto
      final List<int> counts = await Future.wait([
        totalCountFuture,
        pendingCountFuture,
      ]);
      final int totalCount = counts[0];
      final int pendingCount = counts[1];

      return {
        'project': proj,
        'totalTasks': totalCount, // <-- Dato nuevo
        'pendingTasks': pendingCount,
      };
    }).toList();

    // Esperamos a que todos los proyectos terminen de obtener sus datos
    final List<Map<String, dynamic>> stats = await Future.wait(futures);

    // Actualizamos la lista observable una sola vez al final
    projectTaskStats.value = stats;
  }

  Future<void> fetchRecentActivityForTv(String projectId) async {
    // Implementación simplificada: Obtener últimas 5 tareas completadas
    final tasksStream = _taskProvider.getTasksStream(projectId);
    final allTasks = await tasksStream.first;

    final completedTasks = allTasks.where((t) => t.isCompleted).toList();
    completedTasks.sort((a, b) => b.completedAt!.compareTo(a.completedAt!));

    final recent = completedTasks.take(10).map((task) {
      // Idealmente, aquí buscarías el nombre del usuario desde un provider de usuarios
      return {
        'text': "'${task.name}' completada",
        'user': task.completedBy ?? 'Desconocido', // ID del usuario
        'time': task.completedAt!,
      };
    }).toList();

    recentActivity.value = recent;
  }

  void _bindProjectInvitationsStream() {
    isLoadingInvitations.value = true;
    debugPrint(
      '[ProjectController] _bindProjectInvitationsStream - Binding invitations stream.',
    );
    projectInvitations.bindStream(
      _projectInvitationProvider
          .getInvitationsStream()
          .map((invitations) {
            isLoadingInvitations.value = false;
            return invitations;
          })
          .handleError((Object error, Object stackTrace) {
            debugPrint(
              '[ProjectController] Error in project invitations stream: $error\n$stackTrace',
            );
            isLoadingInvitations.value = false;
            return <ProjectInvitationModel>[];
          }),
    );
  }

  String? getCurrentUserRoleInProject(ProjectModel? project) {
    final currentUserId = _authController.currentUser.value?.uid;
    if (project == null || currentUserId == null) return null;
    for (final String roleEntry in project.userRoles) {
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
    currentProjectRole.value = getCurrentUserRoleInProject(project) ?? '';
  }

  void navigateToAddProject() {
    if (_authController.currentUser.value == null) {
      Get.snackbar(
        'Autenticación Requerida',
        'Debes iniciar sesión para crear un proyecto.',
      );
      return;
    }
    currentEditingProject.value = null;
    _resetFormFields();
    Get.toNamed<Object>(AppRoutes.PROJECT_FORM);
  }

  void navigateToEditProject(ProjectModel project) {
    if (_authController.currentUser.value == null) {
      Get.snackbar(
        'Autenticación Requerida',
        'Debes iniciar sesión para editar un proyecto.',
      );
      return;
    }
    if (!isCurrentUserAdmin(project)) {
      Get.snackbar(
        'Permiso Denegado',
        'Solo el administrador puede editar los detalles del proyecto.',
      );
      return;
    }
    currentEditingProject.value = project;
    setCurrentProjectRole(project);
    nameController.text = project.name;
    descriptionController.text = project.description ?? '';
    selectedColor.value = project.projectColor;
    selectedIconName.value = project.iconName;
    Get.toNamed<Object>(AppRoutes.PROJECT_FORM);
  }

  void showJoinWithCodeDialog(BuildContext context) {
    accessCodeController.clear();
    Get.defaultDialog<void>(
      title: 'Unirse a Proyecto con Código',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Ingresa el código de acceso del proyecto al que quieres unirte.',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: accessCodeController,
            decoration: const InputDecoration(
              labelText: 'Código de Acceso',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.vpn_key),
              hintText: 'ABCXYZ',
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            maxLength: 10,
            onFieldSubmitted: (_) => performJoinProjectWithCode(),
          ),
        ],
      ),
      confirm: ElevatedButton(
        onPressed: performJoinProjectWithCode,
        child: const Text('UNIRME'),
      ),
      cancel: ElevatedButton(
        onPressed: () => Get.back<Object>(),
        child: const Text('CANCELAR'),
      ),
    );
  }

  void _resetFormFields() {
    nameController.clear();
    descriptionController.clear();
    selectedColor.value = predefinedColors.first;
    final defaultIconData = predefinedIcons.firstWhere(
      (i) => (i['name'] as String) == 'default_icon',
      orElse: () => predefinedIcons.first, // Fallback si no se encuentra
    );
    selectedIconName.value = defaultIconData['name'] as String;
    inviteEmailController.clear();
    accessCodeController.clear();
    generatedAccessCode.value = '';
  }

  Future<void> saveProject() async {
    final currentUserId = _authController.currentUser.value?.uid;
    if (currentUserId == null) {
      Get.snackbar(
        'Error',
        'Usuario no autenticado. No se puede guardar el proyecto.',
      );
      isSavingProject.value = false;
      return;
    }
    if (projectFormKey.currentState?.validate() ?? false) {
      isSavingProject.value = true;
      try {
        if (isEditing) {
          if (currentEditingProject.value == null) {
            throw Exception('No hay proyecto para editar.');
          }
          final ProjectModel projectToUpdate = currentEditingProject.value!
              .copyWith(
                name: nameController.text.trim(),
                description: descriptionController.text.trim().isNotEmpty
                    ? descriptionController.text.trim()
                    : null,
                colorHex: ProjectModel.colorToHex(selectedColor.value),
                iconName: selectedIconName.value,
              );
          await _projectProvider.updateProject(projectToUpdate);
          Get.snackbar(
            'Éxito',
            'Proyecto actualizado correctamente.',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          final ProjectModel newProjectData = ProjectModel(
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
          await _projectProvider.addProject(newProjectData);
          Get.snackbar(
            'Éxito',
            'Proyecto creado correctamente.',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        }
        _resetFormFields();
        Get.back<Object>();
      } catch (e) {
        Get.snackbar(
          'Error',
          'No se pudo guardar el proyecto: ${e.toString()}',
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
      Get.snackbar('Autenticación Requerida', 'Debes iniciar sesión.');
      return;
    }

    if (!isCurrentUserAdmin(project)) {
      final existingRequest = pendingProjectDeletionRequests.firstWhereOrNull((
        req,
      ) {
        final reqData = req.data;
        if (reqData == null) return false;
        // Hacemos cast explícito para la comparación
        return (reqData['projectId'] as String?) == project.id &&
            req.isRead == false;
      });
      if (existingRequest != null) {
        Get.snackbar(
          'Solicitud Existente',
          'Ya existe una solicitud de eliminación pendiente para este proyecto.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    }

    await Get.defaultDialog<void>(
      title: isCurrentUserAdmin(project)
          ? 'Confirmar Eliminación'
          : 'Solicitar Eliminación',
      middleText: isCurrentUserAdmin(project)
          ? "ADVERTENCIA: ¿Estás seguro de que quieres eliminar el proyecto '${project.name}' y TODAS sus tareas? Esta acción es irreversible."
          : "Vas a solicitar la eliminación del proyecto '${project.name}'. El administrador del proyecto (${project.adminUserId}) deberá aprobarlo.",
      textConfirm: isCurrentUserAdmin(project)
          ? 'Sí, Eliminar Proyecto'
          : 'Sí, Solicitar',
      textCancel: 'Cancelar',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back<Object>();
        if (isCurrentUserAdmin(project)) {
          await _deleteProjectDirectly(project);
        } else {
          if (!isCurrentUserMemberOfProject(project)) {
            Get.snackbar(
              'Permiso Denegado',
              'No eres miembro de este proyecto para solicitar su eliminación.',
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
        '[ProjectController] Eliminando tareas para el proyecto ${project.id}...',
      );
      await _taskProvider.deleteAllTasksForProject(project.id!);
      debugPrint(
        '[ProjectController] Tareas eliminadas. Eliminando proyecto ${project.id}...',
      );

      await _projectProvider.deleteProject(project.id!);
      debugPrint('[ProjectController] Proyecto ${project.id} eliminado.');

      final pendingRequestsForThisProject = pendingProjectDeletionRequests
          .where((req) {
            final reqData = req.data;
            if (reqData == null) return false;
            return (reqData['projectId'] as String?) == project.id &&
                req.isRead == false;
          })
          .toList();
      for (final req in pendingRequestsForThisProject) {
        if (req.id != null) await _notificationController.markAsRead(req.id!);
      }

      Get.snackbar(
        'Proyecto Eliminado',
        "El proyecto '${project.name}' y sus tareas han sido eliminados.",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      if (currentEditingProject.value?.id == project.id) {
        currentEditingProject.value = null;
        currentProjectRole.value = '';
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo eliminar el proyecto: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      debugPrint(
        '[ProjectController] Error eliminando proyecto directamente: $e',
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
      Get.snackbar('Error', 'No se pudo procesar la solicitud. Faltan datos.');
      return;
    }
    if (requester.uid == project.adminUserId) {
      return;
    }

    const String title = 'Solicitud de Eliminación de Proyecto';
    final String body =
        "${requester.name ?? requester.email} (${requester.email}) solicita la eliminación del proyecto '${project.name}'.";

    final Map<String, dynamic> notificationData = {
      'projectId': project.id!,
      'projectName': project.name,
      'projectAdminId': project.adminUserId,
      'requesterId': requester.uid,
      'requesterName': requester.name ?? requester.email,
      'requesterEmail': requester.email,
      'requestType': 'project_deletion',
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
      await _notificationProvider.saveNotification(
        userId: project.adminUserId,
        notification: appNotification,
      );
      debugPrint(
        '[ProjectController] Notificación de solicitud guardada para admin ${project.adminUserId}',
      );

      final List<String>? adminTokens = await _notificationProvider
          .getUserTokensById(project.adminUserId);
      if (adminTokens != null && adminTokens.isNotEmpty) {
        final Map<String, String> pushDataPayload = {
          'type': 'new_project_deletion_request',
          'projectId': project.id!,
          'screen': AppRoutes.PROJECTS_LIST,
          'title': title,
          'body': "Revisa la solicitud de eliminación para '${project.name}'.",
        };
        for (final String token in adminTokens) {
          await _notificationProvider.sendNotificationToToken(
            token: token,
            title: title,
            body: pushDataPayload['body']!,
            data: pushDataPayload,
          );
        }
      }
      Get.snackbar(
        'Solicitud Enviada',
        "Tu solicitud para eliminar '${project.name}' ha sido enviada al administrador.",
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo enviar la solicitud: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      debugPrint(
        '[ProjectController] Error enviando solicitud de eliminación de proyecto: $e',
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
    await _pendingDeletionRequestsSubscription?.cancel();

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
              '[ProjectController] Solicitudes de eliminación de proyecto cargadas: ${pendingProjectDeletionRequests.length}',
            );
          },
          onError: (Object error) {
            debugPrint(
              '[ProjectController] Error al cargar solicitudes de eliminación de proyecto: $error',
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
      Get.snackbar('Error', 'No autorizado o solicitud inválida.');
      return;
    }

    final requestData = request.data!;
    final String? projectId = requestData['projectId'] as String?;
    final String? projectName = requestData['projectName'] as String?;
    final String? requesterId = requestData['requesterId'] as String?;
    final String? projectAdminIdFromRequest =
        requestData['projectAdminId'] as String?;
    final String? requesterEmail = requestData['requesterEmail'] as String?;

    if (adminUser.uid != projectAdminIdFromRequest) {
      Get.snackbar(
        'Error',
        'No eres el administrador designado para esta solicitud.',
      );
      return;
    }

    if (projectId == null || projectName == null || requesterId == null) {
      Get.snackbar('Error', 'Datos de solicitud incompletos.');
      return;
    }

    ProjectModel? projectToVerify;
    try {
      projectToVerify = await _projectProvider.getProjectById(projectId);
      if (projectToVerify == null ||
          projectToVerify.adminUserId != adminUser.uid) {
        Get.snackbar(
          'Error',
          'Proyecto no encontrado o no eres el administrador actual del proyecto.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        await _notificationController.markAsRead(request.id!);
        return;
      }
    } catch (e) {
      Get.snackbar('Error', 'No se pudo verificar el proyecto: $e');
      return;
    }

    isLoadingProjects.value = true;
    try {
      debugPrint(
        '[ProjectController] Aprobando eliminación para proyecto $projectId...',
      );
      await _taskProvider.deleteAllTasksForProject(projectId);
      debugPrint(
        '[ProjectController] Tareas eliminadas. Eliminando proyecto $projectId...',
      );
      await _projectProvider.deleteProject(projectId);
      debugPrint(
        '[ProjectController] Proyecto $projectId eliminado por aprobación.',
      );

      await _notificationController.markAsRead(request.id!);
      Get.snackbar(
        'Proyecto Eliminado',
        "El proyecto '$projectName' ha sido eliminado por aprobación.",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      await _sendProjectDeletionDecisionNotificationToRequester(
        requesterId: requesterId,
        requesterEmail: requesterEmail,
        projectName: projectName,
        isApproved: true,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo procesar la aprobación: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      debugPrint(
        '[ProjectController] Error aprobando solicitud ${request.id}: $e',
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
      Get.snackbar('Error', 'No autorizado o solicitud inválida.');
      return;
    }

    final requestData = request.data!;
    final String? projectName = requestData['projectName'] as String?;
    final String? requesterId = requestData['requesterId'] as String?;
    final String? projectAdminIdFromRequest =
        requestData['projectAdminId'] as String?;
    final String? requesterEmail = requestData['requesterEmail'] as String?;

    // Comprobaciones de nulidad
    if (projectName == null || requesterId == null) {
      Get.snackbar('Error', 'Datos de solicitud incompletos.');
      return;
    }

    if (adminUser.uid != projectAdminIdFromRequest) {
      Get.snackbar(
        'Error',
        'No eres el administrador designado para esta solicitud.',
      );
      return;
    }

    try {
      await _notificationController.markAsRead(request.id!);
      Get.snackbar(
        'Solicitud Rechazada',
        "La solicitud para eliminar '$projectName' ha sido rechazada.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );

      await _sendProjectDeletionDecisionNotificationToRequester(
        requesterId: requesterId,
        requesterEmail: requesterEmail,
        projectName: projectName,
        isApproved: false,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo procesar el rechazo: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      debugPrint(
        '[ProjectController] Error rechazando solicitud ${request.id}: $e',
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
        ? 'Solicitud Aprobada'
        : 'Solicitud Rechazada';
    final String decision = isApproved ? 'aprobada' : 'rechazada';
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

    await _notificationProvider.saveNotification(
      userId: requesterId,
      notification: feedbackNotification,
    );

    final List<String>? requesterTokens = await _notificationProvider
        .getUserTokensById(requesterId);
    if (requesterTokens != null && requesterTokens.isNotEmpty) {
      final Map<String, String> pushDataPayload = {
        'type': isApproved
            ? 'project_deletion_approved'
            : 'project_deletion_rejected',
        'title': title,
        'body': body,
        'screen': AppRoutes.PROJECTS_LIST,
      };
      for (final String token in requesterTokens) {
        await _notificationProvider.sendNotificationToToken(
          token: token,
          title: title,
          body: body,
          data: pushDataPayload,
        );
      }
    }
    debugPrint(
      '[ProjectController] Notificación de decisión enviada a $requesterId ($requesterEmail)',
    );
  }

  Future<void> performInviteUser(String projectId) async {
    if (_authController.currentUser.value == null) {
      Get.snackbar(
        'Autenticación Requerida',
        'Debes iniciar sesión para invitar usuarios.',
      );
      return;
    }
    final project = projects.firstWhereOrNull((p) => p.id == projectId);
    if (!isCurrentUserAdmin(project)) {
      Get.snackbar(
        'Permiso Denegado',
        'Solo el administrador puede invitar usuarios.',
      );
      return;
    }
    if (inviteEmailController.text.trim().isEmpty ||
        !GetUtils.isEmail(inviteEmailController.text.trim())) {
      Get.snackbar('Error', 'Por favor, ingresa un correo electrónico válido.');
      return;
    }
    try {
      await _projectInvitationProvider.inviteUser(
        projectId,
        project!.name,
        inviteEmailController.text.trim(),
      );
      inviteEmailController.clear();
    } catch (e) {
      Get.snackbar('Error de Invitación', e.toString());
    }
  }

  Future<void> performGenerateAccessCode(String projectId) async {
    if (_authController.currentUser.value == null) {
      Get.snackbar(
        'Autenticación Requerida',
        'Debes iniciar sesión para generar códigos.',
      );
      return;
    }
    final project = projects.firstWhereOrNull((p) => p.id == projectId);
    if (!isCurrentUserAdmin(project)) {
      Get.snackbar(
        'Permiso Denegado',
        'Solo el administrador puede generar códigos de acceso.',
      );
      return;
    }
    try {
      final code = await _projectProvider.generateAccessCode(projectId);
      generatedAccessCode.value = code;
      Get.snackbar(
        'Código Generado',
        'Código de acceso: $code. Compártelo con tus colaboradores.',
        duration: const Duration(seconds: 6),
      );
    } catch (e) {
      Get.snackbar('Error', 'No se pudo generar el código: ${e.toString()}');
    }
  }

  Future<void> performJoinProjectWithCode() async {
    final currentUser = _authController.currentUser.value;
    if (currentUser == null) {
      Get.snackbar(
        'Autenticación Requerida',
        'Debes iniciar sesión para unirte a un proyecto.',
      );
      return;
    }
    if (accessCodeController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Por favor, ingresa un código de acceso.');
      return;
    }

    isSavingProject.value = true;

    try {
      final ProjectModel? joinedProject = await _projectProvider
          .joinProjectWithCode(accessCodeController.text.trim());

      if (joinedProject != null) {
        Get.snackbar(
          'Éxito',
          "Te has unido al proyecto '${joinedProject.name}'.",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        accessCodeController.clear();

        if (joinedProject.adminUserId != currentUser.uid) {
          final List<String>? adminTokens = await _notificationProvider
              .getUserTokensById(joinedProject.adminUserId);

          if (adminTokens != null && adminTokens.isNotEmpty) {
            final String joiningUserName =
                currentUser.name ?? currentUser.email;
            const String title = 'Nuevo Miembro en Proyecto';
            final String body =
                "$joiningUserName se ha unido a tu proyecto '${joinedProject.name}' mediante código de acceso.";

            final Map<String, String> pushDataPayload = {
              'type': 'new_member_joined_via_code',
              'projectId': joinedProject.id!,
              'projectName': joinedProject.name,
              'joiningUserId': currentUser.uid,
              'joiningUserName': joiningUserName,
            };

            final AppNotificationModel adminNotification = AppNotificationModel(
              title: title,
              body: body,
              type: AppNotificationType.projectDeletionApproved,
              data: pushDataPayload,
              createdAt: Timestamp.now(),
              isRead: false,
            );
            await _notificationProvider.saveNotification(
              userId: joinedProject.adminUserId,
              notification: adminNotification,
            );

            for (final String token in adminTokens) {
              await _notificationProvider.sendNotificationToToken(
                token: token,
                title: title,
                body: body,
                data: pushDataPayload,
              );
            }
            debugPrint(
              '[ProjectController] Notificación de nuevo miembro enviada al admin ${joinedProject.adminUserId}',
            );
          }
        }
      } else {
        Get.snackbar(
          'Error al Unirse',
          'Código de acceso inválido o no se pudo unir al proyecto.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error al Unirse',
        'Ocurrió un error: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      debugPrint('[ProjectController] Error al unirse con código: $e');
    } finally {
      isSavingProject.value = false;
    }
  }

  Future<void> performAcceptInvitation(String invitationId) async {
    final currentUser = _authController.currentUser.value;
    if (currentUser == null) {
      Get.snackbar(
        'Autenticación Requerida',
        'Debes iniciar sesión para aceptar invitaciones.',
      );
      return;
    }
    try {
      final ProjectInvitationModel? invitation =
          await _projectInvitationProvider.getInvitationById(invitationId);
      if (invitation == null) {
        Get.snackbar('Error', 'Invitación no encontrada.');
        return;
      }

      await _projectInvitationProvider.acceptInvitation(invitationId);
      Get.snackbar(
        'Invitación Aceptada',
        'Ahora eres miembro del proyecto.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      final ProjectModel? project = await _projectProvider.getProjectById(
        invitation.projectId,
      );
      if (project != null && project.adminUserId != currentUser.uid) {
        final List<String>? adminTokens = await _notificationProvider
            .getUserTokensById(project.adminUserId);
        if (adminTokens != null && adminTokens.isNotEmpty) {
          final String userName = currentUser.name ?? currentUser.email;
          const String title = 'Invitación Aceptada';
          final String body =
              "$userName ha aceptado tu invitación para unirse al proyecto '${project.name}'.";
          final Map<String, String> pushDataPayload = {
            'type': 'invitation_accepted',
            'projectId': project.id!,
            'projectName': project.name,
            'userId': currentUser.uid,
            'userName': userName,
            'screen': AppRoutes.PROJECTS_LIST,
          };

          final AppNotificationModel adminNotification = AppNotificationModel(
            title: title,
            body: body,
            type: AppNotificationType.projectDeletionApproved,
            data: pushDataPayload,
            createdAt: Timestamp.now(),
            isRead: false,
            routeToNavigate: AppRoutes.PROJECTS_LIST,
          );
          await _notificationProvider.saveNotification(
            userId: project.adminUserId,
            notification: adminNotification,
          );

          for (final String token in adminTokens) {
            await _notificationProvider.sendNotificationToToken(
              token: token,
              title: title,
              body: body,
              data: pushDataPayload,
            );
          }
          debugPrint(
            '[ProjectController] Notificación de aceptación de invitación enviada al admin ${project.adminUserId}',
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo aceptar la invitación: ${e.toString()}',
      );
    }
  }

  Future<void> performDeclineInvitation(String invitationId) async {
    final currentUser = _authController.currentUser.value;
    if (currentUser == null) {
      Get.snackbar(
        'Autenticación Requerida',
        'Debes iniciar sesión para declinar invitaciones.',
      );
      return;
    }
    try {
      final ProjectInvitationModel? invitation =
          await _projectInvitationProvider.getInvitationById(invitationId);
      if (invitation == null) {
        Get.snackbar('Error', 'Invitación no encontrada.');
        return;
      }

      await _projectInvitationProvider.declineInvitation(invitationId);
      Get.snackbar(
        'Invitación Declinada',
        'Has rechazado la invitación.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );

      final ProjectModel? project = await _projectProvider.getProjectById(
        invitation.projectId,
      );
      if (project != null && project.adminUserId != currentUser.uid) {
        final List<String>? adminTokens = await _notificationProvider
            .getUserTokensById(project.adminUserId);
        if (adminTokens != null && adminTokens.isNotEmpty) {
          final String userName = currentUser.name ?? currentUser.email;
          const String title = 'Invitación Rechazada';
          final String body =
              "$userName ha rechazado tu invitación para unirse al proyecto '${project.name}'.";
          final Map<String, String> pushDataPayload = {
            'type': 'invitation_rejected',
            'projectId': project.id!,
            'projectName': project.name,
            'userId': currentUser.uid,
            'userName': userName,
          };

          final AppNotificationModel adminNotification = AppNotificationModel(
            title: title,
            body: body,
            type: AppNotificationType.projectDeletionRejected,
            data: pushDataPayload,
            createdAt: Timestamp.now(),
            isRead: false,
          );
          await _notificationProvider.saveNotification(
            userId: project.adminUserId,
            notification: adminNotification,
          );

          for (final String token in adminTokens) {
            await _notificationProvider.sendNotificationToToken(
              token: token,
              title: title,
              body: body,
              data: pushDataPayload,
            );
          }
          debugPrint(
            '[ProjectController] Notificación de rechazo de invitación enviada al admin ${project.adminUserId}',
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo declinar la invitación: ${e.toString()}',
      );
    }
  }

  Future<void> performLeaveProject(String projectId) async {
    if (_authController.currentUser.value == null) {
      Get.snackbar(
        'Autenticación Requerida',
        'Debes iniciar sesión para abandonar un proyecto.',
      );
      return;
    }
    await Get.defaultDialog<void>(
      title: 'Abandonar Proyecto',
      middleText: '¿Estás seguro de que quieres abandonar este proyecto?',
      textConfirm: 'Sí, abandonar',
      textCancel: 'Cancelar',
      confirmTextColor: Colors.white,
      buttonColor: Colors.orange,
      onConfirm: () async {
        Get.back<Object>();
        try {
          await _projectProvider.leaveProject(projectId);
          Get.snackbar(
            'Has Abandonado el Proyecto',
            '',
            backgroundColor: Colors.blue,
            colorText: Colors.white,
          );
          if (currentEditingProject.value?.id == projectId) {
            currentEditingProject.value = null;
            currentProjectRole.value = '';
          }
        } catch (e) {
          Get.snackbar(
            'Error',
            'No se pudo abandonar el proyecto: ${e.toString()}',
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
        'Autenticación Requerida',
        'Debes iniciar sesión para remover miembros.',
      );
      return;
    }
    final project = projects.firstWhereOrNull((p) => p.id == projectId);
    if (!isCurrentUserAdmin(project)) {
      Get.snackbar(
        'Permiso Denegado',
        'Solo el administrador puede remover miembros.',
      );
      return;
    }
    await Get.defaultDialog<void>(
      title: 'Remover Miembro',
      middleText:
          "¿Estás seguro de que quieres remover a '$memberName' de este proyecto?",
      textConfirm: 'Sí, remover',
      textCancel: 'Cancelar',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back<Object>();
        try {
          Get.snackbar(
            'Miembro Removido',
            "'$memberName' ha sido removido del proyecto.",
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        } catch (e) {
          Get.snackbar(
            'Error',
            'No se pudo remover al miembro: ${e.toString()}',
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
