import 'package:flutter/material.dart';
import 'package:focus_flow/routes/app_routes.dart';
import 'package:get/get.dart';

class GoToSettingsButton extends StatelessWidget {
  const GoToSettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings_outlined),
      tooltip: "Configuración de Usuario",
      onPressed: () {
        Get.toNamed(AppRoutes.USER_SETTINGS);
      },
    );
  }
}

class GoToSettingsTextButton extends StatelessWidget {
  final String text;
  const GoToSettingsTextButton({super.key, this.text = "Configuración"});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(Icons.manage_accounts_outlined),
      label: Text(text),
      onPressed: () {
        Get.toNamed(AppRoutes.USER_SETTINGS);
      },
    );
  }
}
