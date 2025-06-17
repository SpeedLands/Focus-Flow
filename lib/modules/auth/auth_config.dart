import 'package:flutter/material.dart';
import 'package:focus_flow/modules/auth/auth_controller.dart';
import 'package:get/get.dart';

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
      appBar: AppBar(
        title: const Text("Configuración de Perfil"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (authController.currentUser.value == null) {
          return const Center(child: CircularProgressIndicator());
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
                  () => ElevatedButton.icon(
                    icon: authController.isProfileUpdating.value
                        ? Container(
                            width: 20,
                            height: 20,
                            padding: const EdgeInsets.all(2.0),
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save_alt_outlined),
                    label: Text(
                      authController.isProfileUpdating.value
                          ? "Guardando..."
                          : "Guardar Nombre",
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: authController.isProfileUpdating.value
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              authController.updateUserName(
                                authController.editNameController.text.trim(),
                              );
                            }
                          },
                  ),
                ),
                const SizedBox(height: 40),
                const Divider(),
                const SizedBox(height: 20),
                TextButton.icon(
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: const Text(
                    "Cerrar Sesión",
                    style: TextStyle(color: Colors.redAccent),
                  ),
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
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
