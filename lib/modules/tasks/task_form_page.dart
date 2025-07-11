import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:focus_flow/modules/tasks/tasks_controller.dart';
import 'package:focus_flow/data/models/task_model.dart';
import 'package:getwidget/getwidget.dart';
import 'package:intl/intl.dart';
import 'package:focus_flow/routes/app_routes.dart';

class TaskFormScreen extends GetView<TaskController> {
  const TaskFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = Get.width;
    final isTV = screenWidth > 800 && Get.height > 500;
    final isEditing = controller.isEditingTask;
    final dynamic arguments = Get.arguments;

    // 2. Comprobamos si es un mapa y hacemos el cast seguro.
    final Map<String, dynamic> args = (arguments is Map<String, dynamic>)
        ? arguments // Si es un mapa, lo usamos
        : {}; // Si no (o si es null), usamos un mapa vacío.

    // 3. Ahora que 'args' es un Map tipado, podemos acceder a sus claves de forma segura.
    final String? initialProjectId =
        args['projectId'] as String?; // Cast a String?
    final String projectName = (args['projectName'] as String?) ?? 'Tareas';
    if (!isEditing &&
        initialProjectId != null &&
        controller.currentProjectId.value != initialProjectId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.currentProjectId.value = initialProjectId;
      });
    }

    return Scaffold(
      backgroundColor: isTV ? Colors.blueGrey[900] : null,
      appBar: GFAppBar(
        backgroundColor: GFColors.PRIMARY,
        title: Text(
          isEditing ? 'Editar Tarea' : 'Nueva Tarea',
          style: TextStyle(color: isTV ? Colors.white : Colors.white),
        ),
        leading: GFIconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isTV ? Colors.white : Colors.white,
          ),
          onPressed: () => Get.offAllNamed<Object>(
            AppRoutes.TASKS_LIST,
            arguments: {
              'projectId': initialProjectId,
              'projectName': projectName,
            },
          ),
          type: GFButtonType.transparent,
        ),
        elevation: isTV ? 0 : null,
      ),
      body: _buildFormBody(context, isTV),
    );
  }

  Widget _buildFormBody(BuildContext context, bool isTV) {
    final textTheme = Get.textTheme;
    final colorScheme = Get.theme.colorScheme;

    final tvLabelStyle = textTheme.titleMedium?.copyWith(
      color: Colors.white70,
      fontWeight: FontWeight.w500,
    );
    final mobileLabelStyle = textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w500,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(isTV ? 40.0 : 20.0),
      child: Form(
        key: controller.taskFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildTextFormField(
              controller: controller.taskNameController,
              labelText: 'Nombre de la Tarea',
              hintText: 'Ej: Revisar diseño UI',
              prefixIcon: Icons.task_alt_outlined,
              isTV: isTV,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es obligatorio';
                }
                if (value.trim().length > 100) return 'Máximo 100 caracteres';
                return null;
              },
            ),
            SizedBox(height: isTV ? 30.0 : 20.0),

            _buildTextFormField(
              controller: controller.taskDescriptionController,
              labelText: 'Descripción (Opcional)',
              hintText: 'Detalles adicionales...',
              prefixIcon: Icons.notes_outlined,
              maxLines: isTV ? 4 : 3,
              isTV: isTV,
              validator: (value) {
                if (value != null && value.trim().length > 500) {
                  return 'Máximo 500 caracteres';
                }
                return null;
              },
            ),
            SizedBox(height: isTV ? 35.0 : 25.0),

            Text('Prioridad:', style: isTV ? tvLabelStyle : mobileLabelStyle),
            SizedBox(height: isTV ? 15.0 : 10.0),
            _buildPrioritySelector(context, isTV),
            SizedBox(height: isTV ? 35.0 : 25.0),

            Text(
              'Fecha de Vencimiento (Opcional):',
              style: isTV ? tvLabelStyle : mobileLabelStyle,
            ),
            SizedBox(height: isTV ? 15.0 : 10.0),
            _buildDueDateSelector(context, isTV),
            SizedBox(height: isTV ? 40.0 : 30.0),

            Obx(
              () => GFButton(
                onPressed: controller.isSavingTask.value
                    ? null
                    : controller.saveTask,
                text: controller.isSavingTask.value
                    ? (controller.isEditingTask
                          ? 'Actualizando...'
                          : 'Creando...')
                    : (controller.isEditingTask
                          ? 'Actualizar Tarea'
                          : 'Crear Tarea'),
                icon: controller.isSavingTask.value
                    ? GFLoader(
                        type: GFLoaderType.circle,
                        size: GFSize.SMALL,
                        loaderColorOne: isTV
                            ? colorScheme.primary
                            : Colors.white,
                      )
                    : Icon(
                        controller.isEditingTask
                            ? Icons.save_alt_outlined
                            : Icons.add_circle_outline,
                        color: isTV
                            ? (Get.isDarkMode ? Colors.black : Colors.white)
                            : Colors.white,
                      ),
                fullWidthButton: true,
                size: GFSize.LARGE,
                shape: GFButtonShape.pills,
                color: isTV ? colorScheme.primary : GFColors.PRIMARY,
                textColor: isTV
                    ? (Get.isDarkMode ? Colors.black : Colors.white)
                    : Colors.white,
                buttonBoxShadow: isTV,
                focusColor: isTV
                    ? colorScheme.primary.withValues(alpha: 0.4)
                    : null,
              ),
            ),
            SizedBox(height: isTV ? 20.0 : 10.0),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    required bool isTV,
    int maxLines = 1,
    FocusNode? focusNode,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Get.theme.colorScheme;
    final textTheme = Get.textTheme;
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: isTV
            ? textTheme.titleMedium?.copyWith(color: Colors.white70)
            : null,
        hintText: hintText,
        hintStyle: isTV
            ? textTheme.titleMedium?.copyWith(color: Colors.white54)
            : null,
        filled: isTV,
        fillColor: isTV ? Colors.blueGrey[800] : null,
        prefixIcon: Icon(
          prefixIcon,
          color: isTV ? Colors.white70 : colorScheme.onSurfaceVariant,
        ),
        border: isTV
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blueGrey[700]!),
              )
            : const OutlineInputBorder(),
        enabledBorder: isTV
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blueGrey[700]!),
              )
            : null,
        focusedBorder: isTV
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              )
            : null,
        contentPadding: isTV
            ? const EdgeInsets.symmetric(horizontal: 20, vertical: 22)
            : null,
      ),
      style: isTV ? textTheme.titleMedium?.copyWith(color: Colors.white) : null,
      maxLines: maxLines,
      textCapitalization: TextCapitalization.sentences,
      validator: validator,
      cursorColor: isTV ? colorScheme.primary : null,
    );
  }

  Widget _buildPrioritySelector(BuildContext context, bool isTV) {
    final colorScheme = Get.theme.colorScheme;

    if (isTV) {
      return Obx(
        () => DropdownButtonFormField<TaskPriority>(
          value: controller.selectedPriority.value,
          dropdownColor: Colors.blueGrey[700],
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.blueGrey[800],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blueGrey[700]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blueGrey[700]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
          style: Get.textTheme.titleMedium?.copyWith(color: Colors.white),
          iconEnabledColor: Colors.white70,
          items: controller.taskPriorities.map((priority) {
            return DropdownMenuItem<TaskPriority>(
              value: priority,
              child: Text(
                priority.toString().split('.').last.capitalizeFirst ??
                    priority.toString(),
                style: TextStyle(
                  color: priority == controller.selectedPriority.value
                      ? colorScheme.primary
                      : Colors.white,
                ),
              ),
            );
          }).toList(),
          onChanged: (TaskPriority? newValue) {
            if (newValue != null) controller.selectedPriority.value = newValue;
          },
        ),
      );
    }

    return Obx(
      () => SizedBox(
        height: 50,
        width: Get.width,
        child: DropdownButtonHideUnderline(
          child: GFDropdown<TaskPriority>(
            padding: const EdgeInsets.all(15),
            borderRadius: BorderRadius.circular(10),
            elevation: 0,
            border: const BorderSide(color: Colors.black12, width: 1),
            dropdownButtonColor: GFColors.WHITE,
            value: controller.selectedPriority.value,
            style: TextStyle(color: colorScheme.onSurface),
            icon: Icon(
              Icons.arrow_drop_down,
              color: colorScheme.onSurfaceVariant,
            ),
            dropdownColor: colorScheme.surfaceContainer,
            isExpanded: true,
            isDense: false,
            onChanged: (TaskPriority? newValue) {
              if (newValue != null) {
                controller.selectedPriority.value = newValue;
              }
            },
            items: controller.taskPriorities.map((priority) {
              return DropdownMenuItem<TaskPriority>(
                value: priority,
                child: Text(
                  priority.toString().split('.').last.capitalizeFirst ??
                      priority.toString(),
                ),
              );
            }).toList(),
            itemHeight: 50,
          ),
        ),
      ),
    );
  }

  Widget _buildDueDateSelector(BuildContext context, bool isTV) {
    final colorScheme = Get.theme.colorScheme;

    if (isTV) {
      return Obx(() {
        final dueDate = controller.selectedDueDate.value;
        return Material(
          color: Colors.blueGrey[800],
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: dueDate ?? DateTime.now(),
                firstDate: DateTime(DateTime.now().year - 1),
                lastDate: DateTime(DateTime.now().year + 5),
              );
              if (picked != null) controller.selectedDueDate.value = picked;
            },
            focusColor: colorScheme.primary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueGrey[700]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dueDate == null
                        ? 'No establecida'
                        : DateFormat('EEE, dd MMM yyyy').format(dueDate),
                    style: Get.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const Icon(
                    Icons.calendar_month_outlined,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),
        );
      });
    }

    return Obx(() {
      final dueDate = controller.selectedDueDate.value;
      return Card(
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.7)),
        ),
        margin: EdgeInsets.zero,
        child: GFListTile(
          title: Text(
            dueDate == null
                ? 'No establecida'
                : DateFormat('EEE, dd MMM yyyy').format(dueDate),
            style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
          ),
          icon: Icon(Icons.calendar_today_outlined, color: colorScheme.primary),
          onTap: () => controller.pickDueDate(context),
          avatar: dueDate != null
              ? GFIconButton(
                  icon: Icon(
                    Icons.clear,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () => controller.selectedDueDate.value = null,
                  type: GFButtonType.transparent,
                  size: GFSize.SMALL,
                )
              : null,
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
      );
    });
  }
}
