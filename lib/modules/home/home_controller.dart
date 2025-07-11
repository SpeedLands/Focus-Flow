import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:focus_flow/modules/auth/auth_controller.dart';
import 'package:focus_flow/data/models/user_model.dart';

class HomeController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final Rx<UserData?> userData = Rx<UserData?>(null);

  @override
  void onInit() {
    super.onInit();
    userData.value = _authController.currentUser.value;

    _determineDeviceType();

    ever(_authController.currentUser, (UserData? userFromAuth) {
      userData.value = userFromAuth;
    });
  }

  String get greeting {
    if (userData.value != null && userData.value!.name!.isNotEmpty) {
      return '¡Hola, ${userData.value!.name}!';
    }
    return '¡Bienvenido a FocusFlow!';
  }

  void logout() {
    _authController.logout();
  }

  final Rx<DeviceType> deviceType = DeviceType.mobile.obs;

  void _determineDeviceType() {
    final screenWidth = Get.width;
    final screenHeight = Get.height;
    final shortestSide = Get.mediaQuery.size.shortestSide;

    if (shortestSide < 300 && screenWidth < 350) {
      deviceType.value = DeviceType.watch;
    } else if (shortestSide >= 600) {
      if (GetPlatform.isWeb ||
          GetPlatform.isDesktop ||
          (screenWidth > 800 && screenHeight > 500)) {
        deviceType.value = DeviceType.tv;
      } else {
        deviceType.value = DeviceType.tablet;
      }
    } else {
      deviceType.value = DeviceType.mobile;
    }
    debugPrint('Detected device type: ${deviceType.value}');
  }
}

enum DeviceType { mobile, tablet, tv, watch }
