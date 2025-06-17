import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:focus_flow/data/services/notification_service.dart';
import 'package:focus_flow/firebase_options.dart';
import 'package:focus_flow/routes/app_pages.dart';
import 'package:focus_flow/routes/app_routes.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);
  await NotificationService.instance.initialize();
  runApp(
    GetMaterialApp(
      initialRoute: AppRoutes.LOGIN,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
    ),
  );
}
