import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:focus_flow/data/models/app_notification_model.dart';
import 'package:focus_flow/data/providers/notification_provider.dart';
import 'package:focus_flow/data/providers/project_provider.dart';
import 'package:focus_flow/data/providers/task_provider.dart';
import 'package:focus_flow/modules/notifications/notifications_controller.dart';
import 'package:get/get.dart';
import 'package:focus_flow/data/models/task_model.dart';
import 'package:focus_flow/data/models/project_model.dart';
import 'package:focus_flow/modules/auth/auth_controller.dart';
import 'package:focus_flow/routes/app_routes.dart';

enum TaskViewType { kanban, eisenhower, timeline, swimlanes }

class TaskController extends GetxController {
  final TaskProvider _taskService = Get.find<TaskProvider>();
  final AuthController _authController = Get.find<AuthController>();
  final NotificationProvider _notificationProvider =
      Get.find<NotificationProvider>();
  final ProjectProvider _projectService = Get.find<ProjectProvider>();
  final NotificationController _notificationController =
      Get.find<NotificationController>();

  final Rx<TaskViewType> currentTvView = TaskViewType.kanban.obs;

  List<TaskModel> get pendingTasks =>
      tasks.where((t) => !t.isCompleted).toList();
  List<TaskModel> get completedTasks =>
      tasks.where((t) => t.isCompleted).toList();

  final RxList<TaskModel> tasks = <TaskModel>[].obs;
  final RxBool isLoadingTasks = true.obs;
  final RxString taskListError = ''.obs;
  final RxString currentProjectId = ''.obs;
  final Rx<ProjectModel?> currentProjectData = Rx<ProjectModel?>(null);

  final GlobalKey<FormState> taskFormKey = GlobalKey<FormState>();
  final TextEditingController taskNameController = TextEditingController();
  final TextEditingController taskDescriptionController =
      TextEditingController();
  final Rx<TaskPriority> selectedPriority = Rx<TaskPriority>(
    TaskPriority.media,
  );
  final Rx<DateTime?> selectedDueDate = Rx<DateTime?>(null);
  final Rx<TaskModel?> currentEditingTask = Rx<TaskModel?>(null);
  bool get isEditingTask => currentEditingTask.value != null;
  final RxBool isSavingTask = false.obs;
  final List<TaskPriority> taskPriorities = TaskPriority.values;

  final RxList<AppNotificationModel> pendingTaskModificationRequests =
      <AppNotificationModel>[].obs;
  final RxBool isLoadingRequests = false.obs;

  @override
  void onInit() {
    super.onInit();
    ever(currentProjectId, (String projId) {
      if (projId.isNotEmpty) {
        _loadProjectDetailsAndBindTasks(projId);
        if (isCurrentUserAdminForCurrentProject) {
          _fetchPendingTaskModificationRequests(projId);
        } else {
          pendingTaskModificationRequests.clear();
        }
      } else {
        tasks.clear();
        currentProjectData.value = null;
        isLoadingTasks.value = false;
        taskListError.value = "";
        pendingTaskModificationRequests.clear();
      }
    });

    ever(currentProjectData, (_) {
      if (currentProjectId.value.isNotEmpty &&
          isCurrentUserAdminForCurrentProject) {
        _fetchPendingTaskModificationRequests(currentProjectId.value);
      } else {
        pendingTaskModificationRequests.clear();
      }
    });
  }

  Future<void> _loadProjectDetailsAndBindTasks(String projectId) async {
    isLoadingTasks.value = true;
    taskListError.value = "";
    try {
      currentProjectData.value = await _projectService.getProjectById(
        projectId,
      );
      if (currentProjectData.value == null) {
        taskListError.value =
            "No se pudo cargar el proyecto o no tienes acceso.";
        isLoadingTasks.value = false;
        tasks.clear();
        return;
      }
      _bindTasksStreamForProject(projectId);
      if (isCurrentUserAdminForCurrentProject) {
        _fetchPendingTaskModificationRequests(projectId);
      }
    } catch (e) {
      taskListError.value = "Error cargando detalles del proyecto: $e";
      isLoadingTasks.value = false;
      tasks.clear();
    }
  }

  bool get isCurrentUserAdminForCurrentProject {
    final currentUserId = _authController.currentUser.value?.uid;
    if (currentProjectData.value == null || currentUserId == null) return false;
    return currentProjectData.value!.adminUserId == currentUserId;
  }

  bool get isCurrentUserMemberForCurrentProject {
    final currentUserId = _authController.currentUser.value?.uid;
    if (currentProjectData.value == null || currentUserId == null) return false;
    if (isCurrentUserAdminForCurrentProject) return true;
    return currentProjectData.value!.userRoles.any(
      (roleEntry) => roleEntry.startsWith('$currentUserId:'),
    );
  }

  void loadTasksForProject(String projectId) {
    if (projectId.isEmpty) {
      taskListError.value = "ID de proyecto no válido.";
      currentProjectId.value = '';
      return;
    }
    if (currentProjectId.value != projectId) {
      currentProjectId.value = projectId;
    } else if (tasks.isEmpty &&
        !isLoadingTasks.value &&
        taskListError.value.isNotEmpty) {
      _loadProjectDetailsAndBindTasks(projectId);
    }
  }

  void _bindTasksStreamForProject(String projectId) {
    taskListError.value = '';
    if (_authController.isAuthenticated.value &&
        currentProjectData.value != null) {
      tasks.bindStream(
        _taskService.getTasksStream(projectId).handleError((error) {
          debugPrint(
            "Error en stream de tareas para proyecto $projectId: $error",
          );
          taskListError.value = "Error al cargar tareas: ${error.toString()}";
          isLoadingTasks.value = false;
          return Stream.value([]);
        }),
      );
      once(tasks, (_) {
        if (isLoadingTasks.value) isLoadingTasks.value = false;
        if (tasks.isNotEmpty) taskListError.value = '';
      });
      ever(tasks, (_) {
        if (isLoadingTasks.value) isLoadingTasks.value = false;
      });
    } else {
      tasks.clear();
      isLoadingTasks.value = false;
      if (currentProjectData.value == null && projectId.isNotEmpty) {
      } else if (!_authController.isAuthenticated.value) {
        taskListError.value = "Usuario no autenticado.";
      }
    }
  }

  void navigateToAddTask({String? projectId, String? projectName}) {
    final targetProjectId = projectId ?? currentProjectId.value;
    final targetProjectName = projectName;
    if (targetProjectId.isEmpty) {
      Get.snackbar(
        "Error",
        "No se ha seleccionado un proyecto para añadir la tarea.",
      );
      return;
    }
    if (!isCurrentUserMemberForCurrentProject &&
        currentProjectData.value?.id == targetProjectId) {
      Get.snackbar("Permiso Denegado", "No eres miembro de este proyecto.");
      return;
    }
    currentEditingTask.value = null;
    _resetTaskFormFields();
    Get.toNamed(
      AppRoutes.TASK_FORM,
      arguments: {
        'projectId': targetProjectId,
        'projectName': targetProjectName,
      },
    );
  }

  void navigateToEditTask(TaskModel task) {
    currentEditingTask.value = task;
    taskNameController.text = task.name;
    taskDescriptionController.text = task.description ?? '';
    selectedPriority.value = task.priority;
    selectedDueDate.value = task.dueDate?.toDate();
    Get.toNamed(AppRoutes.TASK_FORM, arguments: {'projectId': task.projectId});
  }

  void _resetTaskFormFields() {
    taskNameController.clear();
    taskDescriptionController.clear();
    selectedPriority.value = TaskPriority.media;
    selectedDueDate.value = null;
  }

  Future<void> saveTask() async {
    if (!(taskFormKey.currentState?.validate() ?? false)) return;
    isSavingTask.value = true;

    final editorId = _authController.currentUser.value?.uid;
    final projIdForSave =
        currentEditingTask.value?.projectId ?? currentProjectId.value;

    if (editorId == null || projIdForSave.isEmpty) {
      Get.snackbar("Error", "Usuario o proyecto no identificado.");
      isSavingTask.value = false;
      return;
    }

    if (!isCurrentUserMemberForCurrentProject && !isEditingTask) {
      Get.snackbar(
        "Permiso Denegado",
        "No eres miembro de este proyecto para crear tareas.",
      );
      isSavingTask.value = false;
      return;
    }

    TaskModel taskData = TaskModel(
      id: isEditingTask ? currentEditingTask.value!.id : null,
      projectId: projIdForSave,
      name: taskNameController.text.trim(),
      description: taskDescriptionController.text.trim().isNotEmpty
          ? taskDescriptionController.text.trim()
          : null,
      priority: selectedPriority.value,
      dueDate: selectedDueDate.value != null
          ? Timestamp.fromDate(selectedDueDate.value!)
          : null,
      isCompleted: isEditingTask
          ? currentEditingTask.value!.isCompleted
          : false,
      createdBy: isEditingTask ? currentEditingTask.value!.createdBy : editorId,
      createdAt: isEditingTask
          ? currentEditingTask.value!.createdAt
          : Timestamp.now(),
      updatedAt: Timestamp.now(),
    );

    try {
      if (isEditingTask) {
        if (!isCurrentUserAdminForCurrentProject) {
          await _createAndSendModificationRequest(
            taskOriginal: currentEditingTask.value!,
            requestType: "edición",
            proposedChangesTaskModel: taskData,
          );
          Get.snackbar(
            "Solicitud Enviada",
            "Tu solicitud para editar la tarea ha sido enviada al administrador.",
          );
        } else {
          await _taskService.updateTaskDetails(taskData);
          Get.snackbar("Éxito", "Tarea actualizada.");
          await _sendTaskChangeNotification(
            projectId: projIdForSave,
            action: "actualizada",
            taskName: taskData.name,
            taskId: taskData.id!,
          );
        }
      } else {
        final docRef = await _taskService.addTask(projIdForSave, taskData);
        Get.snackbar("Éxito", "Tarea creada.");
        await _sendTaskChangeNotification(
          projectId: projIdForSave,
          action: "creada",
          taskName: taskData.name,
          taskId: docRef!,
        );
      }
      _resetTaskFormFields();
      Get.back();
    } catch (e) {
      Get.snackbar("Error", "No se pudo guardar la tarea: ${e.toString()}");
    } finally {
      isSavingTask.value = false;
    }
  }

  Map<String, List<TaskModel>> get eisenhowerTasks {
    final now = DateTime.now();
    final urgentDueDate = now.add(
      const Duration(days: 3),
    ); // Consideramos urgente si vence en 3 días

    final Map<String, List<TaskModel>> categorizedTasks = {
      'important_urgent': [],
      'important_not_urgent': [],
      'not_important_urgent': [],
      'not_important_not_urgent': [],
    };

    for (var task in pendingTasks) {
      // Solo clasificamos tareas pendientes
      final bool isImportant = task.priority == TaskPriority.alta;
      final bool isUrgent =
          task.dueDate != null &&
          task.dueDate!.toDate().isBefore(urgentDueDate);

      if (isImportant && isUrgent) {
        categorizedTasks['important_urgent']!.add(task);
      } else if (isImportant && !isUrgent) {
        categorizedTasks['important_not_urgent']!.add(task);
      } else if (!isImportant && isUrgent) {
        categorizedTasks['not_important_urgent']!.add(task);
      } else {
        categorizedTasks['not_important_not_urgent']!.add(task);
      }
    }
    return categorizedTasks;
  }

  Map<DateTime, List<TaskModel>> get timelineTasks {
    final Map<DateTime, List<TaskModel>> groupedTasks = {};
    final now = DateTime.now();
    final limitDate = now.add(const Duration(days: 30));

    final tasksWithDueDate = pendingTasks.where(
      (task) =>
          task.dueDate != null &&
          task.dueDate!.toDate().isAfter(
            now.subtract(const Duration(days: 1)),
          ) &&
          task.dueDate!.toDate().isBefore(limitDate),
    );

    for (var task in tasksWithDueDate) {
      final date = task.dueDate!.toDate();
      // Normalizamos la fecha a medianoche para agrupar por día
      final dayKey = DateTime(date.year, date.month, date.day);
      if (groupedTasks[dayKey] == null) {
        groupedTasks[dayKey] = [];
      }
      groupedTasks[dayKey]!.add(task);
    }
    return groupedTasks;
  }

  Map<String, List<TaskModel>> get tasksByMember {
    final Map<String, List<TaskModel>> groupedTasks = {};
    for (var task in pendingTasks) {
      final memberId = task.createdBy;
      if (groupedTasks[memberId] == null) {
        groupedTasks[memberId] = [];
      }
      groupedTasks[memberId]!.add(task);
    }
    return groupedTasks;
  }

  Future<String> getMemberName(String userId) async {
    // Si el usuario es el admin del proyecto actual
    // Busca en la lista de miembros
    if (currentProjectData.value != null) {
      for (var role in currentProjectData.value!.userRoles) {
        if (role.startsWith('$userId:')) {
          return role.split(':')[1]; // Retorna el nombre del miembro
        }
      }
    }
    // Fallback: si no se encuentra, retorna un identificador
    return 'Miembro ($userId.substring(0, 6))';
  }

  Future<void> deleteTask(TaskModel task) async {
    Get.defaultDialog(
      title: isCurrentUserAdminForCurrentProject
          ? "Confirmar Eliminación"
          : "Solicitar Eliminación",
      middleText: isCurrentUserAdminForCurrentProject
          ? "¿Estás seguro de que quieres eliminar esta tarea?"
          : "¿Estás seguro de que quieres solicitar la eliminación de esta tarea? El administrador del proyecto deberá aprobarlo.",
      textConfirm: isCurrentUserAdminForCurrentProject
          ? "Sí, eliminar"
          : "Sí, solicitar",
      textCancel: "Cancelar",
      onConfirm: () async {
        Get.back();
        if (!isCurrentUserAdminForCurrentProject) {
          await _createAndSendModificationRequest(
            taskOriginal: task,
            requestType: "eliminación",
          );
          Get.snackbar(
            "Solicitud Enviada",
            "Tu solicitud para eliminar la tarea ha sido enviada al administrador.",
          );
        } else {
          try {
            await _taskService.deleteTask(task.projectId, task.id!);
            Get.snackbar("Éxito", "Tarea eliminada.");
            await _sendTaskChangeNotification(
              projectId: task.projectId,
              action: "eliminada",
              taskName: task.name,
              taskId: task.id!,
            );
          } catch (e) {
            Get.snackbar(
              "Error",
              "No se pudo eliminar la tarea: ${e.toString()}",
            );
          }
        }
      },
    );
  }

  Future<void> _createAndSendModificationRequest({
    required TaskModel taskOriginal,
    required String requestType,
    TaskModel? proposedChangesTaskModel,
  }) async {
    final project = currentProjectData.value;
    final requester = _authController.currentUser.value;

    if (project == null || requester == null) {
      Get.snackbar(
        "Error",
        "No se pudo procesar la solicitud. Faltan datos del proyecto o usuario.",
      );
      debugPrint(
        "Error en _createAndSendModificationRequest: proyecto, adminId o requester es null.",
      );
      return;
    }

    if (requester.uid == project.adminUserId) {
      debugPrint(
        "_createAndSendModificationRequest: El solicitante es el admin, no se crea solicitud.",
      );
      return;
    }

    final String title = "Solicitud de $requestType de tarea";
    final String body =
        "${requester.name ?? requester.email} solicita la $requestType de la tarea '${taskOriginal.name}' en el proyecto '${project.name}'.";

    Map<String, dynamic> notificationData = {
      'projectId': project.id,
      'projectName': project.name,
      'taskId': taskOriginal.id!,
      'taskName': taskOriginal.name,
      'requesterId': requester.uid,
      'requesterName': requester.name ?? requester.email,
      'requestType': requestType,
    };

    if (requestType == "edición" && proposedChangesTaskModel != null) {
      notificationData['proposedChanges'] = proposedChangesTaskModel.toJson();
    }

    final AppNotificationModel appNotification = AppNotificationModel(
      title: title,
      body: body,
      type: AppNotificationType.taskModificationRequest,
      data: notificationData,
      createdAt: Timestamp.now(),
      isRead: false,
      routeToNavigate: AppRoutes.TASKS_LIST,
    );

    final currentUserId = _authController.currentUser.value?.uid;

    for (String roleEntry in project.userRoles) {
      final memberId = roleEntry.split(':')[0];
      if (memberId != currentUserId) {
        await _notificationProvider.saveNotification(
          userId: memberId,
          notification: appNotification,
        );
      }
    }

    if (project.adminUserId != currentUserId &&
        !project.userRoles.any((r) => r.startsWith(project.adminUserId))) {
      await _notificationProvider.saveNotification(
        userId: project.adminUserId,
        notification: appNotification,
      );
    }

    try {
      debugPrint(
        "AppNotification de solicitud de $requestType guardada para admin ${project.adminUserId}",
      );

      List<String>? adminTokens = await _notificationProvider.getUserTokensById(
        project.adminUserId,
      );
      if (adminTokens != null && adminTokens.isNotEmpty) {
        Map<String, String> pushDataPayload = {
          'type': 'new_task_modification_request',
          'projectId': ?project.id,
          'screen': AppRoutes.NOTIFICATIONS_LIST,
          'title': title,
          'body': body,
        };
        for (String token in adminTokens) {
          await _notificationProvider.sendNotificationToToken(
            token: token,
            title: title,
            body: "Tienes una nueva solicitud de tarea para revisar.",
            data: pushDataPayload,
          );
        }
        debugPrint("Push notification de solicitud enviada al admin.");
      }
    } catch (e) {
      debugPrint("Error al enviar solicitud de modificación: $e");
      Get.snackbar("Error", "No se pudo enviar la solicitud al administrador.");
    }
  }

  StreamSubscription? _pendingRequestsSubscription;
  Future<void> _fetchPendingTaskModificationRequests(String projectId) async {
    if (!isCurrentUserAdminForCurrentProject) {
      pendingTaskModificationRequests.clear();
      return;
    }
    isLoadingRequests.value = true;
    final adminId = _authController.currentUser.value?.uid;
    if (adminId == null) {
      isLoadingRequests.value = false;
      return;
    }

    _pendingRequestsSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(adminId)
        .collection('app_notifications')
        .where(
          'type',
          isEqualTo: AppNotificationType.taskModificationRequest.toString(),
        )
        .where('data.projectId', isEqualTo: projectId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            pendingTaskModificationRequests.value = snapshot.docs
                .map((doc) => AppNotificationModel.fromFirestore(doc))
                .toList();
            isLoadingRequests.value = false;
          },
          onError: (error) {
            debugPrint("Error al cargar solicitudes pendientes: $error");
            pendingTaskModificationRequests.clear();
            isLoadingRequests.value = false;
          },
        );
  }

  @override
  void onClose() {
    _pendingRequestsSubscription?.cancel();
    super.onClose();
  }

  Future<void> approveTaskModificationRequest(
    AppNotificationModel request,
  ) async {
    if (!isCurrentUserAdminForCurrentProject || request.data == null) {
      Get.snackbar("Error", "No tienes permiso o la solicitud es inválida.");
      return;
    }

    final requestData = request.data!;
    final String taskId = requestData['taskId'];
    final String taskName = requestData['taskName'];
    final String projectId = requestData['projectId'];
    final String requestType = requestData['requestType'];
    final String requesterId = requestData['requesterId'];

    try {
      if (requestType == "edición") {
        if (requestData['proposedChanges'] == null) {
          Get.snackbar(
            "Error",
            "No se encontraron los cambios propuestos para la edición.",
          );
          return;
        }
        final TaskModel updatedTask = TaskModel.fromJson(
          Map<String, dynamic>.from(requestData['proposedChanges']),
        );
        await _taskService.updateTaskDetails(updatedTask);
        Get.snackbar("Éxito", "Tarea '$taskName' actualizada según solicitud.");

        await _sendTaskChangeNotification(
          projectId: projectId,
          action: "actualizada_por_solicitud",
          taskName: updatedTask.name,
          taskId: taskId,
          details: "Aprobada por el admin.",
        );
      } else if (requestType == "eliminación") {
        await _taskService.deleteTask(projectId, taskId);
        Get.snackbar("Éxito", "Tarea '$taskName' eliminada según solicitud.");
        await _sendTaskChangeNotification(
          projectId: projectId,
          action: "eliminada_por_solicitud",
          taskName: taskName,
          taskId: taskId,
          details: "Aprobada por el admin.",
        );
      }

      await _notificationController.markAsRead(request.id!);

      await _sendApprovalRejectionNotificationToRequester(
        requesterId: requesterId,
        taskName: taskName,
        projectName: requestData['projectName'],
        requestType: requestType,
        isApproved: true,
      );
      _fetchPendingTaskModificationRequests(projectId);
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudo procesar la solicitud: ${e.toString()}",
      );
      debugPrint("Error aprobando solicitud ${request.id}: $e");
    }
  }

  Future<void> rejectTaskModificationRequest(
    AppNotificationModel request,
  ) async {
    if (!isCurrentUserAdminForCurrentProject || request.data == null) {
      Get.snackbar("Error", "No tienes permiso o la solicitud es inválida.");
      return;
    }
    final requestData = request.data!;
    final String taskName = requestData['taskName'];
    final String projectId = requestData['projectId'];
    final String requesterId = requestData['requesterId'];
    final String requestType = requestData['requestType'];

    try {
      await _notificationController.markAsRead(request.id!);

      Get.snackbar(
        "Solicitud Rechazada",
        "La solicitud para '$taskName' ha sido rechazada.",
      );

      await _sendApprovalRejectionNotificationToRequester(
        requesterId: requesterId,
        taskName: taskName,
        projectName: requestData['projectName'],
        requestType: requestType,
        isApproved: false,
      );
      _fetchPendingTaskModificationRequests(projectId);
    } catch (e) {
      Get.snackbar("Error", "No se pudo procesar el rechazo: ${e.toString()}");
      debugPrint("Error rechazando solicitud ${request.id}: $e");
    }
  }

  Future<void> _sendApprovalRejectionNotificationToRequester({
    required String requesterId,
    required String taskName,
    required String projectName,
    required String requestType,
    required bool isApproved,
  }) async {
    final String title = isApproved
        ? "Solicitud Aprobada"
        : "Solicitud Rechazada";
    final String decision = isApproved ? "aprobada" : "rechazada";
    final String body =
        "Tu solicitud de $requestType para la tarea '$taskName' en el proyecto '$projectName' ha sido $decision por el administrador.";

    final AppNotificationModel feedbackNotification = AppNotificationModel(
      title: title,
      body: body,
      type: isApproved
          ? AppNotificationType.taskModificationApproved
          : AppNotificationType.taskModificationRejected,
      data: {
        'taskName': taskName,
        'projectName': projectName,
        'decision': decision,
      },
      createdAt: Timestamp.now(),
    );

    await _notificationProvider.saveNotification(
      userId: requesterId,
      notification: feedbackNotification,
    );

    List<String>? requesterTokens = await _notificationProvider
        .getUserTokensById(requesterId);
    if (requesterTokens != null && requesterTokens.isNotEmpty) {
      Map<String, String> pushDataPayload = {
        'type': isApproved ? 'task_request_approved' : 'task_request_rejected',
        'title': title,
        'body': body,
      };
      for (String token in requesterTokens) {
        _notificationProvider.sendNotificationToToken(
          token: token,
          title: title,
          body: body,
          data: pushDataPayload,
        );
      }
    }
  }

  Future<void> toggleTaskCompletion(TaskModel task) async {
    if (!isCurrentUserMemberForCurrentProject) {
      Get.snackbar("Permiso Denegado", "No eres miembro de este proyecto.");
      return;
    }
    bool newCompletionStatus = !task.isCompleted;
    try {
      await _taskService.toggleTaskCompletion(
        task.projectId,
        task.id!,
        newCompletionStatus,
      );
      if (newCompletionStatus) {
        await _sendTaskCompletedNotification(task);
      } else {
        await _sendTaskChangeNotification(
          projectId: task.projectId,
          action: "marcada_como_pendiente",
          taskName: task.name,
          taskId: task.id!,
          details: "Ahora está marcada como pendiente ⏳.",
        );
      }
    } catch (e) {
      Get.snackbar("Error", "No se pudo actualizar el estado: ${e.toString()}");
    }
  }

  Future<void> _sendTaskCompletedNotification(TaskModel task) async {
    ProjectModel? project = currentProjectData.value;
    if (project == null || project.id != task.projectId) {
      project = await _projectService.getProjectById(task.projectId);
      if (project == null) {
        debugPrint(
          "No se pudo obtener el proyecto para enviar notificación de tarea completada.",
        );
        return;
      }
    }

    final currentUserId = _authController.currentUser.value?.uid;
    final userName =
        _authController.currentUser.value?.name ??
        _authController.currentUser.value?.email ??
        "Alguien";
    String title = "¡Tarea Completada en '${project.name}'! 🎉";
    String body = "$userName ha completado la tarea: '${task.name}'.";

    List<String> targetTokens =
        await _getProjectMemberTokensExcludingCurrentUser(
          project,
          currentUserId,
        );

    if (targetTokens.isEmpty) {
      debugPrint(
        "No hay otros miembros para notificar que la tarea '${task.name}' fue completada.",
      );
    }

    final AppNotificationModel appNotif = AppNotificationModel(
      title: title,
      body: body,
      type: AppNotificationType.taskCompleted,
      data: {
        'projectId': task.projectId,
        'projectName': project.name,
        'taskId': task.id!,
        'completedBy': userName,
      },
      createdAt: Timestamp.now(),
      routeToNavigate: AppRoutes.TASKS_LIST,
    );

    for (String roleEntry in project.userRoles) {
      final memberId = roleEntry.split(':')[0];
      if (memberId != currentUserId) {
        await _notificationProvider.saveNotification(
          userId: memberId,
          notification: appNotif,
        );
      }
    }
    if (project.adminUserId != currentUserId &&
        !project.userRoles.any((r) => r.startsWith(project!.adminUserId))) {
      await _notificationProvider.saveNotification(
        userId: project.adminUserId,
        notification: appNotif,
      );
    }

    if (targetTokens.isNotEmpty) {
      Map<String, String> notificationDataPayload = {
        'type': 'task_completed',
        'projectId': task.projectId,
        'projectName': project.name,
        'screen': AppRoutes.TASKS_LIST,
        'taskId': task.id!,
        'title': title,
        'body': body,
      };
      for (String token in targetTokens) {
        await _notificationProvider.sendNotificationToToken(
          token: token,
          title: title,
          body: body,
          data: notificationDataPayload,
        );
      }
    }
  }

  Future<List<String>> _getProjectMemberTokensExcludingCurrentUser(
    ProjectModel project,
    String? currentUserId,
  ) async {
    List<String> targetTokens = [];
    if (project.adminUserId != currentUserId) {
      List<String>? adminTokens = await _notificationProvider.getUserTokensById(
        project.adminUserId,
      );
      if (adminTokens != null) targetTokens.addAll(adminTokens);
    }
    for (String roleEntry in project.userRoles) {
      final memberId = roleEntry.split(':')[0];
      if (memberId != currentUserId && memberId != project.adminUserId) {
        List<String>? memberTokens = await _notificationProvider
            .getUserTokensById(memberId);
        if (memberTokens != null) targetTokens.addAll(memberTokens);
      }
    }
    return targetTokens.toSet().toList();
  }

  Future<void> _sendTaskChangeNotification({
    required String projectId,
    required String action,
    required String taskName,
    required String taskId,
    String? details,
  }) async {
    ProjectModel? project = currentProjectData.value;
    if (project == null || project.id != projectId) {
      project = await _projectService.getProjectById(projectId);
      if (project == null) {
        debugPrint(
          "No se pudo obtener el proyecto para enviar notificaciones de tarea.",
        );
        return;
      }
    }

    final currentUserId = _authController.currentUser.value?.uid;
    final userName =
        _authController.currentUser.value?.name ??
        _authController.currentUser.value?.email ??
        "Alguien";
    String title = "";
    String body = "";

    switch (action) {
      case "creada":
        title = "Nueva Tarea en '${project.name}' ✨";
        body = "$userName ha creado la tarea: '$taskName'.";
        break;
      case "actualizada":
        title = "Tarea Actualizada en '${project.name}' 🔄";
        body = "$userName ha actualizado la tarea: '$taskName'.";
        break;
      case "eliminada":
        title = "Tarea Eliminada de '${project.name}' 🗑️";
        body = "$userName ha eliminado la tarea: '$taskName'.";
        break;
      case "marcada_como_pendiente":
        title = "Estado de Tarea en '${project.name}'";
        body = "$userName actualizó la tarea '$taskName'.";
        break;
      case "actualizada_por_solicitud":
        title = "Tarea Actualizada en '${project.name}'";
        body =
            "La tarea '$taskName' fue actualizada (solicitud aprobada por admin).";
        break;
      case "eliminada_por_solicitud":
        title = "Tarea Eliminada de '${project.name}'";
        body =
            "La tarea '$taskName' fue eliminada (solicitud aprobada por admin).";
        break;
      default:
        debugPrint("Acción de notificación de tarea desconocida: $action");
        return;
    }
    if (details != null) body += " $details";

    List<String> targetTokens =
        await _getProjectMemberTokensExcludingCurrentUser(
          project,
          currentUserId,
        );

    final AppNotificationModel appNotif = AppNotificationModel(
      title: title,
      body: body,
      type: AppNotificationType.generic,
      data: {'projectId': projectId, 'taskId': taskId, 'action': action},
      createdAt: Timestamp.now(),
      routeToNavigate: AppRoutes.TASKS_LIST,
    );

    for (String roleEntry in project.userRoles) {
      final memberId = roleEntry.split(':')[0];
      if (memberId != currentUserId) {
        await _notificationProvider.saveNotification(
          userId: memberId,
          notification: appNotif,
        );
      }
    }
    if (project.adminUserId != currentUserId &&
        !project.userRoles.any((r) => r.startsWith(project!.adminUserId))) {
      await _notificationProvider.saveNotification(
        userId: project.adminUserId,
        notification: appNotif,
      );
    }

    if (targetTokens.isEmpty) {
      debugPrint(
        "No hay otros miembros en el proyecto para notificar (push) sobre la tarea '$taskName'.",
      );
      return;
    }

    Map<String, String> notificationDataPayload = {
      'type': 'task_event',
      'projectId': projectId,
      'projectName': project.name,
      'screen': AppRoutes.TASKS_LIST,
      'actionPerformed': action,
      'title': title,
      'body': body,
      'adminUserIdForProject': project.adminUserId,
    };
    if (taskId.isNotEmpty) notificationDataPayload['taskId'] = taskId;

    for (String token in targetTokens) {
      await _notificationProvider.sendNotificationToToken(
        token: token,
        title: title,
        body: body,
        data: notificationDataPayload,
      );
    }
  }

  Future<void> pickDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDueDate.value ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && picked != selectedDueDate.value) {
      selectedDueDate.value = picked;
    }
  }
}
