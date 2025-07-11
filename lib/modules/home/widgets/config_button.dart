import 'package:flutter/material.dart';
import 'package:focus_flow/routes/app_routes.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';

class GoToSettingsButton extends StatelessWidget {
  const GoToSettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GFIconButton(
      icon: const Icon(Icons.settings_outlined),
      tooltip: 'Configuración de Usuario',
      onPressed: () {
        Get.toNamed<Object>(AppRoutes.USER_SETTINGS);
      },
    );
  }
}
