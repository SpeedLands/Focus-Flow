// lib/app/modules/tasks/views/task_form_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:focus_flow/modules/tasks/tasks_controller.dart';
import 'package:focus_flow/data/models/task_model.dart';
import 'package:getwidget/getwidget.dart';
import 'package:intl/intl.dart';

class TaskFormScreen extends GetView<TaskController> {
  const TaskFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = Get.width;
    final isTV = screenWidth > 800 && Get.height > 500;
    final isEditing = controller.isEditingTask;
    final Map<String, dynamic> args = Get.arguments ?? {};
    final String? initialProjectId = args['projectId'];
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
        title: Text(
          isEditing ? "Editar Tarea" : "Nueva Tarea",
          style: TextStyle(color: isTV ? Colors.white : Colors.white),
        ),
        leading: GFIconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isTV ? Colors.white : Colors.white,
          ),
          onPressed: () => Get.back(),
          type: GFButtonType.transparent,
        ),
        backgroundColor: isTV
            ? Colors.blueGrey[800]
            : (Get.theme.appBarTheme.backgroundColor ??
                  Get.theme.colorScheme.primary),
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
            // --- Campo Nombre de la Tarea ---
            _buildTextFormField(
              controller: controller.taskNameController,
              labelText: "Nombre de la Tarea",
              hintText: "Ej: Revisar diseño UI",
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

            // --- Campo Descripción de la Tarea ---
            _buildTextFormField(
              controller: controller.taskDescriptionController,
              labelText: "Descripción (Opcional)",
              hintText: "Detalles adicionales...",
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

            // --- Selector de Prioridad ---
            Text("Prioridad:", style: isTV ? tvLabelStyle : mobileLabelStyle),
            SizedBox(height: isTV ? 15.0 : 10.0),
            _buildPrioritySelector(context, isTV),
            SizedBox(height: isTV ? 35.0 : 25.0),

            // --- Selector de Fecha de Vencimiento ---
            Text(
              "Fecha de Vencimiento (Opcional):",
              style: isTV ? tvLabelStyle : mobileLabelStyle,
            ),
            SizedBox(height: isTV ? 15.0 : 10.0),
            _buildDueDateSelector(context, isTV),
            SizedBox(height: isTV ? 40.0 : 30.0),

            // --- Botón de Guardar ---
            Obx(
              () => GFButton(
                onPressed: controller.isSavingTask.value
                    ? null
                    : controller.saveTask,
                text: controller.isSavingTask.value
                    ? (controller.isEditingTask
                          ? "Actualizando..."
                          : "Creando...")
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

  // Reutilizamos el helper de ProjectFormScreen, adaptándolo si es necesario
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
    // (Misma implementación de _buildTextFormField que en ProjectFormScreen)
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
      // Para TV, un DropdownButtonFormField es más estándar y manejable con D-Pad
      return Obx(
        () => DropdownButtonFormField<TaskPriority>(
          value: controller.selectedPriority.value,
          dropdownColor: Colors.blueGrey[700], // Fondo del menú desplegable
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

    // Móvil: GFDropdown
    return Obx(
      () => GFDropdown<TaskPriority>(
        padding: const EdgeInsets.all(0),
        borderRadius: BorderRadius.circular(8), // Bordes más redondeados
        border: BorderSide(
          color: colorScheme.outline,
          width: 1,
        ), // Usar color del tema
        dropdownButtonColor: colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.5,
        ),
        value: controller.selectedPriority.value,
        style: TextStyle(color: colorScheme.onSurface), // Color de texto
        icon: Icon(Icons.arrow_drop_down, color: colorScheme.onSurfaceVariant),
        dropdownColor:
            colorScheme.surfaceContainer, // Color de fondo del dropdown
        onChanged: (TaskPriority? newValue) {
          if (newValue != null) controller.selectedPriority.value = newValue;
        },
        items: controller.taskPriorities.map((priority) {
          return DropdownMenuItem<TaskPriority>(
            value: priority,
            child: Text(
              priority.toString().split('.').last.capitalizeFirst ??
                  priority.toString(),
              // El estilo dentro del DropdownMenuItem ya lo toma del `style` del GFDropdown
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDueDateSelector(BuildContext context, bool isTV) {
    final colorScheme = Get.theme.colorScheme;

    if (isTV) {
      // Para TV, un botón que abre el DatePicker. El DatePicker estándar
      // puede no ser ideal con D-Pad, pero probemos.
      return Obx(() {
        final dueDate = controller.selectedDueDate.value;
        return Material(
          // Para InkWell
          color: Colors.blueGrey[800],
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () async {
              // El showDatePicker puede necesitar un tema específico para TV
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: dueDate ?? DateTime.now(),
                firstDate: DateTime(DateTime.now().year - 1),
                lastDate: DateTime(DateTime.now().year + 5),
                // builder: (context, child) { // Para tematizar el DatePicker
                //   return Theme(data: ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: colorScheme.primary)), child: child!);
                // }
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
                  Icon(Icons.calendar_month_outlined, color: Colors.white70),
                ],
              ),
            ),
          ),
        );
      });
    }

    // Móvil: GFListTile como lo tenías, pero con colores de tema
    return Obx(() {
      final dueDate = controller.selectedDueDate.value;
      return Card(
        // Envolver en Card para un mejor aspecto
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
          color: Colors.transparent, // El Card ya tiene el color
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
      );
    });
  }
}
