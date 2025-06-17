import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:focus_flow/data/models/app_notification_model.dart';
import 'package:focus_flow/routes/app_routes.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:focus_flow/modules/projects/project_controller.dart';
import 'package:focus_flow/data/models/project_model.dart';

class ProjectsScreen extends GetView<ProjectController> {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = Get.width;
    final isTV = screenWidth > 800 && Get.height > 500;
    final isWatch = screenWidth < 300;

    if (isWatch) {
      return _buildWatchProjectsScreen(context);
    } else if (isTV) {
      return _buildTvProjectsScreen(context);
    } else {
      return _buildMobileProjectsScreen(context);
    }
  }

  Widget _buildMobileProjectsScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Proyectos"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            tooltip: "Unirse con Código",
            onPressed: () => _showJoinWithCodeDialog(context),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingProjects.value &&
            controller.projects.isEmpty &&
            controller.isLoadingDeletionRequests.value &&
            controller.pendingProjectDeletionRequests.isEmpty &&
            controller.isLoadingInvitations.value &&
            controller.projectInvitations.isEmpty) {
          return const Center(child: GFLoader(type: GFLoaderType.circle));
        }
        if (controller.projectListError.value.isNotEmpty &&
            controller.projects.isEmpty) {
          return _buildErrorState(context, isTV: false);
        }
        return Column(
          children: [
            _buildPendingDeletionRequestsSection(),
            _buildPendingInvitationsSection(),
            Expanded(
              child:
                  controller.projects.isEmpty &&
                      !controller.isLoadingProjects.value
                  ? _buildEmptyState(context, isTV: false)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 80.0),
                      itemCount: controller.projects.length,
                      itemBuilder: (ctx, index) {
                        final project = controller.projects[index];
                        return _buildProjectCardMobile(context, project);
                      },
                    ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.navigateToAddProject,
        label: const Text("Nuevo Proyecto"),
        icon: const Icon(Icons.add),
        backgroundColor: GFColors.PRIMARY,
      ),
    );
  }

  void _showJoinWithCodeDialog(BuildContext context) {
    controller.accessCodeController.clear();
    Get.defaultDialog(
      title: "Unirse a Proyecto con Código",
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Ingresa el código de acceso del proyecto al que quieres unirte.",
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: controller.accessCodeController,
            decoration: const InputDecoration(
              labelText: "Código de Acceso",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.vpn_key),
              hintText: "ABCXYZ",
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            maxLength: 10,
            onFieldSubmitted: (_) => controller.performJoinProjectWithCode(),
          ),
        ],
      ),
      confirm: ElevatedButton(
        onPressed: controller.performJoinProjectWithCode,
        child: const Text("UNIRME"),
      ),
      cancel: ElevatedButton(
        onPressed: () => Get.back(),
        child: const Text("CANCELAR"),
      ),
    );
  }

  Widget _buildPendingDeletionRequestsSection() {
    return Obx(() {
      if (controller.isLoadingDeletionRequests.value &&
          controller.pendingProjectDeletionRequests.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(8.0),
          child: Center(
            child: GFLoader(type: GFLoaderType.circle, size: GFSize.SMALL),
          ),
        );
      }
      if (controller.pendingProjectDeletionRequests.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.all(8.0),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Get.theme.colorScheme.errorContainer.withAlpha(100),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
              child: Text(
                "Solicitudes de Eliminación Pendientes",
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Get.theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.pendingProjectDeletionRequests.length,
              itemBuilder: (context, index) {
                final request =
                    controller.pendingProjectDeletionRequests[index];
                final requestData = request.data ?? {};
                final projectName =
                    requestData['projectName'] as String? ??
                    'Proyecto Desconocido';
                final requesterName =
                    requestData['requesterName'] as String? ??
                    'Usuario Desconocido';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Icon(
                      Icons.warning_amber_rounded,
                      color: Get.theme.colorScheme.error,
                    ),
                    title: Text(
                      "Eliminar: '$projectName'",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Solicitado por: $requesterName\nEmail: ${requestData['requesterEmail'] ?? 'N/A'}",
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                          ),
                          tooltip: "Aprobar Eliminación",
                          onPressed: () =>
                              controller.approveProjectDeletionRequest(request),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.cancel_outlined,
                            color: Colors.red,
                          ),
                          tooltip: "Rechazar Solicitud",
                          onPressed: () =>
                              controller.rejectProjectDeletionRequest(request),
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
    });
  }

  Widget _buildPendingInvitationsSection() {
    return Obx(() {
      if (controller.isLoadingInvitations.value &&
          controller.projectInvitations.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(8.0),
          child: Center(
            child: GFLoader(type: GFLoaderType.circle, size: GFSize.SMALL),
          ),
        );
      }
      if (controller.projectInvitations.isEmpty) {
        return const SizedBox.shrink();
      }
      return Container(
        padding: const EdgeInsets.all(8.0),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Get.theme.colorScheme.secondaryContainer.withAlpha(70),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
              child: Text(
                "Invitaciones Pendientes",
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.projectInvitations.length,
              itemBuilder: (context, index) {
                final invitation = controller.projectInvitations[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: const Icon(
                      Icons.mail_outline,
                      color: GFColors.INFO,
                    ),
                    title: Text("Invitación a: ${invitation.projectName}"),
                    subtitle: Text("De: ${invitation.invitedByUserId}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                          ),
                          tooltip: "Aceptar",
                          onPressed: () => controller.performAcceptInvitation(
                            invitation.id!,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.cancel_outlined,
                            color: Colors.red,
                          ),
                          tooltip: "Declinar",
                          onPressed: () => controller.performDeclineInvitation(
                            invitation.id!,
                          ),
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
    });
  }

  Widget _buildProjectCardMobile(BuildContext context, ProjectModel project) {
    final projectColor = project.projectColor;
    final iconData = controller.getIconDataByName(project.iconName);
    final bool isAdmin = controller.isCurrentUserAdmin(project);
    final bool isMember = controller.isCurrentUserMemberOfProject(project);

    final int memberCount = project.userRoles
        .map((roleEntry) => roleEntry.split(':')[0])
        .toSet()
        .length;

    return Card(
      elevation: 3.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: () {
          controller.setCurrentProjectRole(project);
          Get.toNamed(
            AppRoutes.TASKS_LIST,
            arguments: {'projectId': project.id, 'projectName': project.name},
          );
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GFAvatar(
                    backgroundColor: projectColor.withAlpha(50),
                    child: Icon(iconData, color: projectColor, size: 24),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: Get.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isAdmin)
                          Text(
                            "Administrador",
                            style: Get.textTheme.bodySmall?.copyWith(
                              color: GFColors.PRIMARY,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                    onSelected: (value) =>
                        _handleProjectMenuAction(context, value, project),
                    itemBuilder: (ctx) => _projectMenuItems(
                      context,
                      project,
                      isTV: false,
                      isAdmin: isAdmin,
                      isMember: isMember,
                    ),
                  ),
                ],
              ),
              if (project.description != null &&
                  project.description!.isNotEmpty) ...[
                const SizedBox(height: 8.0),
                Text(
                  project.description!,
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12.0),
              Text("$memberCount miembro(s)", style: Get.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  void _handleProjectMenuAction(
    BuildContext context,
    String value,
    ProjectModel project,
  ) {
    final bool isAdmin = controller.isCurrentUserAdmin(project);
    final bool isMember = controller.isCurrentUserMemberOfProject(project);

    switch (value) {
      case 'tasks':
        controller.setCurrentProjectRole(project);
        Get.toNamed(
          AppRoutes.TASKS_LIST,
          arguments: {'projectId': project.id, 'projectName': project.name},
        );
        break;
      case 'edit_details':
        if (isAdmin) {
          controller.navigateToEditProject(project);
        } else {
          Get.snackbar(
            "Permiso Denegado",
            "Solo el admin puede editar detalles.",
          );
        }
        break;
      case 'invite_member':
        if (isAdmin) {
          _showInviteUserDialog(context, project.id!);
        } else {
          Get.snackbar(
            "Permiso Denegado",
            "Solo el admin puede invitar miembros.",
          );
        }
        break;
      case 'manage_members':
        if (isAdmin) {
          Get.snackbar("Próximamente", "Pantalla para gestionar miembros.");
        } else {
          Get.snackbar(
            "Permiso Denegado",
            "No tienes permiso para gestionar miembros.",
          );
        }
        break;
      case 'view_access_code':
        if (isAdmin) {
          controller.performGenerateAccessCode(project.id!);
          _showAccessCodeDialog();
        } else {
          Get.snackbar(
            "Permiso Denegado",
            "Solo el admin puede ver el código de acceso.",
          );
        }
        break;
      case 'leave_project':
        if (isMember && !isAdmin) {
          controller.performLeaveProject(project.id!);
        } else if (isAdmin) {
          Get.snackbar(
            "Acción no permitida",
            "El administrador no puede abandonar el proyecto. Transfiere la administración o elimina el proyecto.",
          );
        }
        break;
      case 'delete_project_or_request':
        controller.handleDeleteProjectAction(project);
        break;
    }
  }

  void _showInviteUserDialog(BuildContext context, String projectId) {
    controller.inviteEmailController.clear();
    Get.defaultDialog(
      title: "Invitar Usuario al Proyecto",
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Ingresa el correo electrónico del usuario que quieres invitar.",
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: controller.inviteEmailController,
            decoration: const InputDecoration(
              labelText: "Email del Invitado",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            onFieldSubmitted: (_) => controller.performInviteUser(projectId),
          ),
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () => controller.performInviteUser(projectId),
        child: const Text("ENVIAR INVITACIÓN"),
      ),
      cancel: ElevatedButton(
        onPressed: () => Get.back(),
        child: const Text("CANCELAR"),
      ),
    );
  }

  void _showAccessCodeDialog() {
    Get.defaultDialog(
      title: "Código de Acceso del Proyecto",
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Este es el código de acceso del proyecto. Puedes compartirlo con otros usuarios para que se unan.",
          ),
          const SizedBox(height: 16),
          Obx(
            () => SelectableText(
              controller.generatedAccessCode.value,
              style: Get.textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text("Copiar Código"),
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: controller.generatedAccessCode.value),
              );
              Get.snackbar(
                "Código Copiado",
                "El código de acceso ha sido copiado al portapapeles.",
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 2),
              );
            },
          ),
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () => Get.back(),
        child: const Text("CERRAR"),
      ),
    );
  }

  List<PopupMenuEntry<String>> _projectMenuItems(
    BuildContext context,
    ProjectModel project, {
    required bool isTV,
    required bool isAdmin,
    required bool isMember,
  }) {
    final textColor = isTV
        ? Colors.white
        : Theme.of(context).textTheme.bodyLarge?.color;
    List<PopupMenuEntry<String>> items = [
      PopupMenuItem<String>(
        value: 'tasks',
        child: ListTile(
          leading: Icon(
            Icons.task_alt_outlined,
            color: isTV ? GFColors.SUCCESS.withAlpha(180) : GFColors.SUCCESS,
          ),
          title: Text('Ver Tareas', style: TextStyle(color: textColor)),
        ),
      ),
    ];

    if (isAdmin) {
      items.addAll([
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'edit_details',
          child: ListTile(
            leading: Icon(
              Icons.edit_outlined,
              color: isTV ? GFColors.INFO.withAlpha(180) : GFColors.INFO,
            ),
            title: Text('Editar Detalles', style: TextStyle(color: textColor)),
          ),
        ),
        PopupMenuItem<String>(
          value: 'invite_member',
          child: ListTile(
            leading: Icon(
              Icons.person_add_alt_1_outlined,
              color: isTV ? GFColors.WARNING.withAlpha(180) : GFColors.WARNING,
            ),
            title: Text('Invitar Miembro', style: TextStyle(color: textColor)),
          ),
        ),
        PopupMenuItem<String>(
          value: 'view_access_code',
          child: ListTile(
            leading: Icon(
              Icons.vpn_key_outlined,
              color: isTV ? Colors.teal.withAlpha(180) : Colors.teal,
            ),
            title: Text('Código de Acceso', style: TextStyle(color: textColor)),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'delete_project_or_request',
          child: ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: isTV ? GFColors.DANGER.withAlpha(180) : GFColors.DANGER,
            ),
            title: Text(
              'Eliminar Proyecto',
              style: TextStyle(color: textColor),
            ),
          ),
        ),
      ]);
    } else if (isMember) {
      items.add(const PopupMenuDivider());
      items.add(
        PopupMenuItem<String>(
          value: 'leave_project',
          child: ListTile(
            leading: Icon(
              Icons.exit_to_app_outlined,
              color: isTV ? Colors.orange.withAlpha(180) : Colors.orange,
            ),
            title: Text(
              'Abandonar Proyecto',
              style: TextStyle(color: textColor),
            ),
          ),
        ),
      );
      items.add(
        PopupMenuItem<String>(
          value: 'delete_project_or_request',
          child: ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: isTV ? Colors.redAccent.withAlpha(180) : Colors.redAccent,
            ),
            title: Text(
              'Solicitar Eliminación',
              style: TextStyle(color: textColor),
            ),
          ),
        ),
      );
    }
    return items;
  }

  Widget _buildTvProjectsScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: const Text(
          "Mis Proyectos",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey[800],
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_outlined, color: Colors.white),
            tooltip: "Unirse con Código",
            onPressed: () => _showJoinWithCodeDialog(context),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingProjects.value &&
            controller.projects.isEmpty &&
            controller.isLoadingDeletionRequests.value &&
            controller.pendingProjectDeletionRequests.isEmpty &&
            controller.isLoadingInvitations.value &&
            controller.projectInvitations.isEmpty) {
          return const Center(child: GFLoader(type: GFLoaderType.circle));
        }
        if (controller.projectListError.value.isNotEmpty &&
            controller.projects.isEmpty) {
          return _buildErrorState(context, isTV: true);
        }
        bool hasHeaderContent =
            controller.pendingProjectDeletionRequests.isNotEmpty ||
            controller.projectInvitations.isNotEmpty;

        return Column(
          children: [
            if (hasHeaderContent)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10.0,
                ),
                child: Column(
                  children: [
                    _buildPendingDeletionRequestsSection(),
                    _buildPendingInvitationsSection(),
                  ],
                ),
              ),
            Expanded(
              child:
                  controller.projects.isEmpty &&
                      !controller.isLoadingProjects.value
                  ? _buildEmptyState(context, isTV: true)
                  : GridView.builder(
                      padding: const EdgeInsets.all(30.0),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.5,
                            crossAxisSpacing: 30,
                            mainAxisSpacing: 30,
                          ),
                      itemCount: controller.projects.length + 1,
                      itemBuilder: (ctx, index) {
                        if (index == controller.projects.length) {
                          return _buildAddProjectCardTV(context);
                        }
                        final project = controller.projects[index];
                        return _buildProjectCardTV(context, project);
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildWatchProjectsScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Proyectos",
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        backgroundColor: Colors.grey[900],
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          GFIconButton(
            icon: const Icon(Icons.add, size: 20, color: Colors.white),
            onPressed: controller.navigateToAddProject,
            type: GFButtonType.transparent,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingProjects.value && controller.projects.isEmpty) {
          return const Center(
            child: GFLoader(type: GFLoaderType.circle, size: GFSize.SMALL),
          );
        }
        if (controller.projectListError.value.isNotEmpty &&
            controller.projects.isEmpty) {
          return Center(
            child: Text(
              controller.projectListError.value,
              style: const TextStyle(color: Colors.redAccent, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          );
        }
        if (controller.projects.isEmpty &&
            !controller.isLoadingProjects.value) {
          return const Center(
            child: Text(
              "No hay proyectos.",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          );
        }
        return ListView.builder(
          itemCount: controller.projects.length,
          itemBuilder: (context, index) {
            final project = controller.projects[index];
            return GFListTile(
              color: Colors.grey[850],
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 5),
              radius: 8,
              avatar: GFAvatar(
                size: GFSize.SMALL,
                backgroundColor: project.projectColor.withAlpha(70),
                child: Icon(
                  controller.getIconDataByName(project.iconName),
                  color: project.projectColor,
                  size: 16,
                ),
              ),
              title: Text(
                project.name,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Get.toNamed(
                  AppRoutes.TASKS_LIST,
                  arguments: {
                    'projectId': project.id,
                    'projectName': project.name,
                  },
                );
              },
            );
          },
        );
      }),
    );
  }

  Widget _buildProjectCardTV(BuildContext context, ProjectModel project) {
    final projectColor = project.projectColor;
    final iconData = controller.getIconDataByName(project.iconName);
    final bool isAdmin = controller.isCurrentUserAdmin(project);
    final bool isMember = controller.isCurrentUserMemberOfProject(project);
    final int memberCount = project.userRoles
        .map((roleEntry) => roleEntry.split(':')[0])
        .toSet()
        .length;

    return Material(
      color: Colors.blueGrey[800],
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: InkWell(
        onTap: () {
          controller.setCurrentProjectRole(project);
          Get.toNamed(
            AppRoutes.TASKS_LIST,
            arguments: {'projectId': project.id, 'projectName': project.name},
          );
        },
        focusColor: projectColor.withAlpha(70),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GFAvatar(
                    backgroundColor: projectColor.withAlpha(50),
                    size: GFSize.MEDIUM,
                    child: Icon(iconData, color: projectColor, size: 32),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white70),
                    onSelected: (value) =>
                        _handleProjectMenuAction(context, value, project),
                    itemBuilder: (ctx) => _projectMenuItems(
                      context,
                      project,
                      isTV: true,
                      isAdmin: isAdmin,
                      isMember: isMember,
                    ),
                    color: Colors.blueGrey[700],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                project.name,
                style: Get.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (project.description != null &&
                  project.description!.isNotEmpty)
                Text(
                  project.description!,
                  style: Get.textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              Text(
                "$memberCount miembro(s)",
                style: Get.textTheme.bodySmall?.copyWith(color: Colors.white60),
              ),
              if (isAdmin)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    "Administrador",
                    style: Get.textTheme.labelSmall?.copyWith(
                      color: GFColors.PRIMARY,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddProjectCardTV(BuildContext context) {
    return Material(
      color: Colors.grey[700]?.withAlpha(120),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: controller.navigateToAddProject,
        focusColor: Colors.grey[600],
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_circle_outline,
                size: 50,
                color: Colors.white70,
              ),
              const SizedBox(height: 10),
              Text(
                "Nuevo Proyecto",
                style: Get.textTheme.titleLarge?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
              Icons.error_outline,
              color: Colors.redAccent,
              size: isTV ? 80 : 50,
            ),
            const SizedBox(height: 15),
            Text(
              "Error al Cargar",
              style: Get.textTheme.headlineSmall?.copyWith(color: titleColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              controller.projectListError.value,
              style: Get.textTheme.bodyLarge?.copyWith(color: textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            GFButton(
              onPressed: controller.reloadProjects,
              text: "Reintentar",
              icon: const Icon(Icons.refresh, color: Colors.white),
              type: isTV ? GFButtonType.outline2x : GFButtonType.solid,
              textColor: isTV ? Colors.white : null,
              color: isTV ? Colors.white : GFColors.PRIMARY,
              buttonBoxShadow: isTV,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool isTV}) {
    final textColor = isTV ? Colors.white70 : Colors.grey[700];
    final titleColor = isTV ? Colors.white : Get.textTheme.headlineSmall?.color;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_off_outlined,
              color: isTV ? Colors.white54 : Colors.grey,
              size: isTV ? 80 : 60,
            ),
            const SizedBox(height: 20),
            Text(
              "No Hay Proyectos",
              style: Get.textTheme.headlineSmall?.copyWith(color: titleColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "Crea tu primer proyecto para empezar a organizar tus tareas.",
              style: Get.textTheme.bodyLarge?.copyWith(color: textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            GFButton(
              onPressed: controller.navigateToAddProject,
              text: "Crear Nuevo Proyecto",
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              type: isTV ? GFButtonType.outline2x : GFButtonType.solid,
              textColor: isTV ? Colors.white : null,
              color: isTV ? Colors.white : GFColors.PRIMARY,
              buttonBoxShadow: isTV,
              size: isTV ? GFSize.LARGE : GFSize.MEDIUM,
            ),
          ],
        ),
      ),
    );
  }
}
