import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:focus_flow/modules/tasks/tasks_controller.dart';
import 'package:focus_flow/data/models/task_model.dart';
import 'package:getwidget/getwidget.dart';
import 'package:intl/intl.dart';

class TasksListScreen extends GetView<TaskController> {
  const TasksListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = Get.arguments ?? {};
    final String projectId = args['projectId'] ?? '';
    final String projectName = args['projectName'] ?? 'Tareas';

    final screenWidth = Get.width;
    final bool isTV = screenWidth > 800 && Get.height > 500;
    final bool isWatch = screenWidth < 300;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.currentProjectId.value != projectId ||
          (controller.tasks.isEmpty &&
              !controller.isLoadingTasks.value &&
              controller.taskListError.value.isEmpty)) {
        controller.loadTasksForProject(projectId);
      }
    });

    if (isWatch) {
      return _buildWatchTasksScreen(context, projectId, projectName);
    } else if (isTV) {
      return _buildTvTasksScreen(context, projectId, projectName);
    } else {
      return _buildMobileTasksScreen(
        context,
        projectId,
        projectName,
        isTV: false,
      );
    }
  }

  Widget _buildMobileTasksScreen(
    BuildContext context,
    String projectId,
    String projectName, {
    required bool isTV,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: GFAppBar(
        title: Text(projectName),
        leading: GFIconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
          type: GFButtonType.transparent,
        ),
        actions: [
          GFIconButton(
            icon: const Icon(Icons.add_task_outlined, color: Colors.white),
            onPressed: () => controller.navigateToAddTask(projectId: projectId),
            type: GFButtonType.transparent,
          ),
        ],
      ),
      body: Column(
        children: [
          Obx(() {
            if (controller.isCurrentUserAdminForCurrentProject &&
                (controller.isLoadingRequests.value ||
                    controller.pendingTaskModificationRequests.isNotEmpty)) {
              return _buildPendingRequestsSection(context, isTV: isTV);
            }
            return const SizedBox.shrink();
          }),
          Expanded(
            child: Obx(() {
              if (controller.isLoadingTasks.value && controller.tasks.isEmpty) {
                if (!(controller.isCurrentUserAdminForCurrentProject &&
                    controller.isLoadingRequests.value)) {
                  return const Center(
                    child: GFLoader(type: GFLoaderType.circle),
                  );
                }
              }
              if (controller.taskListError.value.isNotEmpty) {
                return _buildErrorState(context, isTV: isTV);
              }

              final pendingTasks = controller.tasks
                  .where((t) => !t.isCompleted)
                  .toList();
              final completedTasks = controller.tasks
                  .where((t) => t.isCompleted)
                  .toList();

              if (!controller.isLoadingTasks.value &&
                  pendingTasks.isEmpty &&
                  completedTasks.isEmpty &&
                  !(controller.isCurrentUserAdminForCurrentProject &&
                      controller.pendingTaskModificationRequests.isNotEmpty)) {
                return _buildEmptyState(context, projectId, isTV: isTV);
              }

              return DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    Material(
                      color:
                          Theme.of(context).appBarTheme.backgroundColor ??
                          colorScheme.surface,
                      elevation: 1,
                      child: TabBar(
                        indicatorColor: GFColors.PRIMARY,
                        labelColor: GFColors.PRIMARY,
                        unselectedLabelColor: Colors.grey[600],
                        tabs: [
                          Tab(text: "PENDIENTES (${pendingTasks.length})"),
                          Tab(text: "COMPLETADAS (${completedTasks.length})"),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildTasksListView(
                            context,
                            pendingTasks,
                            "No hay tareas pendientes.",
                            projectId,
                            isTV: isTV,
                            isCompletedTab: false,
                          ),
                          _buildTasksListView(
                            context,
                            completedTasks,
                            "No hay tareas completadas.",
                            projectId,
                            isTV: isTV,
                            isCompletedTab: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: (controller.isCurrentUserMemberForCurrentProject)
          ? FloatingActionButton(
              onPressed: () =>
                  controller.navigateToAddTask(projectId: projectId),
              backgroundColor: GFColors.PRIMARY,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildWatchTasksScreen(
    BuildContext context,
    String projectId,
    String projectName,
  ) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          projectName,
          style: const TextStyle(fontSize: 15, color: Colors.white),
        ),
        backgroundColor: Colors.grey[900],
        centerTitle: true,
        leading: GFIconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.white),
          onPressed: () => Get.back(),
          type: GFButtonType.transparent,
        ),
        actions: [
          GFIconButton(
            icon: const Icon(Icons.add, size: 20, color: Colors.white),
            onPressed: () => controller.navigateToAddTask(projectId: projectId),
            type: GFButtonType.transparent,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingTasks.value && controller.tasks.isEmpty) {
          return const Center(
            child: GFLoader(type: GFLoaderType.circle, size: GFSize.SMALL),
          );
        }
        if (controller.taskListError.value.isNotEmpty) {
          return Center(
            child: Text(
              controller.taskListError.value,
              style: const TextStyle(color: Colors.redAccent, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          );
        }
        final tasksToDisplay = controller.tasks
            .where((t) => !t.isCompleted)
            .toList();
        if (tasksToDisplay.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.greenAccent,
                  size: 40,
                ),
                SizedBox(height: 8),
                Text(
                  "¡Todo Hecho!",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 3),
          itemCount: tasksToDisplay.length,
          itemBuilder: (ctx, index) =>
              _buildTaskItemWatch(context, tasksToDisplay[index]),
        );
      }),
    );
  }

  Widget _buildTvTasksScreen(
    BuildContext context,
    String projectId,
    String projectName,
  ) {
    final bool isTV = true;
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: GFAppBar(
        title: Text(projectName, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey[800],
        leading: GFIconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
          type: GFButtonType.transparent,
        ),
        actions: [
          GFIconButton(
            icon: const Icon(Icons.add_task_outlined, color: Colors.white),
            onPressed: () => controller.navigateToAddTask(projectId: projectId),
            type: GFButtonType.transparent,
            tooltip: "Nueva Tarea",
          ),
        ],
      ),
      body: Obx(() {
        bool showMainLoader =
            (controller.isLoadingTasks.value && controller.tasks.isEmpty) ||
            (controller.isCurrentUserAdminForCurrentProject &&
                controller.isLoadingRequests.value &&
                controller.pendingTaskModificationRequests.isEmpty);

        if (showMainLoader) {
          return const Center(child: GFLoader(type: GFLoaderType.circle));
        }
        if (controller.taskListError.value.isNotEmpty) {
          return _buildErrorState(context, isTV: isTV);
        }

        final pendingTasks = controller.tasks
            .where((t) => !t.isCompleted)
            .toList();
        final completedTasks = controller.tasks
            .where((t) => t.isCompleted)
            .toList();

        if (pendingTasks.isEmpty &&
            completedTasks.isEmpty &&
            !(controller.isCurrentUserAdminForCurrentProject &&
                controller.pendingTaskModificationRequests.isNotEmpty)) {
          return _buildEmptyState(context, projectId, isTV: isTV);
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child:
                  (controller.isCurrentUserAdminForCurrentProject &&
                      (controller.isLoadingRequests.value ||
                          controller
                              .pendingTaskModificationRequests
                              .isNotEmpty))
                  ? _buildPendingRequestsSection(context, isTV: isTV)
                  : const SizedBox.shrink(),
            ),
            if (pendingTasks.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _buildSectionHeaderTV(
                  "Pendientes (${pendingTasks.length})",
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _buildTaskCardTV(context, pendingTasks[i]),
                  childCount: pendingTasks.length,
                ),
              ),
            ],
            if (completedTasks.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _buildSectionHeaderTV(
                  "Completadas (${completedTasks.length})",
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _buildTaskCardTV(context, completedTasks[i]),
                  childCount: completedTasks.length,
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        );
      }),
    );
  }

  Widget _buildPendingRequestsSection(
    BuildContext context, {
    required bool isTV,
  }) {
    final titleColor = isTV ? Colors.amber.shade200 : Colors.amber.shade800;
    final cardColor = isTV ? Colors.blueGrey[700] : Colors.amber[50];
    final borderColor = isTV ? Colors.amber.shade400 : Colors.amber.shade300;
    final textColor = isTV ? Colors.white : Colors.black87;

    return Container(
      padding: EdgeInsets.all(isTV ? 16.0 : 8.0),
      margin: EdgeInsets.symmetric(
        horizontal: isTV ? 20.0 : 8.0,
        vertical: isTV ? 12.0 : 4.0,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(isTV ? 12 : 8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              bottom: isTV ? 12.0 : 8.0,
              left: isTV ? 8 : 4,
              top: isTV ? 4 : 0,
            ),
            child: Text(
              "Solicitudes Pendientes (${controller.isLoadingRequests.value && controller.pendingTaskModificationRequests.isEmpty ? "cargando..." : controller.pendingTaskModificationRequests.length})",
              style: TextStyle(
                fontSize: isTV ? 20 : 16,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
          ),
          if (controller.isLoadingRequests.value &&
              controller.pendingTaskModificationRequests.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: GFLoader(
                  type: GFLoaderType.circle,
                  size: isTV ? GFSize.MEDIUM : GFSize.SMALL,
                ),
              ),
            )
          else if (!controller.isLoadingRequests.value &&
              controller.pendingTaskModificationRequests.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  "No hay solicitudes pendientes.",
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.pendingTaskModificationRequests.length,
              itemBuilder: (context, index) {
                final request =
                    controller.pendingTaskModificationRequests[index];
                if (request.data == null) return const SizedBox.shrink();

                final requestData = request.data!;
                final taskName = requestData['taskName'] ?? 'Tarea desconocida';
                final requesterName = requestData['requesterName'] ?? 'Miembro';
                final typeOfRequest =
                    (requestData['requestType'] as String?)?.capitalizeFirst ??
                    'Modificación';
                String proposedChangesSummary = "";
                if (typeOfRequest.toLowerCase() == "edición" &&
                    requestData['proposedChanges'] != null) {
                  final changesMap = Map<String, dynamic>.from(
                    requestData['proposedChanges'],
                  );
                  final newName = changesMap['name'];
                  if (newName != null && newName != taskName) {
                    proposedChangesSummary = "Nuevo nombre: '$newName'";
                  } else {
                    proposedChangesSummary = "Cambios en detalles";
                  }
                }

                return GFCard(
                  margin: EdgeInsets.symmetric(vertical: isTV ? 8.0 : 4.0),
                  padding: EdgeInsets.zero,
                  color: isTV ? Colors.blueGrey[600] : Colors.white,
                  elevation: 2,
                  content: GFListTile(
                    color: isTV ? Colors.blueGrey[600] : Colors.white,
                    title: Text(
                      "Solicitud para: $taskName",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: textColor,
                        fontSize: isTV ? 18 : 15,
                      ),
                    ),
                    subTitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "De: $requesterName",
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.8),
                            fontSize: isTV ? 15 : 13,
                          ),
                        ),
                        Text(
                          "Acción: $typeOfRequest",
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.8),
                            fontSize: isTV ? 15 : 13,
                          ),
                        ),
                        if (proposedChangesSummary.isNotEmpty)
                          Text(
                            proposedChangesSummary,
                            style: TextStyle(
                              color: GFColors.INFO,
                              fontSize: isTV ? 14 : 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                    icon: Wrap(
                      spacing: isTV ? 12 : 0,
                      children: [
                        GFIconButton(
                          icon: Icon(
                            Icons.check_circle,
                            color: Colors.green.shade400,
                            size: isTV ? 30 : 24,
                          ),
                          tooltip: "Aprobar",
                          onPressed: () => controller
                              .approveTaskModificationRequest(request),
                          type: GFButtonType.transparent,
                        ),
                        GFIconButton(
                          icon: Icon(
                            Icons.cancel,
                            color: Colors.red.shade400,
                            size: isTV ? 30 : 24,
                          ),
                          tooltip: "Rechazar",
                          onPressed: () =>
                              controller.rejectTaskModificationRequest(request),
                          type: GFButtonType.transparent,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeaderTV(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Text(
        title,
        style: Get.textTheme.headlineSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTasksListView(
    BuildContext context,
    List<TaskModel> tasks,
    String emptyMessage,
    String projectId, {
    required bool isTV,
    required bool isCompletedTab,
  }) {
    if (tasks.isEmpty && !controller.isLoadingTasks.value) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCompletedTab
                    ? Icons.check_circle_outline
                    : Icons.list_alt_outlined,
                size: 60,
                color: isTV ? Colors.white54 : Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: isTV ? Colors.white70 : Colors.grey[700],
                ),
              ),
              if (!isTV &&
                  !isCompletedTab &&
                  (controller.isCurrentUserMemberForCurrentProject))
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: GFButton(
                    onPressed: () =>
                        controller.navigateToAddTask(projectId: projectId),
                    text: "Añadir Tarea",
                    icon: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        isTV ? 20 : 10,
        isTV ? 20 : 10,
        isTV ? 20 : 10,
        isTV ? 20 : 80,
      ),
      itemCount: tasks.length,
      itemBuilder: (ctx, index) {
        final task = tasks[index];
        if (isTV) return _buildTaskCardTV(context, task);
        return _buildTaskItemMobile(context, task);
      },
    );
  }

  Widget _buildTaskItemMobile(BuildContext context, TaskModel task) {
    final colorScheme = Theme.of(context).colorScheme;
    final priorityColor = _getPriorityColor(task.priority, context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool canInteractWithMenu = controller.isCurrentUserMemberForCurrentProject;

    return Card(
      elevation: task.isCompleted ? 1.0 : 2.5,
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      color: task.isCompleted
          ? (isDark ? Colors.grey[800] : Colors.grey[200])
          : (isDark
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                : colorScheme.surface),
      child: InkWell(
        onTap: () {
          if (controller.isCurrentUserAdminForCurrentProject ||
              (!task.isCompleted &&
                  controller.isCurrentUserMemberForCurrentProject)) {
            controller.navigateToEditTask(task);
          } else if (task.isCompleted) {
            Get.snackbar(
              "Tarea Completada",
              "'${task.name}' ya está marcada como completada.",
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 2),
            );
          }
        },
        borderRadius: BorderRadius.circular(10.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Transform.scale(
                scale: 1.1,
                child: Checkbox(
                  value: task.isCompleted,
                  onChanged: (val) => controller.toggleTaskCompletion(task),
                  activeColor: GFColors.SUCCESS,
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(
                    color: task.isCompleted ? Colors.grey : priorityColor,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: task.isCompleted
                            ? Colors.grey[600]
                            : colorScheme.onSurface,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (task.description != null &&
                        task.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3.0),
                        child: Text(
                          task.description!,
                          style: TextStyle(
                            fontSize: 13,
                            color: task.isCompleted
                                ? Colors.grey[500]
                                : colorScheme.onSurfaceVariant.withValues(
                                    alpha: 0.8,
                                  ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (task.dueDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 13,
                              color: task.isCompleted
                                  ? Colors.grey[500]
                                  : priorityColor.withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Vence: ${DateFormat('dd MMM').format(task.dueDate!.toDate())}",
                              style: TextStyle(
                                fontSize: 12,
                                color: task.isCompleted
                                    ? Colors.grey[500]
                                    : priorityColor.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (canInteractWithMenu)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                  onSelected: (value) => _handleTaskMenuAction(value, task),
                  itemBuilder: (ctx) =>
                      _taskMenuItems(context, task, isTV: false),
                  tooltip: "Más opciones",
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCardTV(BuildContext context, TaskModel task) {
    final priorityColor = _getPriorityColor(task.priority, context, isTV: true);
    final focusNode = FocusNode();
    bool canInteractWithMenu = controller.isCurrentUserMemberForCurrentProject;

    return FocusableActionDetector(
      focusNode: focusNode,
      onFocusChange: (hasFocus) {},
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) => controller.toggleTaskCompletion(task),
        ),
      },
      child: Card(
        color: task.isCompleted ? Colors.blueGrey[700] : Colors.blueGrey[800],
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: focusNode.hasFocus ? priorityColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Transform.scale(
                scale: 1.5,
                child: Checkbox(
                  value: task.isCompleted,
                  onChanged: (val) => controller.toggleTaskCompletion(task),
                  activeColor: GFColors.SUCCESS,
                  focusColor: priorityColor.withValues(alpha: 0.4),
                  checkColor: Colors.black87,
                  side: BorderSide(
                    color: task.isCompleted ? Colors.grey[600]! : priorityColor,
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.name,
                      style: Get.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: Colors.grey[400],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (task.description != null &&
                        task.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 5.0),
                        child: Text(
                          task.description!,
                          style: Get.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (task.dueDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: priorityColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Vence: ${DateFormat('dd MMM yyyy').format(task.dueDate!.toDate())}",
                              style: Get.textTheme.bodyMedium?.copyWith(
                                color: priorityColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (canInteractWithMenu)
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white70,
                    size: 28,
                  ),
                  onSelected: (value) => _handleTaskMenuAction(value, task),
                  itemBuilder: (ctx) =>
                      _taskMenuItems(context, task, isTV: true),
                  color: Colors.blueGrey[700],
                  tooltip: "Más opciones",
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskItemWatch(BuildContext context, TaskModel task) {
    bool canRequestActions = controller.isCurrentUserMemberForCurrentProject;
    final priorityColor = _getPriorityColor(
      task.priority,
      context,
      isWatch: true,
    );

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => controller.toggleTaskCompletion(task),
        onLongPress: () {
          if (!canRequestActions) return;
          Get.bottomSheet(
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!task.isCompleted)
                    ListTile(
                      leading: const Icon(
                        Icons.edit_note_outlined,
                        color: Colors.white70,
                        size: 20,
                      ),
                      title: const Text(
                        'Editar',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      dense: true,
                      onTap: () {
                        Get.back();
                        controller.navigateToEditTask(task);
                      },
                    ),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_forever_outlined,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    title: Text(
                      controller.isCurrentUserAdminForCurrentProject
                          ? 'Eliminar'
                          : 'Solicitar Eliminar',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                      ),
                    ),
                    dense: true,
                    onTap: () {
                      Get.back();
                      controller.deleteTask(task);
                    },
                  ),
                  if (task.isCompleted && !(!task.isCompleted))
                    ListTile(
                      title: Center(
                        child: Text(
                          "Tarea completada",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
          child: Row(
            children: [
              Icon(
                task.isCompleted
                    ? Icons.check_circle_outline_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: task.isCompleted ? Colors.greenAccent : priorityColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (task.dueDate != null) ...[
                const SizedBox(width: 5),
                Text(
                  DateFormat('dd/MM').format(task.dueDate!.toDate()),
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    String projectId, {
    required bool isTV,
  }) {
    final textColor = isTV ? Colors.white70 : Colors.grey[700];
    final titleColor = isTV ? Colors.white : Get.textTheme.headlineSmall?.color;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.playlist_add_check_circle_outlined,
              color: isTV ? Colors.white54 : Colors.grey,
              size: isTV ? 80 : 60,
            ),
            const SizedBox(height: 20),
            Text(
              "No Hay Tareas",
              style: Get.textTheme.headlineSmall?.copyWith(color: titleColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "Este proyecto aún no tiene tareas. ¡Añade algunas!",
              style: Get.textTheme.bodyLarge?.copyWith(color: textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            if (controller.isCurrentUserMemberForCurrentProject)
              GFButton(
                onPressed: () =>
                    controller.navigateToAddTask(projectId: projectId),
                text: "Añadir Primera Tarea",
                icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                type: isTV ? GFButtonType.outline2x : GFButtonType.solid,
                textColor: isTV ? Colors.white : null,
                color: isTV ? Colors.white : GFColors.SUCCESS,
                size: isTV ? GFSize.LARGE : GFSize.MEDIUM,
              ),
          ],
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _taskMenuItems(
    BuildContext context,
    TaskModel task, {
    required bool isTV,
  }) {
    final textColor = isTV
        ? Colors.white
        : Theme.of(context).textTheme.bodyLarge?.color;
    List<PopupMenuEntry<String>> items = [];
    final bool isMember = controller.isCurrentUserMemberForCurrentProject;
    final bool isAdmin = controller.isCurrentUserAdminForCurrentProject;

    if (!task.isCompleted && isMember) {
      items.add(
        PopupMenuItem<String>(
          value: 'edit',
          child: ListTile(
            leading: Icon(
              Icons.edit_outlined,
              color: isTV
                  ? GFColors.INFO.withValues(alpha: 0.7)
                  : GFColors.INFO,
            ),
            title: Text('Editar Tarea', style: TextStyle(color: textColor)),
            dense: !isTV,
          ),
        ),
      );
    }
    if (isMember) {
      if (items.isNotEmpty && !isTV) items.add(const PopupMenuDivider());
      items.add(
        PopupMenuItem<String>(
          value: 'delete',
          child: ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: isTV
                  ? GFColors.DANGER.withValues(alpha: 0.7)
                  : GFColors.DANGER,
            ),
            title: Text(
              isAdmin ? 'Eliminar Tarea' : 'Solicitar Eliminar',
              style: TextStyle(color: textColor),
            ),
            dense: !isTV,
          ),
        ),
      );
    }
    if (items.isEmpty) {
      return [
        PopupMenuItem<String>(
          enabled: false,
          child: ListTile(
            title: Text(
              "No hay acciones",
              style: TextStyle(color: Colors.grey[isTV ? 300 : 500]),
            ),
          ),
        ),
      ];
    }
    return items;
  }

  Widget _buildErrorState(BuildContext context, {required bool isTV}) {
    final textColor = isTV ? Colors.white70 : Get.textTheme.bodyLarge?.color;
    final titleColor = isTV ? Colors.white : Get.textTheme.headlineSmall?.color;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              color: Colors.orangeAccent,
              size: isTV ? 80 : 50,
            ),
            const SizedBox(height: 15),
            Text(
              "Error al Cargar Tareas",
              style: Get.textTheme.headlineSmall?.copyWith(color: titleColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              controller.taskListError.value,
              style: Get.textTheme.bodyLarge?.copyWith(color: textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            GFButton(
              onPressed: () => controller.loadTasksForProject(
                controller.currentProjectId.value,
              ),
              text: "Reintentar",
              icon: const Icon(Icons.refresh, color: Colors.white),
              type: isTV ? GFButtonType.outline2x : GFButtonType.solid,
              textColor: isTV ? Colors.white : null,
              color: isTV ? Colors.white : GFColors.WARNING,
            ),
          ],
        ),
      ),
    );
  }

  void _handleTaskMenuAction(String value, TaskModel task) {
    if (value == 'edit') {
      controller.navigateToEditTask(task);
    } else if (value == 'delete') {
      controller.deleteTask(task);
    }
  }

  Color _getPriorityColor(
    TaskPriority priority,
    BuildContext context, {
    bool isTV = false,
    bool isWatch = false,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    switch (priority) {
      case TaskPriority.alta:
        if (isTV) return Colors.red.shade300;
        if (isWatch) return Colors.redAccent.shade100;
        return isDark ? Colors.red.shade300 : Colors.red.shade400;
      case TaskPriority.media:
        if (isTV) return Colors.orange.shade300;
        if (isWatch) return Colors.orangeAccent.shade100;
        return isDark ? Colors.orange.shade300 : Colors.orange.shade400;
      case TaskPriority.baja:
        if (isTV) return Colors.green.shade400;
        if (isWatch) return Colors.greenAccent.shade100;
        return isDark ? Colors.green.shade300 : Colors.green.shade500;
    }
  }
}
