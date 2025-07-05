import 'package:flutter/material.dart';
import 'package:focus_flow/data/models/project_model.dart';
import 'package:focus_flow/modules/projects/project_controller.dart';
import 'package:focus_flow/routes/app_routes.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';

class ProjectCardMobile extends StatelessWidget {
  final ProjectModel project;
  final ProjectController controller;

  const ProjectCardMobile({
    super.key,
    required this.project,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final projectColor = project.projectColor;
    final iconData = controller.getIconDataByName(project.iconName);
    final isAdmin = controller.isCurrentUserAdmin(project);
    final isMember = controller.isCurrentUserMemberOfProject(project);

    final memberCount = project.userRoles
        .map((roleEntry) => roleEntry.split(':')[0])
        .toSet()
        .length;

    return GFCard(
      elevation: 3.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(12.0),
      ),
      title: GFListTile(
        padding: const EdgeInsets.all(16.0),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GFAvatar(
                  backgroundColor: projectColor.withAlpha(50),
                  child: Icon(iconData, color: projectColor, size: 24),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: TextStyle(
                          color: GFColors.DARK,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isAdmin)
                        Text(
                          'Administrador',
                          style: TextStyle(
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
                style: TextStyle(color: GFColors.FOCUS),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12.0),
              Text("$memberCount miembro(s)"),
            ],
          ],
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
          controller.showInviteUserDialog(context, project.id!);
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
          controller.showAccessCodeDialog();
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
}
