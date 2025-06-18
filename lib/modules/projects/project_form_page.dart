import 'package:flutter/material.dart';
import 'package:focus_flow/routes/app_routes.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:focus_flow/modules/projects/project_controller.dart';

class ProjectFormScreen extends GetView<ProjectController> {
  const ProjectFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = Get.width;
    final isTV = screenWidth > 800 && Get.height > 500;

    return Scaffold(
      backgroundColor: isTV ? Colors.blueGrey[900] : null,
      appBar: GFAppBar(
        title: Obx(
          () => GFTypography(
            text: controller.isEditing ? 'Editar Proyecto' : 'Nuevo Proyecto',
            type: GFTypographyType.typo1,
            textColor: GFColors.WHITE,
            showDivider: false,
          ),
        ),
        leading: GFIconButton(
          icon: Icon(Icons.arrow_back_ios, color: isTV ? Colors.white : null),
          onPressed: () => Get.offAllNamed(AppRoutes.PROJECTS_LIST),
        ),
        backgroundColor: GFColors.PRIMARY,
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
        key: controller.projectFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
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

            Text(
              "Color del Proyecto:",
              style: isTV ? tvLabelStyle : mobileLabelStyle,
            ),
            SizedBox(height: isTV ? 15.0 : 10.0),
            _buildColorSelector(isTV),
            SizedBox(height: isTV ? 35.0 : 25.0),

            Text(
              "Icono del Proyecto:",
              style: isTV ? tvLabelStyle : mobileLabelStyle,
            ),
            SizedBox(height: isTV ? 15.0 : 10.0),
            _buildIconSelector(isTV),
            SizedBox(height: isTV ? 40.0 : 30.0),

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

  Widget _buildColorSelector(bool isTV) {
    final colorScheme = Get.theme.colorScheme;
    if (isTV) {
      return SizedBox(
        height: 60,
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
                focusNode: FocusNode(),
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

    if (isTV) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.predefinedIcons.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          childAspectRatio: 1,
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
