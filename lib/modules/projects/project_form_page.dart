// lib/app/modules/projects/views/project_form_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:focus_flow/modules/projects/project_controller.dart'; // Ajusta ruta

class ProjectFormScreen extends GetView<ProjectController> {
  const ProjectFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = Get.width;
    final isTV = screenWidth > 800 && Get.height > 500;

    return Scaffold(
      backgroundColor: isTV ? Colors.blueGrey[900] : null,
      appBar: AppBar(
        title: Obx(
          () => Text(
            controller.isEditing ? 'Editar Proyecto' : 'Nuevo Proyecto',
            style: TextStyle(color: isTV ? Colors.white : null),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: isTV ? Colors.white : null),
          onPressed: () => Get.back(),
        ),
        backgroundColor: isTV ? Colors.blueGrey[800] : null,
        elevation: isTV ? 0 : null,
      ),
      body: _buildFormBody(context, isTV),
    );
  }

  Widget _buildFormBody(BuildContext context, bool isTV) {
    final textTheme = Get.textTheme;
    final colorScheme = Get.theme.colorScheme;

    // Estilos para TV
    final tvLabelStyle = textTheme.titleMedium?.copyWith(
      color: Colors.white70,
      fontWeight: FontWeight.w500,
    );

    // Estilos para Móvil
    final mobileLabelStyle = textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w500,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(isTV ? 40.0 : 20.0),
      child: Form(
        key: controller.projectFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // --- Campo Nombre del Proyecto ---
            _buildTextFormField(
              controller: controller.nameController,
              labelText: 'Nombre del Proyecto',
              hintText: 'Ej: Desarrollo App Móvil',
              prefixIcon: Icons.title_outlined,
              isTV: isTV,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es obligatorio';
                }
                if (value.trim().length > 50) return 'Máximo 50 caracteres';
                return null;
              },
            ),
            SizedBox(height: isTV ? 30.0 : 20.0),

            // --- Campo Descripción del Proyecto ---
            _buildTextFormField(
              controller: controller.descriptionController,
              labelText: 'Descripción (Opcional)',
              hintText: 'Detalles adicionales...',
              prefixIcon: Icons.description_outlined,
              maxLines: isTV ? 4 : 3,
              isTV: isTV,
              validator: (value) {
                if (value != null && value.trim().length > 200) {
                  return 'Máximo 200 caracteres';
                }
                return null;
              },
            ),
            SizedBox(height: isTV ? 35.0 : 25.0),

            // --- Selector de Color ---
            Text(
              "Color del Proyecto:",
              style: isTV ? tvLabelStyle : mobileLabelStyle,
            ),
            SizedBox(height: isTV ? 15.0 : 10.0),
            _buildColorSelector(isTV),
            SizedBox(height: isTV ? 35.0 : 25.0),

            // --- Selector de Icono ---
            Text(
              "Icono del Proyecto:",
              style: isTV ? tvLabelStyle : mobileLabelStyle,
            ),
            SizedBox(height: isTV ? 15.0 : 10.0),
            _buildIconSelector(isTV),
            SizedBox(height: isTV ? 40.0 : 30.0),

            // --- Botón de Guardar ---
            Obx(
              () => GFButton(
                onPressed: controller.isSavingProject.value
                    ? null
                    : controller.saveProject,
                text: controller.isSavingProject.value
                    ? (controller.isEditing ? "Actualizando..." : "Creando...")
                    : (controller.isEditing
                          ? 'Actualizar Proyecto'
                          : 'Crear Proyecto'),
                icon: controller.isSavingProject.value
                    ? GFLoader(
                        type: GFLoaderType.circle,
                        size: GFSize.SMALL,
                        loaderColorOne: isTV
                            ? colorScheme.primary
                            : Colors.white,
                        loaderColorTwo: isTV
                            ? colorScheme.primaryContainer
                            : Colors.white70,
                        loaderColorThree: isTV
                            ? colorScheme.secondary
                            : Colors.white38,
                      )
                    : Icon(
                        controller.isEditing
                            ? Icons.save_alt_outlined
                            : Icons.add_circle_outline,
                        color: isTV
                            ? (Get.isDarkMode ? Colors.black : Colors.white)
                            : Colors.white, // Color del icono del botón
                      ),
                fullWidthButton: true,
                size: GFSize.LARGE,
                shape: GFButtonShape.pills,
                color: isTV
                    ? colorScheme.primary
                    : GFColors.PRIMARY, // Color de fondo del botón
                textColor: isTV
                    ? (Get.isDarkMode ? Colors.black : Colors.white)
                    : Colors.white, // Color del texto del botón
                buttonBoxShadow: isTV, // Sombra para TV
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
    FocusNode? focusNode, // Para manejo de foco en TV
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

  Widget _buildColorSelector(bool isTV) {
    final colorScheme = Get.theme.colorScheme;
    // En TV, un ListView horizontal podría ser mejor para la navegación con D-Pad
    if (isTV) {
      return SizedBox(
        height: 60, // Altura fija para el ListView
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: controller.predefinedColors.length,
          separatorBuilder: (context, index) => const SizedBox(width: 15),
          itemBuilder: (context, index) {
            final color = controller.predefinedColors[index];
            return Obx(() {
              bool isSelected =
                  controller.selectedColor.value.toARGB32() == color.toARGB32();
              return FocusableActionDetector(
                focusNode: FocusNode(), // Cada item necesita su FocusNode
                actions: <Type, Action<Intent>>{
                  ActivateIntent: CallbackAction<ActivateIntent>(
                    onInvoke: (_) => controller.selectedColor.value = color,
                  ),
                },
                child: GestureDetector(
                  onTap: () => controller.selectedColor.value = color,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            color: color.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                            size: 28,
                          )
                        : null,
                  ),
                ),
              );
            });
          },
        ),
      );
    }
    // Selector para Móvil
    return Obx(
      () => Wrap(
        spacing: 10.0,
        runSpacing: 10.0,
        children: controller.predefinedColors.map((color) {
          bool isSelected =
              controller.selectedColor.value.toARGB32() == color.toARGB32();
          return GestureDetector(
            onTap: () => controller.selectedColor.value = color,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: colorScheme.primary, width: 3)
                    : Border.all(color: Colors.grey.shade300, width: 1.5),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: color.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white,
                      size: 20,
                    )
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIconSelector(bool isTV) {
    final colorScheme = Get.theme.colorScheme;
    final onSurfaceVariant = Get.isDarkMode
        ? Colors.grey.shade400
        : Colors.grey.shade700;

    // En TV, un GridView podría ser más fácil de navegar con D-Pad
    if (isTV) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.predefinedIcons.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5, // Ajusta según el número de iconos
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          childAspectRatio: 1, // Iconos cuadrados
        ),
        itemBuilder: (context, index) {
          final iconMap = controller.predefinedIcons[index];
          final String iconName = iconMap['name'] as String;
          final IconData iconData = iconMap['icon'] as IconData;
          return Obx(() {
            bool isSelected = controller.selectedIconName.value == iconName;
            return FocusableActionDetector(
              focusNode: FocusNode(),
              actions: <Type, Action<Intent>>{
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (_) => controller.selectedIconName.value = iconName,
                ),
              },
              child: GestureDetector(
                onTap: () => controller.selectedIconName.value = iconName,
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary.withValues(alpha: 0.3)
                        : Colors.blueGrey[800],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.blueGrey[700]!,
                      width: isSelected ? 2.5 : 1.5,
                    ),
                  ),
                  child: Icon(
                    iconData,
                    size: 36,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
              ),
            );
          });
        },
      );
    }

    // Selector para Móvil
    return Obx(
      () => Wrap(
        spacing: 12.0,
        runSpacing: 12.0,
        children: controller.predefinedIcons.map((iconMap) {
          final String iconName = iconMap['name'] as String;
          final IconData iconData = iconMap['icon'] as IconData;
          bool isSelected = controller.selectedIconName.value == iconName;
          return GestureDetector(
            onTap: () => controller.selectedIconName.value = iconName,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest.withValues(
                        alpha: Get.isDarkMode ? 0.6 : 0.3,
                      ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  width: isSelected ? 2.0 : 1.0,
                ),
              ),
              child: Icon(
                iconData,
                size: 28,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : onSurfaceVariant,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
