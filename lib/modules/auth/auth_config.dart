import 'package:flutter/material.dart';
import 'package:focus_flow/modules/auth/auth_controller.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:focus_flow/routes/app_routes.dart';

class UserSettingsScreen extends StatelessWidget {
  UserSettingsScreen({super.key});

  final AuthController authController = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authController.editNameController.text.isEmpty &&
          authController.currentUser.value != null &&
          (authController.currentUser.value!.name ?? '').isNotEmpty) {
        authController.editNameController.text =
            authController.currentUser.value!.name!;
      }
    });

    return Scaffold(
      appBar: GFAppBar(
        title: const Text("Configuración de Perfil"),
        backgroundColor: GFColors.PRIMARY,
        leading: GFIconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.offAllNamed(AppRoutes.HOME),
        ),
      ),
      body: Obx(() {
        if (authController.currentUser.value == null) {
          return const Center(child: GFLoader(type: GFLoaderType.circle));
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Text(
                  "Email: ${authController.currentUser.value!.email}",
                  style: Get.textTheme.titleMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: authController.editNameController,
                  decoration: InputDecoration(
                    labelText: "Nombre para mostrar",
                    hintText: "Ingresa tu nuevo nombre",
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person_outline),
                    suffixIcon:
                        authController.editNameController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () =>
                                authController.editNameController.clear(),
                          )
                        : null,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "El nombre no puede estar vacío.";
                    }
                    if (value.trim() ==
                        authController.currentUser.value!.name) {
                      return "El nuevo nombre es igual al actual.";
                    }
                    if (value.trim().length < 3) {
                      return "El nombre debe tener al menos 3 caracteres.";
                    }
                    return null;
                  },
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 24),
                Obx(
                  () => GFButton(
                    onPressed: authController.isProfileUpdating.value
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              authController.updateUserName(
                                authController.editNameController.text.trim(),
                              );
                            }
                          },
                    text: authController.isProfileUpdating.value
                        ? "Guardando..."
                        : "Guardar Nombre",
                    icon: authController.isProfileUpdating.value
                        ? const GFLoader(
                            type: GFLoaderType.circle,
                            size: GFSize.SMALL,
                            loaderColorOne: Colors.white,
                            loaderColorTwo: Colors.white70,
                            loaderColorThree: Colors.white38,
                          )
                        : const Icon(
                            Icons.save_alt_outlined,
                            color: Colors.white,
                          ),
                    type: GFButtonType.solid,
                    color: GFColors.SUCCESS,
                    fullWidthButton: true,
                    size: GFSize.LARGE,
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 40),
                const Divider(),
                const SizedBox(height: 20),

                GFButton(
                  onPressed: () async {
                    Get.defaultDialog(
                      title: "Confirmar Cierre de Sesión",
                      middleText: "¿Estás seguro de que quieres cerrar sesión?",
                      textConfirm: "Sí, cerrar",
                      textCancel: "Cancelar",
                      confirmTextColor: Colors.white,
                      onConfirm: () async {
                        Get.back();
                        await authController.logout();
                      },
                    );
                  },
                  text: "Cerrar Sesión",
                  icon: Icon(Icons.logout, color: GFColors.WHITE),
                  type: GFButtonType.solid,
                  color: GFColors.DANGER,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
